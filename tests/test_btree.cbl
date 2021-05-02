       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-BTREE.
      *>================================================================*
      *> BASALT TEST SUITE - B+TREE SLOTTED INDEX VERIFICATION         *
      *> Verification of B+Tree key insertion, binary search, sorted    *
      *> leaf splits, routing pointers, and key deletion.              *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "btree.cpy".

       01 WS-BT-TEST-VARS.
          05 WS-KEY                      PIC X(16) VALUE SPACES.
          05 WS-IN-PAGE                  PIC 9(8)  VALUE 0.
          05 WS-IN-SLOT                  PIC 9(4)  VALUE 0.
          05 WS-OUT-PAGE                 PIC 9(8)  VALUE 0.
          05 WS-OUT-SLOT                 PIC 9(4)  VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       01 WS-I                           PIC 9(4)  VALUE 0.
       01 WS-FORMATTED-KEY               PIC X(16) VALUE SPACES.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: Insert key "ACCT-00000001" with RID (10, 1)
      *>----------------------------------------------------------------*
           MOVE "ACCT-00000001   " TO WS-KEY
           MOVE 10 TO WS-IN-PAGE
           MOVE 1  TO WS-IN-SLOT
           CALL "BSLT-BTREE-INDEX" USING "INSERT  " WS-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree insert first key failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Search for existing key "ACCT-00000001"
      *> Should locate exact RID (10, 1)
      *>----------------------------------------------------------------*
           MOVE "ACCT-00000001   " TO WS-KEY
           MOVE 0 TO WS-OUT-PAGE WS-OUT-SLOT
           CALL "BSLT-BTREE-INDEX" USING "SEARCH  " WS-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-PAGE = 10 AND WS-OUT-SLOT = 1
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree search existing key failed: " WS-OUT-PAGE
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Search for non-existent key "ACCT-99999999"
      *> Should return NOT-FOUND error code
      *>----------------------------------------------------------------*
           MOVE "ACCT-99999999   " TO WS-KEY
           CALL "BSLT-BTREE-INDEX" USING "SEARCH  " WS-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-NOT-FOUND
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree search non-existent key should return NOT-FOUND"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Insert 20 keys to test ordered placement in leaf node
      *>----------------------------------------------------------------*
           PERFORM VARYING WS-I FROM 2 BY 1 UNTIL WS-I > 20
               STRING "KEY-" WS-I INTO WS-FORMATTED-KEY
               MOVE WS-I TO WS-IN-PAGE
               MOVE WS-I TO WS-IN-SLOT
               CALL "BSLT-BTREE-INDEX" USING "INSERT  " WS-FORMATTED-KEY
                                             WS-IN-PAGE WS-IN-SLOT
                                             WS-OUT-PAGE WS-OUT-SLOT
                                             WS-STATUS
               IF WS-STATUS NOT = BS-RC-OK
                   ADD 1 TO LNK-TESTS-FAILED
                   DISPLAY "FAIL: B+Tree batch insert failed at key " WS-I
                   GOBACK
               END-IF
           END-PERFORM
           ADD 1 TO LNK-TESTS-PASSED

      *>----------------------------------------------------------------*
      *> TEST 5: Verify lookup of inserted key "KEY-15"
      *>----------------------------------------------------------------*
           STRING "KEY-15" INTO WS-FORMATTED-KEY
           CALL "BSLT-BTREE-INDEX" USING "SEARCH  " WS-FORMATTED-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-PAGE = 15 AND WS-OUT-SLOT = 15
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree lookup of KEY-15 failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Delete key "KEY-15" and verify subsequent lookup fails
      *>----------------------------------------------------------------*
           CALL "BSLT-BTREE-INDEX" USING "DELETE  " WS-FORMATTED-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree delete KEY-15 failed: " WS-STATUS
           END-IF

           CALL "BSLT-BTREE-INDEX" USING "SEARCH  " WS-FORMATTED-KEY
                                         WS-IN-PAGE WS-IN-SLOT
                                         WS-OUT-PAGE WS-OUT-SLOT
                                         WS-STATUS
           IF WS-STATUS = BS-RC-NOT-FOUND
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: B+Tree deleted key still found"
           END-IF.

           GOBACK.
