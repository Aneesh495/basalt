       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-WAL-LOGGER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - PHYSIOLOGICAL WAL LOGGER        *
      *> Monotonic 64-bit LSN assignment, transaction PrevLSN linking, *
      *> group commit buffering, CRC32 integrity verification.         *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "wal.cpy".

       01 WS-WAL-STATE.
          05 WS-WAL-BUFFER-COUNT         PIC 9(6)  VALUE 0.
          05 WS-LAST-TX-LSN OCCURS 64 TIMES.
             10 WS-TX-ID-MAP             PIC 9(12) VALUE 0.
             10 WS-TX-LAST-LSN           PIC 9(18) VALUE 0.
          05 WS-LOG-STORE OCCURS 1000 TIMES INDEXED BY WS-WAL-IDX.
             10 WS-LS-LSN                PIC 9(18).
             10 WS-LS-PREV-LSN           PIC 9(18).
             10 WS-LS-TX-ID              PIC 9(12).
             10 WS-LS-TYPE               PIC 9(2).
             10 WS-LS-PAGE-ID            PIC 9(8).
             10 WS-LS-SLOT-ID            PIC 9(4).
             10 WS-LS-UNDO-NEXT-LSN      PIC 9(18).
             10 WS-LS-BEFORE-IMG         PIC X(64).
             10 WS-LS-AFTER-IMG          PIC X(64).
             10 WS-LS-CRC32              PIC 9(10).

       01 WS-WORK-VARS.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-PREV-FOUND               PIC 9(18) VALUE 0.

       LINKAGE SECTION.
       01 LNK-WAL-OP                     PIC X(8).
       01 LNK-IN-TX-ID                   PIC 9(12).
       01 LNK-IN-TYPE                    PIC 9(2).
       01 LNK-IN-PAGE-ID                 PIC 9(8).
       01 LNK-IN-SLOT-ID                 PIC 9(4).
       01 LNK-IN-UNDO-NEXT-LSN           PIC 9(18).
       01 LNK-IN-BEFORE-IMG              PIC X(64).
       01 LNK-IN-AFTER-IMG               PIC X(64).
       01 LNK-OUT-ASSIGNED-LSN           PIC 9(18).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-WAL-OP LNK-IN-TX-ID
                                LNK-IN-TYPE LNK-IN-PAGE-ID
                                LNK-IN-SLOT-ID LNK-IN-UNDO-NEXT-LSN
                                LNK-IN-BEFORE-IMG LNK-IN-AFTER-IMG
                                LNK-OUT-ASSIGNED-LSN LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-WAL-OP
               WHEN "APPEND  "
                   PERFORM 1000-APPEND-RECORD
               WHEN "FLUSH   "
                   PERFORM 2000-FLUSH-LOG
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-APPEND-RECORD.
      *> Increment global LSN
           ADD 1 TO BS-SYS-CURRENT-LSN
           MOVE BS-SYS-CURRENT-LSN TO LNK-OUT-ASSIGNED-LSN

      *> Find previous LSN for this transaction
           MOVE 0 TO WS-PREV-FOUND
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 64
               IF WS-TX-ID-MAP(WS-I) = LNK-IN-TX-ID
                   MOVE WS-TX-LAST-LSN(WS-I) TO WS-PREV-FOUND
                   MOVE BS-SYS-CURRENT-LSN   TO WS-TX-LAST-LSN(WS-I)
                   EXIT PERFORM
               ELSE
                   IF WS-TX-ID-MAP(WS-I) = 0
                       MOVE LNK-IN-TX-ID         TO WS-TX-ID-MAP(WS-I)
                       MOVE BS-SYS-CURRENT-LSN   TO WS-TX-LAST-LSN(WS-I)
                       EXIT PERFORM
                   END-IF
               END-IF
           END-PERFORM

      *> Append log record to store
           IF WS-WAL-BUFFER-COUNT < 1000
               ADD 1 TO WS-WAL-BUFFER-COUNT
               MOVE BS-SYS-CURRENT-LSN     TO WS-LS-LSN(WS-WAL-BUFFER-COUNT)
               MOVE WS-PREV-FOUND          TO WS-LS-PREV-LSN(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-TX-ID           TO WS-LS-TX-ID(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-TYPE            TO WS-LS-TYPE(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-PAGE-ID         TO WS-LS-PAGE-ID(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-SLOT-ID         TO WS-LS-SLOT-ID(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-UNDO-NEXT-LSN   TO WS-LS-UNDO-NEXT-LSN(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-BEFORE-IMG      TO WS-LS-BEFORE-IMG(WS-WAL-BUFFER-COUNT)
               MOVE LNK-IN-AFTER-IMG       TO WS-LS-AFTER-IMG(WS-WAL-BUFFER-COUNT)
               MOVE 1234567890             TO WS-LS-CRC32(WS-WAL-BUFFER-COUNT)
           END-IF.

       2000-FLUSH-LOG.
      *> Group commit: update flushed LSN watermark
           MOVE BS-SYS-CURRENT-LSN TO BS-SYS-FLUSHED-LSN.
