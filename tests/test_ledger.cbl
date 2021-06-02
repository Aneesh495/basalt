       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-LEDGER.
      *>================================================================*
      *> BASALT TEST SUITE - BI-TEMPORAL LEDGER & ACCOUNT MANAGER      *
      *> Double-entry invariant validation, atomic batch posting,       *
      *> liquidity encumbrances, and point-in-time balance rewind.     *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "entry.cpy".

       01 WS-CALL-VARS.
          05 WS-OP-CODE                  PIC X(8)  VALUE SPACES.
          05 WS-ACC-ID                   PIC X(16) VALUE SPACES.
          05 WS-OWNER-BIC                PIC X(11) VALUE SPACES.
          05 WS-CCY                      PIC X(3)  VALUE "USD".
          05 WS-ACC-TYPE                 PIC 9(2)  VALUE 1.
          05 WS-AMOUNT                   PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-LIMIT                    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-BATCH-ID                 PIC 9(12) VALUE 0.
          05 WS-BATCH-COUNT              PIC 9(4)  VALUE 0.
          05 WS-VAL-TIME                 PIC 9(14) VALUE 20261015120000.
          05 WS-SYS-TIME                 PIC 9(14) VALUE 20261015120000.
          05 WS-QUERY-BAL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIR                      PIC X(1)  VALUE "C".
          05 WS-ACC-BUF                  PIC X(256) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4)   VALUE 0.
          05 WS-COMMITTED                PIC 9(6)   VALUE 0.
          05 WS-RECON-BAL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MATCH-COUNT              PIC 9(6)   VALUE 0.

       01 WS-BALANCED-BATCH.
          05 WS-BB-ENTRY OCCURS 64 TIMES.
             10 WS-BB-ACC-ID             PIC X(16) VALUE SPACES.
             10 WS-BB-CPTY-ID            PIC X(16) VALUE SPACES.
             10 WS-BB-DIR                PIC X(1)  VALUE SPACES.
             10 WS-BB-AMT                PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-BB-CCY                PIC X(3)  VALUE "USD".
             10 WS-BB-TYPE               PIC 9(2)  VALUE 1.
             10 WS-BB-VAL-DATE           PIC 9(14) VALUE 20261015120000.
             10 WS-BB-NARRATIVE          PIC X(48) VALUE SPACES.

       01 WS-UNBALANCED-BATCH.
          05 WS-UB-ENTRY OCCURS 64 TIMES.
             10 WS-UB-ACC-ID             PIC X(16) VALUE SPACES.
             10 WS-UB-CPTY-ID            PIC X(16) VALUE SPACES.
             10 WS-UB-DIR                PIC X(1)  VALUE SPACES.
             10 WS-UB-AMT                PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-UB-CCY                PIC X(3)  VALUE "USD".
             10 WS-UB-TYPE               PIC 9(2)  VALUE 1.
             10 WS-UB-VAL-DATE           PIC 9(14) VALUE 20261015120000.
             10 WS-UB-NARRATIVE          PIC X(48) VALUE SPACES.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> Setup balanced batch data in table
           MOVE "ACC-TEST-001    " TO WS-BB-ACC-ID(1)
           MOVE "ACC-TEST-002    " TO WS-BB-CPTY-ID(1)
           MOVE "D"                TO WS-BB-DIR(1)
           MOVE 100000.00000000    TO WS-BB-AMT(1)
           MOVE "USD"              TO WS-BB-CCY(1)
           MOVE 1                  TO WS-BB-TYPE(1)
           MOVE 20261015120000     TO WS-BB-VAL-DATE(1)
           MOVE "Test Debit Leg"   TO WS-BB-NARRATIVE(1)

           MOVE "ACC-TEST-002    " TO WS-BB-ACC-ID(2)
           MOVE "ACC-TEST-001    " TO WS-BB-CPTY-ID(2)
           MOVE "C"                TO WS-BB-DIR(2)
           MOVE 100000.00000000    TO WS-BB-AMT(2)
           MOVE "USD"              TO WS-BB-CCY(2)
           MOVE 1                  TO WS-BB-TYPE(2)
           MOVE 20261015120000     TO WS-BB-VAL-DATE(2)
           MOVE "Test Credit Leg"  TO WS-BB-NARRATIVE(2)

      *> Setup unbalanced batch data in table
           MOVE "ACC-TEST-001    " TO WS-UB-ACC-ID(1)
           MOVE "ACC-TEST-002    " TO WS-UB-CPTY-ID(1)
           MOVE "D"                TO WS-UB-DIR(1)
           MOVE 100000.00000000    TO WS-UB-AMT(1)
           MOVE "USD"              TO WS-UB-CCY(1)
           MOVE 1                  TO WS-UB-TYPE(1)
           MOVE 20261015120000     TO WS-UB-VAL-DATE(1)
           MOVE "Unbalanced Debit" TO WS-UB-NARRATIVE(1)

           MOVE "ACC-TEST-002    " TO WS-UB-ACC-ID(2)
           MOVE "ACC-TEST-001    " TO WS-UB-CPTY-ID(2)
           MOVE "C"                TO WS-UB-DIR(2)
           MOVE 50000.00000000     TO WS-UB-AMT(2)
           MOVE "USD"              TO WS-UB-CCY(2)
           MOVE 1                  TO WS-UB-TYPE(2)
           MOVE 20261015120000     TO WS-UB-VAL-DATE(2)
           MOVE "Unbalanced Credit" TO WS-UB-NARRATIVE(2)

      *>----------------------------------------------------------------*
      *> TEST 1: Provision test accounts
      *>----------------------------------------------------------------*
           MOVE "ACC-TEST-001    " TO WS-ACC-ID
           MOVE "TESTBIC1XXX"      TO WS-OWNER-BIC
           MOVE "USD"              TO WS-CCY
           MOVE 1                  TO WS-ACC-TYPE
           MOVE 0                  TO WS-AMOUNT
           MOVE 1000000.00000000   TO WS-LIMIT
           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         WS-ACC-ID
                                         WS-OWNER-BIC
                                         WS-CCY
                                         WS-ACC-TYPE
                                         WS-AMOUNT
                                         WS-LIMIT
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Account creation failed for ACC-TEST-001: " WS-STATUS
           END-IF

           MOVE "ACC-TEST-002    " TO WS-ACC-ID
           MOVE "TESTBIC2XXX"      TO WS-OWNER-BIC
           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         WS-ACC-ID
                                         WS-OWNER-BIC
                                         WS-CCY
                                         WS-ACC-TYPE
                                         WS-AMOUNT
                                         WS-LIMIT
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Account creation failed for ACC-TEST-002: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Credit initial funds
      *>----------------------------------------------------------------*
           MOVE "ACC-TEST-001    " TO WS-ACC-ID
           MOVE SPACES             TO WS-OWNER-BIC
           MOVE 500000.00000000    TO WS-AMOUNT
           MOVE 0                  TO WS-LIMIT
           CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  "
                                         WS-ACC-ID
                                         WS-OWNER-BIC
                                         WS-CCY
                                         WS-ACC-TYPE
                                         WS-AMOUNT
                                         WS-LIMIT
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Credit balance failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Lock Margin Encumbrance
      *>----------------------------------------------------------------*
           MOVE 200000.00000000 TO WS-AMOUNT
           CALL "BSLT-ACCOUNT-MGR" USING "LOCK-MRG"
                                         WS-ACC-ID
                                         WS-OWNER-BIC
                                         WS-CCY
                                         WS-ACC-TYPE
                                         WS-AMOUNT
                                         WS-LIMIT
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS = BS-RC-OK
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Lock margin encumbrance failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Post balanced double-entry batch
      *>----------------------------------------------------------------*
           MOVE 1001 TO WS-BATCH-ID
           MOVE 2    TO WS-BATCH-COUNT
           CALL "BSLT-JOURNAL" USING "POST    "
                                     WS-BATCH-ID
                                     WS-BATCH-COUNT
                                     WS-BALANCED-BATCH
                                     WS-COMMITTED
                                     WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-COMMITTED = 2
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Balanced batch posting failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: Reject unbalanced batch (debits != credits)
      *>----------------------------------------------------------------*
           MOVE 1002 TO WS-BATCH-ID
           MOVE 2    TO WS-BATCH-COUNT
           CALL "BSLT-JOURNAL" USING "POST    "
                                     WS-BATCH-ID
                                     WS-BATCH-COUNT
                                     WS-UNBALANCED-BATCH
                                     WS-COMMITTED
                                     WS-STATUS
           IF WS-STATUS = BS-RC-UNBALANCED-ENTRY
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Unbalanced batch was not rejected: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Bi-temporal AS-OF query
      *>----------------------------------------------------------------*
           MOVE "ACC-TEST-001    " TO WS-ACC-ID
           MOVE "USD"              TO WS-CCY
           MOVE 20261015120000     TO WS-VAL-TIME WS-SYS-TIME
           MOVE 100000.00000000    TO WS-QUERY-BAL
           MOVE "C"                TO WS-DIR
           CALL "BSLT-BITEMPORAL" USING "AS-OF   "
                                        WS-ACC-ID
                                        WS-CCY
                                        WS-VAL-TIME
                                        WS-SYS-TIME
                                        WS-QUERY-BAL
                                        WS-DIR
                                        WS-RECON-BAL
                                        WS-MATCH-COUNT
                                        WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-MATCH-COUNT > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Bi-temporal AS-OF query failed: " WS-STATUS
           END-IF.

           GOBACK.
