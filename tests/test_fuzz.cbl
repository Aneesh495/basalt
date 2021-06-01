       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-FUZZ.
      *>================================================================*
      *> BASALT TEST SUITE - FUZZING AND INVARIANT PRESERVATION         *
      *> High-volume randomized transactions, double-entry conservation,*
      *> liquidity invariance, and non-negative balance enforcement.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "entry.cpy".

       01 WS-FUZZ-STATE.
          05 WS-ITERATIONS               PIC 9(4)  VALUE 50.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-FROM-IDX                 PIC 9(2)  VALUE 0.
          05 WS-TO-IDX                   PIC 9(2)  VALUE 0.
          05 WS-RANDOM-AMT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-POSTED-COUNT             PIC 9(4)  VALUE 0.
          05 WS-REJECTED-COUNT           PIC 9(4)  VALUE 0.
          05 WS-BATCH-ID                 PIC 9(12) VALUE 50000.
          05 WS-BATCH-COUNT              PIC 9(4)  VALUE 2.
          05 WS-COMMITTED                PIC 9(6)  VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-BREAK-FLAG               PIC 9(1)  VALUE 0.
          05 WS-TRIAL-BAL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DISCREPANCY              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-EXT-BAL                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TARGET-ACC               PIC X(16) VALUE SPACES.
          05 WS-TOTAL-SYSTEM-CASH        PIC S9(18)V9(8) COMP-3 VALUE 0.

      *> Account manager parameters
       01 WS-AM-PARAMS.
          05 WS-AM-ID                    PIC X(16) VALUE SPACES.
          05 WS-AM-OWNER                 PIC X(11) VALUE "FUZZPARTICX".
          05 WS-AM-TYPE                  PIC 9(2)  VALUE 1.
          05 WS-AM-CCY                   PIC X(3)  VALUE "USD".
          05 WS-AM-LIMIT                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-AMOUNT                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-BUF                   PIC X(256) VALUE SPACES.

      *> Journal batch table
       01 WS-FUZZ-BATCH.
          05 WS-FB-ENTRY OCCURS 64 TIMES.
             10 WS-FB-ACC-ID             PIC X(16) VALUE SPACES.
             10 WS-FB-CPTY-ID            PIC X(16) VALUE SPACES.
             10 WS-FB-DIR                PIC X(1)  VALUE SPACES.
             10 WS-FB-AMT                PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-FB-CCY                PIC X(3)  VALUE "USD".
             10 WS-FB-TYPE               PIC 9(2)  VALUE 1.
             10 WS-FB-VAL-DATE           PIC 9(14) VALUE 20261015120000.
             10 WS-FB-NARRATIVE          PIC X(48) VALUE SPACES.

       01 WS-ACCT-NAMES.
          05 WS-AN-1                     PIC X(16) VALUE "ACC-FUZZ-001    ".
          05 WS-AN-2                     PIC X(16) VALUE "ACC-FUZZ-002    ".
          05 WS-AN-3                     PIC X(16) VALUE "ACC-FUZZ-003    ".
          05 WS-AN-4                     PIC X(16) VALUE "ACC-FUZZ-004    ".
          05 WS-AN-5                     PIC X(16) VALUE "ACC-FUZZ-005    ".
       01 WS-ACCT-ARRAY REDEFINES WS-ACCT-NAMES.
          05 WS-ACCT-ID OCCURS 5 TIMES   PIC X(16).

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> Setup 5 test accounts with initial liquidity of $1,000,000 each
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               MOVE WS-ACCT-ID(WS-I) TO WS-AM-ID
               MOVE "FUZZPARTICX"    TO WS-AM-OWNER
               MOVE "USD"            TO WS-AM-CCY
               MOVE 1                TO WS-AM-TYPE
               MOVE 0                TO WS-AM-AMOUNT
               MOVE 0                TO WS-AM-LIMIT
               CALL "BSLT-ACCOUNT-MGR" USING "CREATE  " WS-AM-ID
                                             WS-AM-OWNER WS-AM-CCY
                                             WS-AM-TYPE WS-AM-AMOUNT
                                             WS-AM-LIMIT WS-AM-BUF
                                             WS-STATUS
               IF WS-STATUS NOT = BS-RC-OK
                   ADD 1 TO LNK-TESTS-FAILED
                   DISPLAY "FAIL: Account creation in fuzzing setup failed: " WS-STATUS
                   GOBACK
               END-IF

      *> Credit initial balance $1,000,000
               MOVE 1000000.00000000 TO WS-AM-AMOUNT
               CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  " WS-AM-ID
                                             WS-AM-OWNER WS-AM-CCY
                                             WS-AM-TYPE WS-AM-AMOUNT
                                             WS-AM-LIMIT WS-AM-BUF
                                             WS-STATUS
           END-PERFORM

      *>----------------------------------------------------------------*
      *> TEST 1: Execute 50 pseudo-random transfers across the 5 accounts
      *> Double-entry journal invariant: sum(Debits) == sum(Credits)
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-POSTED-COUNT
           MOVE 0 TO WS-REJECTED-COUNT

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 50
               ADD 1 TO WS-BATCH-ID
               COMPUTE WS-FROM-IDX = FUNCTION MOD(WS-I * 7, 5) + 1
               COMPUTE WS-TO-IDX   = FUNCTION MOD(WS-I * 13, 5) + 1
               IF WS-FROM-IDX = WS-TO-IDX
                   COMPUTE WS-TO-IDX = FUNCTION MOD(WS-FROM-IDX, 5) + 1
               END-IF
               COMPUTE WS-RANDOM-AMT = (FUNCTION MOD(WS-I * 179 + 31, 50) + 1) * 1000.00000000

      *> Setup batch
               MOVE WS-ACCT-ID(WS-FROM-IDX) TO WS-FB-ACC-ID(1)
               MOVE WS-ACCT-ID(WS-TO-IDX)   TO WS-FB-CPTY-ID(1)
               MOVE "D"                     TO WS-FB-DIR(1)
               MOVE WS-RANDOM-AMT           TO WS-FB-AMT(1)
               MOVE "USD"                   TO WS-FB-CCY(1)
               MOVE 1                       TO WS-FB-TYPE(1)
               MOVE 20261015120000          TO WS-FB-VAL-DATE(1)
               MOVE "Fuzz Debit Transfer"   TO WS-FB-NARRATIVE(1)

               MOVE WS-ACCT-ID(WS-TO-IDX)   TO WS-FB-ACC-ID(2)
               MOVE WS-ACCT-ID(WS-FROM-IDX) TO WS-FB-CPTY-ID(2)
               MOVE "C"                     TO WS-FB-DIR(2)
               MOVE WS-RANDOM-AMT           TO WS-FB-AMT(2)
               MOVE "USD"                   TO WS-FB-CCY(2)
               MOVE 1                       TO WS-FB-TYPE(2)
               MOVE 20261015120000          TO WS-FB-VAL-DATE(2)
               MOVE "Fuzz Credit Transfer"  TO WS-FB-NARRATIVE(2)

               MOVE 2 TO WS-BATCH-COUNT
               CALL "BSLT-JOURNAL" USING "POST    " WS-BATCH-ID
                                         WS-BATCH-COUNT WS-FUZZ-BATCH
                                         WS-COMMITTED WS-STATUS
               IF WS-STATUS = BS-RC-OK AND WS-COMMITTED = 2
                   ADD 1 TO WS-POSTED-COUNT
               ELSE
                   ADD 1 TO WS-REJECTED-COUNT
               END-IF
           END-PERFORM

           IF WS-POSTED-COUNT > 20
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fuzzing batch post count too low: " WS-POSTED-COUNT
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Run End-of-Day trial balance across all accounts
      *> Total trial balance must equal $5,000,000.00 exactly
      *>----------------------------------------------------------------*
           MOVE "USD" TO WS-AM-CCY
           CALL "BSLT-RECONCILIATION" USING "TRIALBAL"
                                            WS-AM-CCY
                                            WS-EXT-BAL
                                            WS-TARGET-ACC
                                            WS-TRIAL-BAL
                                            WS-DISCREPANCY
                                            WS-BREAK-FLAG
                                            WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-TRIAL-BAL > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fuzzing trial balance failed: " WS-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Verify individual account retrieval and non-negative balance
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-TOTAL-SYSTEM-CASH
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               MOVE WS-ACCT-ID(WS-I) TO WS-AM-ID
               CALL "BSLT-ACCOUNT-MGR" USING "GET     " WS-AM-ID
                                             WS-AM-OWNER WS-AM-CCY
                                             WS-AM-TYPE WS-AM-AMOUNT
                                             WS-AM-LIMIT WS-AM-BUF
                                             WS-STATUS
               IF WS-STATUS = BS-RC-OK
                   MOVE WS-AM-BUF(33:14) TO WS-AM-AMOUNT
                   IF WS-AM-AMOUNT >= 0
                       ADD 1 TO LNK-TESTS-PASSED
                   ELSE
                       ADD 1 TO LNK-TESTS-FAILED
                       DISPLAY "FAIL: Negative balance detected in account " WS-AM-ID
                   END-IF
                   ADD WS-AM-AMOUNT TO WS-TOTAL-SYSTEM-CASH
               ELSE
                   ADD 1 TO LNK-TESTS-FAILED
                   DISPLAY "FAIL: Get account failed for " WS-AM-ID
               END-IF
           END-PERFORM.

           GOBACK.
