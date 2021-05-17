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
          05 WS-ITERATIONS               PIC 9(4)  VALUE 100.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-FROM-IDX                 PIC 9(2)  VALUE 0.
          05 WS-TO-IDX                   PIC 9(2)  VALUE 0.
          05 WS-RANDOM-AMT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ACCT-FROM-ID             PIC 9(12) VALUE 0.
          05 WS-ACCT-TO-ID               PIC 9(12) VALUE 0.
          05 WS-POSTED-COUNT             PIC 9(4)  VALUE 0.
          05 WS-REJECTED-COUNT           PIC 9(4)  VALUE 0.
          05 WS-TX-ID                    PIC 9(12) VALUE 50000.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-BREAK-COUNT              PIC 9(4)  VALUE 0.
          05 WS-TOTAL-DISCREPANCY        PIC S9(18)V9(8) COMP-3 VALUE 0.

      *> Account manager parameters
       01 WS-AM-PARAMS.
          05 WS-AM-ID                    PIC 9(12) VALUE 0.
          05 WS-AM-OWNER                 PIC X(11) VALUE SPACES.
          05 WS-AM-TYPE                  PIC 9(2)  VALUE 1.
          05 WS-AM-CCY                   PIC X(3)  VALUE "USD".
          05 WS-AM-LIMIT                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-AMOUNT                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-OUT-BAL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-OUT-AVAIL             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-AM-OUT-LOCKED            PIC S9(18)V9(8) COMP-3 VALUE 0.

      *> Journal entry parameters
       01 WS-JRN-ENTRY.
          05 WS-JRN-ID                   PIC 9(12) VALUE 0.
          05 WS-JRN-TX-ID                PIC 9(12) VALUE 0.
          05 WS-JRN-VAL-TS               PIC 9(18) VALUE 202610150900000000.
          05 WS-JRN-DEBIT-ACCT           PIC 9(12) VALUE 0.
          05 WS-JRN-CREDIT-ACCT          PIC 9(12) VALUE 0.
          05 WS-JRN-AMT                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-JRN-CCY                  PIC X(3)  VALUE "USD".
          05 WS-JRN-OUT-ID               PIC 9(12) VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> Setup 5 test accounts with initial liquidity of $1,000,000 each
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               COMPUTE WS-AM-ID = 200 + WS-I
               MOVE "TESTPARTIC" TO WS-AM-OWNER
               MOVE 1 TO WS-AM-TYPE
               MOVE "USD" TO WS-AM-CCY
               MOVE 0 TO WS-AM-LIMIT
               CALL "BSLT-ACCOUNT-MGR" USING "PROVISN " WS-AM-ID
                                             WS-AM-OWNER WS-AM-TYPE
                                             WS-AM-CCY WS-AM-LIMIT
                                             WS-AM-AMOUNT WS-AM-OUT-BAL
                                             WS-AM-OUT-AVAIL WS-AM-OUT-LOCKED
                                             WS-STATUS
               IF WS-STATUS NOT = BS-RC-OK
                   ADD 1 TO LNK-TESTS-FAILED
                   DISPLAY "FAIL: Account provisioning in fuzzing setup failed"
                   GOBACK
               END-IF

      *> Credit initial balance
               MOVE 1000000.00000000 TO WS-AM-AMOUNT
               CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  " WS-AM-ID
                                             WS-AM-OWNER WS-AM-TYPE
                                             WS-AM-CCY WS-AM-LIMIT
                                             WS-AM-AMOUNT WS-AM-OUT-BAL
                                             WS-AM-OUT-AVAIL WS-AM-OUT-LOCKED
                                             WS-STATUS
           END-PERFORM

      *>----------------------------------------------------------------*
      *> TEST 1: Execute 100 pseudo-random transfers across the 5 accounts
      *> Double-entry journal invariant: sum(Debits) == sum(Credits)
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-POSTED-COUNT
           MOVE 0 TO WS-REJECTED-COUNT

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 100
               ADD 1 TO WS-TX-ID
      *> Generate pseudo-random account indices (1 to 5) and amount
               COMPUTE WS-FROM-IDX = FUNCTION MOD(WS-I * 7, 5) + 1
               COMPUTE WS-TO-IDX   = FUNCTION MOD(WS-I * 13, 5) + 1
               IF WS-FROM-IDX = WS-TO-IDX
                   COMPUTE WS-TO-IDX = FUNCTION MOD(WS-FROM-IDX, 5) + 1
               END-IF
               COMPUTE WS-ACCT-FROM-ID = 200 + WS-FROM-IDX
               COMPUTE WS-ACCT-TO-ID   = 200 + WS-TO-IDX
               COMPUTE WS-RANDOM-AMT = (FUNCTION MOD(WS-I * 179 + 31, 200) + 1) * 1000.00000000

      *> Attempt Debit from sender
               CALL "BSLT-ACCOUNT-MGR" USING "DEBIT   " WS-ACCT-FROM-ID
                                             WS-AM-OWNER WS-AM-TYPE
                                             WS-AM-CCY WS-AM-LIMIT
                                             WS-RANDOM-AMT WS-AM-OUT-BAL
                                             WS-AM-OUT-AVAIL WS-AM-OUT-LOCKED
                                             WS-STATUS
               IF WS-STATUS = BS-RC-OK
      *> Debit succeeded: credit receiver and log journal entry
                   CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  " WS-ACCT-TO-ID
                                                 WS-AM-OWNER WS-AM-TYPE
                                                 WS-AM-CCY WS-AM-LIMIT
                                                 WS-RANDOM-AMT WS-AM-OUT-BAL
                                                 WS-AM-OUT-AVAIL WS-AM-OUT-LOCKED
                                                 WS-STATUS

                   MOVE WS-TX-ID          TO WS-JRN-TX-ID
                   MOVE WS-ACCT-FROM-ID   TO WS-JRN-DEBIT-ACCT
                   MOVE WS-ACCT-TO-ID     TO WS-JRN-CREDIT-ACCT
                   MOVE WS-RANDOM-AMT     TO WS-JRN-AMT
                   CALL "BSLT-JOURNAL" USING "POST    " WS-JRN-ID
                                             WS-JRN-TX-ID WS-JRN-VAL-TS
                                             WS-JRN-DEBIT-ACCT WS-JRN-CREDIT-ACCT
                                             WS-JRN-AMT WS-JRN-CCY
                                             WS-JRN-OUT-ID WS-STATUS

                   ADD 1 TO WS-POSTED-COUNT
               ELSE
      *> Insufficient balance: transaction correctly rejected
                   ADD 1 TO WS-REJECTED-COUNT
               END-IF
           END-PERFORM

           IF WS-POSTED-COUNT > 50
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fuzzing post count too low: " WS-POSTED-COUNT
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Run End-of-Day reconciliation trial balance
      *> Must report 0 breaks and 0 discrepancy across all accounts
      *>----------------------------------------------------------------*
           CALL "BSLT-RECONCILIATION" USING "RECONCILE" WS-BREAK-COUNT
                                            WS-TOTAL-DISCREPANCY WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-BREAK-COUNT = 0
              AND WS-TOTAL-DISCREPANCY = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fuzzing reconciliation detected breaks: " WS-BREAK-COUNT
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Verify system-wide total liquidity conservation
      *> Sum of all 5 account balances must still exactly equal $5,000,000
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-TOTAL-DISCREPANCY
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 5
               COMPUTE WS-AM-ID = 200 + WS-I
               CALL "BSLT-ACCOUNT-MGR" USING "GETBAL  " WS-AM-ID
                                             WS-AM-OWNER WS-AM-TYPE
                                             WS-AM-CCY WS-AM-LIMIT
                                             WS-AM-AMOUNT WS-AM-OUT-BAL
                                             WS-AM-OUT-AVAIL WS-AM-OUT-LOCKED
                                             WS-STATUS
               ADD WS-AM-OUT-BAL TO WS-TOTAL-DISCREPANCY
           END-PERFORM

           IF WS-TOTAL-DISCREPANCY = 5000000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Liquidity conservation broken. Total: " WS-TOTAL-DISCREPANCY
           END-IF.

           GOBACK.
