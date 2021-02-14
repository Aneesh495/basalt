       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-ACCOUNT-MGR.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - BI-TEMPORAL ACCOUNT MANAGER     *
      *> Account provisioning, balance verification, liquidity locks,   *
      *> multi-currency balance tracking, and credit limit validation. *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".

       01 WS-TEMP-SEARCH-IDX             PIC 9(6)  VALUE 0.
       01 WS-FOUND-FLAG                  PIC 9(1)  VALUE 0.
       01 WS-CALC-AVAILABLE              PIC S9(18)V9(8) COMP-3 VALUE 0.
       01 WS-REQUIRED-LIQUIDITY          PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-ACC-OP                     PIC X(8).
       01 LNK-IN-ACC-ID                  PIC X(16).
       01 LNK-IN-OWNER-BIC               PIC X(11).
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-IN-TYPE                    PIC 9(2).
       01 LNK-IN-AMOUNT                  PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-CREDIT-LIMIT            PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-ACCOUNT                PIC X(256).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-ACC-OP LNK-IN-ACC-ID
                                LNK-IN-OWNER-BIC LNK-IN-CURRENCY
                                LNK-IN-TYPE LNK-IN-AMOUNT
                                LNK-IN-CREDIT-LIMIT LNK-OUT-ACCOUNT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-ACC-OP
               WHEN "CREATE  "
                   PERFORM 1000-CREATE-ACCOUNT
               WHEN "GET     "
                   PERFORM 2000-GET-ACCOUNT
               WHEN "CREDIT  "
                   PERFORM 3000-CREDIT-BALANCE
               WHEN "DEBIT   "
                   PERFORM 4000-DEBIT-BALANCE
               WHEN "LOCK-MRG"
                   PERFORM 5000-LOCK-MARGIN
               WHEN "FREE-MRG"
                   PERFORM 6000-RELEASE-MARGIN
               WHEN "FREEZE  "
                   PERFORM 7000-FREEZE-ACCOUNT
               WHEN "UNFREEZE"
                   PERFORM 8000-UNFREEZE-ACCOUNT
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-CREATE-ACCOUNT.
      *> Search for duplicate account ID
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 1
               MOVE BS-RC-DUPLICATE TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF BS-ACC-COUNT >= BS-MAX-ACCOUNTS
               MOVE BS-RC-PAGE-FULL TO LNK-OUT-STATUS
               GOBACK
           END-IF

           ADD 1 TO BS-ACC-COUNT
           MOVE BS-ACC-COUNT TO WS-TEMP-SEARCH-IDX

           MOVE LNK-IN-ACC-ID       TO BS-TBL-ACC-ID(WS-TEMP-SEARCH-IDX)
           MOVE LNK-IN-OWNER-BIC    TO BS-TBL-ACC-OWNER-BIC(WS-TEMP-SEARCH-IDX)
           MOVE LNK-IN-CURRENCY     TO BS-TBL-ACC-CURRENCY(WS-TEMP-SEARCH-IDX)
           MOVE LNK-IN-TYPE         TO BS-TBL-ACC-TYPE(WS-TEMP-SEARCH-IDX)
           MOVE 'A'                 TO BS-TBL-ACC-STATUS(WS-TEMP-SEARCH-IDX)
           MOVE 0                   TO BS-TBL-ACC-SETTLED-BAL(WS-TEMP-SEARCH-IDX)
           MOVE 0                   TO BS-TBL-ACC-PENDING-DEB(WS-TEMP-SEARCH-IDX)
           MOVE 0                   TO BS-TBL-ACC-PENDING-CRE(WS-TEMP-SEARCH-IDX)
           MOVE 0                   TO BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX)
           MOVE LNK-IN-CREDIT-LIMIT TO BS-TBL-ACC-CREDIT-LIMIT(WS-TEMP-SEARCH-IDX)
           MOVE LNK-IN-CREDIT-LIMIT TO BS-TBL-ACC-AVAILABLE(WS-TEMP-SEARCH-IDX)
           MOVE 20260101000000      TO BS-TBL-ACC-VALID-FROM(WS-TEMP-SEARCH-IDX)
           MOVE 99999999999999      TO BS-TBL-ACC-VALID-TO(WS-TEMP-SEARCH-IDX)
           MOVE 20260101000000      TO BS-TBL-ACC-SYSTEM-FROM(WS-TEMP-SEARCH-IDX)
           MOVE 99999999999999      TO BS-TBL-ACC-SYSTEM-TO(WS-TEMP-SEARCH-IDX)
           MOVE 0                   TO BS-TBL-ACC-LAST-LSN(WS-TEMP-SEARCH-IDX).

       2000-GET-ACCOUNT.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> Export table entry into linkage output buffer
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       3000-CREDIT-BALANCE.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF BS-TBL-ACC-STATUS(WS-TEMP-SEARCH-IDX) NOT = 'A'
               MOVE BS-RC-INVALID-STATE TO LNK-OUT-STATUS
               GOBACK
           END-IF

           ADD LNK-IN-AMOUNT TO 
               BS-TBL-ACC-SETTLED-BAL(WS-TEMP-SEARCH-IDX)
           PERFORM 9100-RECALC-AVAILABLE
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       4000-DEBIT-BALANCE.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF BS-TBL-ACC-STATUS(WS-TEMP-SEARCH-IDX) NOT = 'A'
               MOVE BS-RC-INVALID-STATE TO LNK-OUT-STATUS
               GOBACK
           END-IF

           PERFORM 9100-RECALC-AVAILABLE
           IF LNK-IN-AMOUNT > BS-TBL-ACC-AVAILABLE(WS-TEMP-SEARCH-IDX)
               MOVE BS-RC-INSUFFICIENT-FUNDS TO LNK-OUT-STATUS
               GOBACK
           END-IF

           SUBTRACT LNK-IN-AMOUNT FROM 
               BS-TBL-ACC-SETTLED-BAL(WS-TEMP-SEARCH-IDX)
           PERFORM 9100-RECALC-AVAILABLE
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       5000-LOCK-MARGIN.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

           PERFORM 9100-RECALC-AVAILABLE
           IF LNK-IN-AMOUNT > BS-TBL-ACC-AVAILABLE(WS-TEMP-SEARCH-IDX)
               MOVE BS-RC-INSUFFICIENT-FUNDS TO LNK-OUT-STATUS
               GOBACK
           END-IF

           ADD LNK-IN-AMOUNT TO 
               BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX)
           PERFORM 9100-RECALC-AVAILABLE
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       6000-RELEASE-MARGIN.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF LNK-IN-AMOUNT > BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX)
               MOVE BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX) 
                   TO LNK-IN-AMOUNT
           END-IF

           SUBTRACT LNK-IN-AMOUNT FROM 
               BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX)
           PERFORM 9100-RECALC-AVAILABLE
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       7000-FREEZE-ACCOUNT.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF
           MOVE 'F' TO BS-TBL-ACC-STATUS(WS-TEMP-SEARCH-IDX)
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       8000-UNFREEZE-ACCOUNT.
           PERFORM 9000-FIND-ACCOUNT
           IF WS-FOUND-FLAG = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF
           MOVE 'A' TO BS-TBL-ACC-STATUS(WS-TEMP-SEARCH-IDX)
           MOVE BS-ACC-ENTRY(WS-TEMP-SEARCH-IDX) TO LNK-OUT-ACCOUNT.

       9000-FIND-ACCOUNT.
           MOVE 0 TO WS-FOUND-FLAG
           MOVE 0 TO WS-TEMP-SEARCH-IDX
           PERFORM VARYING WS-TEMP-SEARCH-IDX FROM 1 BY 1 
                   UNTIL WS-TEMP-SEARCH-IDX > BS-ACC-COUNT
               IF BS-TBL-ACC-ID(WS-TEMP-SEARCH-IDX) = LNK-IN-ACC-ID
                   MOVE 1 TO WS-FOUND-FLAG
                   EXIT PERFORM
               END-IF
           END-PERFORM.

       9100-RECALC-AVAILABLE.
      *> Available = Settled - Encumbered + CreditLimit
           COMPUTE BS-TBL-ACC-AVAILABLE(WS-TEMP-SEARCH-IDX) ROUNDED = 
               (BS-TBL-ACC-SETTLED-BAL(WS-TEMP-SEARCH-IDX) - 
                BS-TBL-ACC-ENCUMBERED(WS-TEMP-SEARCH-IDX)) + 
                BS-TBL-ACC-CREDIT-LIMIT(WS-TEMP-SEARCH-IDX).
