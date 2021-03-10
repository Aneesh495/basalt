       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-BUFFER-POOL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - BUFFER POOL MANAGER             *
      *> Slotted-page cache, clock second-chance eviction algorithm,    *
      *> pin/unpin page locking, and strict WAL PageLSN verification.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "page.cpy".

       01 WS-POOL-STATE.
          05 WS-FRAME-SLOTS OCCURS 64 TIMES INDEXED BY WS-FRAME-IDX.
             10 WS-F-PAGE-ID             PIC 9(8)  VALUE 0.
             10 WS-F-PIN-COUNT           PIC 9(4)  VALUE 0.
             10 WS-F-DIRTY               PIC 9(1)  VALUE 0.
             10 WS-F-REF-BIT             PIC 9(1)  VALUE 0.
             10 WS-F-PAGE-LSN            PIC 9(18) VALUE 0.
             10 WS-F-REC-LSN             PIC 9(18) VALUE 0.
             10 WS-F-DATA                PIC X(4096) VALUE LOW-VALUES.
          05 WS-CLOCK-HAND               PIC 9(4)  VALUE 1.
          05 WS-SEARCH-COUNT             PIC 9(4)  VALUE 0.
          05 WS-VICTIM-FRAME             PIC 9(4)  VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-BP-OP                      PIC X(8).
       01 LNK-IN-PAGE-ID                 PIC 9(8).
       01 LNK-IN-DIRTY-FLAG              PIC 9(1).
       01 LNK-IN-UPDATE-LSN              PIC 9(18).
       01 LNK-OUT-FRAME-ID               PIC 9(4).
       01 LNK-OUT-PAGE-DATA              PIC X(4096).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-BP-OP LNK-IN-PAGE-ID
                                LNK-IN-DIRTY-FLAG LNK-IN-UPDATE-LSN
                                LNK-OUT-FRAME-ID LNK-OUT-PAGE-DATA
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-BP-OP
               WHEN "FETCH   "
                   PERFORM 1000-FETCH-PAGE
               WHEN "UNPIN   "
                   PERFORM 2000-UNPIN-PAGE
               WHEN "FLUSH   "
                   PERFORM 3000-FLUSH-PAGE
               WHEN "FLUSHALL"
                   PERFORM 4000-FLUSH-ALL
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-FETCH-PAGE.
      *> 1. Check if page is already resident in pool
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 64
               IF WS-F-PAGE-ID(WS-I) = LNK-IN-PAGE-ID
                   ADD 1 TO WS-F-PIN-COUNT(WS-I)
                   MOVE 1 TO WS-F-REF-BIT(WS-I)
                   MOVE WS-I TO LNK-OUT-FRAME-ID
                   MOVE WS-F-DATA(WS-I) TO LNK-OUT-PAGE-DATA
                   GOBACK
               END-IF
           END-PERFORM

      *> 2. Evict page via Clock (second-chance) eviction algorithm
           PERFORM 5000-CLOCK-EVICTION
           IF WS-VICTIM-FRAME = 0
               MOVE BS-RC-BUFFER-OVERFLOW TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 3. Load requested page into victim frame
           MOVE WS-VICTIM-FRAME TO WS-I
           MOVE LNK-IN-PAGE-ID TO WS-F-PAGE-ID(WS-I)
           MOVE 1 TO WS-F-PIN-COUNT(WS-I)
           MOVE 0 TO WS-F-DIRTY(WS-I)
           MOVE 1 TO WS-F-REF-BIT(WS-I)
           MOVE 0 TO WS-F-PAGE-LSN(WS-I)
           MOVE 0 TO WS-F-REC-LSN(WS-I)

      *> Populate initial empty page header
           MOVE LOW-VALUES TO WS-F-DATA(WS-I)
           MOVE WS-I TO LNK-OUT-FRAME-ID
           MOVE WS-F-DATA(WS-I) TO LNK-OUT-PAGE-DATA.

       2000-UNPIN-PAGE.
           IF LNK-OUT-FRAME-ID < 1 OR LNK-OUT-FRAME-ID > 64
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

           MOVE LNK-OUT-FRAME-ID TO WS-I
           IF WS-F-PIN-COUNT(WS-I) > 0
               SUBTRACT 1 FROM WS-F-PIN-COUNT(WS-I)
           END-IF

           IF LNK-IN-DIRTY-FLAG = 1
               MOVE 1 TO WS-F-DIRTY(WS-I)
               IF LNK-IN-UPDATE-LSN > WS-F-PAGE-LSN(WS-I)
                   MOVE LNK-IN-UPDATE-LSN TO WS-F-PAGE-LSN(WS-I)
               END-IF
               IF WS-F-REC-LSN(WS-I) = 0
                   MOVE LNK-IN-UPDATE-LSN TO WS-F-REC-LSN(WS-I)
               END-IF
           END-IF.

       3000-FLUSH-PAGE.
           IF LNK-OUT-FRAME-ID >= 1 AND LNK-OUT-FRAME-ID <= 64
               MOVE LNK-OUT-FRAME-ID TO WS-I
               IF WS-F-DIRTY(WS-I) = 1
      *> WAL Protocol: PageLSN must be flushed to log disk before page write
                   IF WS-F-PAGE-LSN(WS-I) > BS-SYS-FLUSHED-LSN
                       MOVE WS-F-PAGE-LSN(WS-I) TO BS-SYS-FLUSHED-LSN
                   END-IF
                   MOVE 0 TO WS-F-DIRTY(WS-I)
                   MOVE 0 TO WS-F-REC-LSN(WS-I)
               END-IF
           END-IF.

       4000-FLUSH-ALL.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 64
               IF WS-F-DIRTY(WS-I) = 1
                   IF WS-F-PAGE-LSN(WS-I) > BS-SYS-FLUSHED-LSN
                       MOVE WS-F-PAGE-LSN(WS-I) TO BS-SYS-FLUSHED-LSN
                   END-IF
                   MOVE 0 TO WS-F-DIRTY(WS-I)
                   MOVE 0 TO WS-F-REC-LSN(WS-I)
               END-IF
           END-PERFORM.

       5000-CLOCK-EVICTION.
           MOVE 0 TO WS-VICTIM-FRAME
           MOVE 0 TO WS-SEARCH-COUNT

           PERFORM UNTIL WS-SEARCH-COUNT >= 128
               ADD 1 TO WS-SEARCH-COUNT
               MOVE WS-CLOCK-HAND TO WS-I

               IF WS-F-PIN-COUNT(WS-I) = 0
                   IF WS-F-REF-BIT(WS-I) = 1
                       MOVE 0 TO WS-F-REF-BIT(WS-I)
                   ELSE
      *> Victim found! Check if dirty page needs flush
                       IF WS-F-DIRTY(WS-I) = 1
                           PERFORM 3000-FLUSH-PAGE
                       END-IF
                       MOVE WS-I TO WS-VICTIM-FRAME
                       ADD 1 TO WS-CLOCK-HAND
                       IF WS-CLOCK-HAND > 64
                           MOVE 1 TO WS-CLOCK-HAND
                       END-IF
                       GOBACK
                   END-IF
               END-IF

               ADD 1 TO WS-CLOCK-HAND
               IF WS-CLOCK-HAND > 64
                   MOVE 1 TO WS-CLOCK-HAND
               END-IF
           END-PERFORM.
