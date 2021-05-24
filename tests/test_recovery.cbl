       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-RECOVERY.
      *>================================================================*
      *> BASALT TEST SUITE - ARIES THREE-PASS CRASH RECOVERY           *
      *> Verification of physiological logging, fuzzy checkpointing,    *
      *> Analysis pass, Redo pass (repeating history), Undo pass        *
      *> (loser rollback), and Compensation Log Records (CLRs).         *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "wal.cpy".
       COPY "page.cpy".

       01 WS-REC-TEST-VARS.
          05 WS-CRASH-LSN                PIC 9(18) VALUE 50000.
          05 WS-CHKPT-LSN                PIC 9(18) VALUE 45000.
          05 WS-REDO-APPLIED             PIC 9(6)  VALUE 0.
          05 WS-UNDO-APPLIED             PIC 9(6)  VALUE 0.
          05 WS-CLRS-WRITTEN             PIC 9(6)  VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

      *> WAL logger test variables
       01 WS-WAL-TEST-VARS.
          05 WS-IN-TX-ID                 PIC 9(12) VALUE 101.
          05 WS-IN-TYPE                  PIC 9(2)  VALUE 1.
          05 WS-IN-PAGE-ID               PIC 9(8)  VALUE 12.
          05 WS-IN-SLOT-ID               PIC 9(4)  VALUE 1.
          05 WS-IN-UNDO-NEXT             PIC 9(18) VALUE 0.
          05 WS-IN-BEFORE-IMG            PIC X(64) VALUE "ACCT-101 BAL: 1000.00".
          05 WS-IN-AFTER-IMG             PIC X(64) VALUE "ACCT-101 BAL:  500.00".
          05 WS-OUT-LSN                  PIC 9(18) VALUE 0.
          05 WS-SAVED-LSN                PIC 9(18) VALUE 0.

      *> Checkpoint test variables
       01 WS-CHKPT-TEST-VARS.
          05 WS-CHKPT-OUT-LSN            PIC 9(18) VALUE 0.
          05 WS-CHKPT-DIRTY-COUNT        PIC 9(4)  VALUE 0.
          05 WS-CHKPT-TX-COUNT           PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: Append physiological WAL record
      *>----------------------------------------------------------------*
           MOVE 101 TO WS-IN-TX-ID
           MOVE 1   TO WS-IN-TYPE
           MOVE 12  TO WS-IN-PAGE-ID
           MOVE 1   TO WS-IN-SLOT-ID
           MOVE 0   TO WS-IN-UNDO-NEXT
           MOVE "ACCT-101 BAL: 1000.00" TO WS-IN-BEFORE-IMG
           MOVE "ACCT-101 BAL:  500.00" TO WS-IN-AFTER-IMG

           CALL "BSLT-WAL-LOGGER" USING "APPEND  " WS-IN-TX-ID
                                        WS-IN-TYPE WS-IN-PAGE-ID
                                        WS-IN-SLOT-ID WS-IN-UNDO-NEXT
                                        WS-IN-BEFORE-IMG WS-IN-AFTER-IMG
                                        WS-OUT-LSN WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-LSN > 0
               ADD 1 TO LNK-TESTS-PASSED
               MOVE WS-OUT-LSN TO WS-SAVED-LSN
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: WAL logger append record failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Append second WAL record and verify monotonic LSN growth
      *>----------------------------------------------------------------*
           CALL "BSLT-WAL-LOGGER" USING "APPEND  " WS-IN-TX-ID
                                        WS-IN-TYPE WS-IN-PAGE-ID
                                        WS-IN-SLOT-ID WS-IN-UNDO-NEXT
                                        WS-IN-BEFORE-IMG WS-IN-AFTER-IMG
                                        WS-OUT-LSN WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-LSN > WS-SAVED-LSN
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Monotonic LSN growth test failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Force WAL buffer flush up to current LSN
      *>----------------------------------------------------------------*
           CALL "BSLT-WAL-LOGGER" USING "FLUSH   " WS-IN-TX-ID
                                        WS-IN-TYPE WS-IN-PAGE-ID
                                        WS-IN-SLOT-ID WS-IN-UNDO-NEXT
                                        WS-IN-BEFORE-IMG WS-IN-AFTER-IMG
                                        WS-OUT-LSN WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: WAL logger flush failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Emit fuzzy checkpoint record
      *>----------------------------------------------------------------*
           CALL "BSLT-CHECKPOINT" USING "CREATE  " WS-CHKPT-OUT-LSN
                                        WS-CHKPT-DIRTY-COUNT
                                        WS-CHKPT-TX-COUNT
                                        WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-CHKPT-OUT-LSN > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fuzzy checkpoint creation failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: Execute ARIES 3-pass crash recovery
      *> Analysis -> Redo (repeating history) -> Undo (rolling back losers)
      *>----------------------------------------------------------------*
           MOVE 50000 TO WS-CRASH-LSN
           MOVE 45000 TO WS-CHKPT-LSN
           CALL "BSLT-ARIES-RECOVERY" USING "RECOVER "
                                            WS-CRASH-LSN
                                            WS-CHKPT-LSN
                                            WS-REDO-APPLIED
                                            WS-UNDO-APPLIED
                                            WS-CLRS-WRITTEN
                                            WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-REDO-APPLIED > 0
              AND WS-UNDO-APPLIED > 0 AND WS-CLRS-WRITTEN > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ARIES crash recovery execution failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Verify equality of Undo actions and CLR records written
      *> Every undone action must generate exactly one Compensation Log Record
      *>----------------------------------------------------------------*
           IF WS-UNDO-APPLIED = WS-CLRS-WRITTEN
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ARIES CLR count mismatch with Undo operations"
           END-IF.

           GOBACK.
