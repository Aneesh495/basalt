       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-RECONCILIATION.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - RECONCILIATION AND AUDIT        *
      *> End-of-day trial balance generator, multi-currency invariant   *
      *> verification, and interbank discrepancy break detection.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".

       01 WS-RECON-VARS.
          05 WS-TOTAL-SETTLED            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TOTAL-ENCUMBERED         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TOTAL-CREDIT-LIMITS      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-BREAK-COUNT              PIC 9(4)  VALUE 0.
          05 WS-I                        PIC 9(6)  VALUE 0.
          05 WS-DIFF                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-ACC-ID              PIC X(16) VALUE SPACES.
          05 WS-CALL-BIC                 PIC X(11) VALUE SPACES.
          05 WS-CALL-TYPE                PIC 9(2)  VALUE 0.
          05 WS-CALL-LIMIT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-OUT-ACC             PIC X(256) VALUE SPACES.
          05 WS-CALL-STATUS              PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-REC-OP                     PIC X(8).
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-IN-EXT-REPORTED-BAL        PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-TARGET-ACC-ID           PIC X(16).
       01 LNK-OUT-TRIAL-BALANCE          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-DISCREPANCY            PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-BREAK-FLAG             PIC 9(1).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-REC-OP LNK-IN-CURRENCY
                                LNK-IN-EXT-REPORTED-BAL
                                LNK-IN-TARGET-ACC-ID
                                LNK-OUT-TRIAL-BALANCE
                                LNK-OUT-DISCREPANCY
                                LNK-OUT-BREAK-FLAG
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-TRIAL-BALANCE
           MOVE 0 TO LNK-OUT-DISCREPANCY
           MOVE 0 TO LNK-OUT-BREAK-FLAG

           EVALUATE LNK-REC-OP
               WHEN "TRIALBAL"
                   PERFORM 1000-TRIAL-BALANCE
               WHEN "CHECKBRK"
                   PERFORM 2000-CHECK-BREAK
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-TRIAL-BALANCE.
      *> Aggregates all account balances in the specified currency via Account Manager
           MOVE 0 TO WS-TOTAL-SETTLED
           CALL "BSLT-ACCOUNT-MGR" USING "TRIALBAL"
                                         WS-CALL-ACC-ID
                                         WS-CALL-BIC
                                         LNK-IN-CURRENCY
                                         WS-CALL-TYPE
                                         WS-TOTAL-SETTLED
                                         WS-CALL-LIMIT
                                         WS-CALL-OUT-ACC
                                         WS-CALL-STATUS
           MOVE WS-TOTAL-SETTLED TO LNK-OUT-TRIAL-BALANCE.

       2000-CHECK-BREAK.
      *> Compares internal settled balance against external reported statement
           MOVE 0 TO LNK-OUT-BREAK-FLAG
           MOVE 0 TO LNK-OUT-DISCREPANCY
           CALL "BSLT-ACCOUNT-MGR" USING "GET     "
                                         LNK-IN-TARGET-ACC-ID
                                         WS-CALL-BIC
                                         LNK-IN-CURRENCY
                                         WS-CALL-TYPE
                                         WS-TOTAL-SETTLED
                                         WS-CALL-LIMIT
                                         WS-CALL-OUT-ACC
                                         WS-CALL-STATUS
           IF WS-CALL-STATUS = BS-RC-OK
               MOVE WS-CALL-OUT-ACC TO BS-ACCOUNT-RECORD
               COMPUTE WS-DIFF = 
                   BS-ACC-SETTLED-BAL - 
                   LNK-IN-EXT-REPORTED-BAL
               IF WS-DIFF NOT = 0
                   MOVE 1 TO LNK-OUT-BREAK-FLAG
                   MOVE WS-DIFF TO LNK-OUT-DISCREPANCY
               END-IF
           ELSE
               MOVE WS-CALL-STATUS TO LNK-OUT-STATUS
           END-IF.
