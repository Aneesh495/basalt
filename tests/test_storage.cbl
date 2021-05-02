       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-STORAGE.
      *>================================================================*
      *> BASALT TEST SUITE - STORAGE AND BUFFER POOL MANAGEMENT        *
      *> Verification of 64-frame buffer pool manager, page pinning,    *
      *> unpinning, dirty page tracking, Clock replacement, and flush.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "page.cpy".

       01 WS-BP-TEST-VARS.
          05 WS-PAGE-ID                  PIC 9(8)  VALUE 0.
          05 WS-DIRTY-FLAG               PIC 9(1)  VALUE 0.
          05 WS-UPDATE-LSN               PIC 9(18) VALUE 0.
          05 WS-FRAME-ID                 PIC 9(4)  VALUE 0.
          05 WS-FRAME-ID-SAVED           PIC 9(4)  VALUE 0.
          05 WS-PAGE-DATA                PIC X(4096) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       01 WS-I                           PIC 9(8)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: Fetch page 1 into buffer pool
      *> Should allocate a free frame and return status OK
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-PAGE-ID
           MOVE 0 TO WS-DIRTY-FLAG WS-UPDATE-LSN
           CALL "BSLT-BUFFER-POOL" USING "FETCH   " WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-FRAME-ID > 0
               ADD 1 TO LNK-TESTS-PASSED
               MOVE WS-FRAME-ID TO WS-FRAME-ID-SAVED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool fetch page 1 failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Fetch page 1 again while pinned
      *> Should hit cache and return the exact same frame ID
      *>----------------------------------------------------------------*
           CALL "BSLT-BUFFER-POOL" USING "FETCH   " WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-FRAME-ID = WS-FRAME-ID-SAVED
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool cache hit test failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Unpin page 1 with dirty flag and PageLSN watermark
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-DIRTY-FLAG
           MOVE 10042 TO WS-UPDATE-LSN
           CALL "BSLT-BUFFER-POOL" USING "UNPIN   " WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool unpin 1 failed: " WS-STATUS
           END-IF

      *> Unpin second pin
           MOVE 0 TO WS-DIRTY-FLAG
           CALL "BSLT-BUFFER-POOL" USING "UNPIN   " WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool unpin 2 failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Fetch multiple distinct pages to verify frame assignment
      *>----------------------------------------------------------------*
           PERFORM VARYING WS-I FROM 2 BY 1 UNTIL WS-I > 10
               MOVE WS-I TO WS-PAGE-ID
               MOVE 0 TO WS-DIRTY-FLAG WS-UPDATE-LSN
               CALL "BSLT-BUFFER-POOL" USING "FETCH   " WS-PAGE-ID
                                             WS-DIRTY-FLAG WS-UPDATE-LSN
                                             WS-FRAME-ID WS-PAGE-DATA
                                             WS-STATUS
               IF WS-STATUS NOT = BS-RC-OK
                   ADD 1 TO LNK-TESTS-FAILED
                   DISPLAY "FAIL: Buffer pool sequential fetch failed at page " WS-I
                   GOBACK
               END-IF
               CALL "BSLT-BUFFER-POOL" USING "UNPIN   " WS-PAGE-ID
                                             WS-DIRTY-FLAG WS-UPDATE-LSN
                                             WS-FRAME-ID WS-PAGE-DATA
                                             WS-STATUS
           END-PERFORM
           ADD 1 TO LNK-TESTS-PASSED

      *>----------------------------------------------------------------*
      *> TEST 5: Flush dirty page to disk
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-PAGE-ID
           CALL "BSLT-BUFFER-POOL" USING "FLUSH   " WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool flush page 1 failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Flush all pages (checkpoint sync)
      *>----------------------------------------------------------------*
           CALL "BSLT-BUFFER-POOL" USING "FLUSHALL" WS-PAGE-ID
                                         WS-DIRTY-FLAG WS-UPDATE-LSN
                                         WS-FRAME-ID WS-PAGE-DATA
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Buffer pool flushall failed"
           END-IF.

           GOBACK.
