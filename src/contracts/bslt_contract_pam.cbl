       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-PAM.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ACTUS PAM CONTRACT LIFECYCLE     *
      *> Principal at Maturity (PAM): Fixed-rate plain vanilla bond.    *
      *> Full cash-flow schedule generation, intermediate coupon accrual*
      *> and bullet principal redemption at maturity.                   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-PAM-VARS.
          05 WS-FLOW-COUNT               PIC 9(4)        VALUE 0.
          05 WS-CURR-DATE                PIC 9(8)        VALUE 0.
          05 WS-NEXT-DATE                PIC 9(8)        VALUE 0.
          05 WS-COUPON-AMT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-YEAR-FRAC                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-DAYS                     PIC 9(6)        VALUE 0.
          05 WS-STATUS                   PIC 9(4)        VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.
          05 WS-Y                        PIC 9(4)        VALUE 0.
          05 WS-M                        PIC 9(2)        VALUE 0.
          05 WS-D                        PIC 9(2)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-PAM-OP                     PIC X(8).
       01 LNK-IN-CONTRACT-ID             PIC X(16).
       01 LNK-IN-PRINCIPAL               PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-ANNUAL-RATE             PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-DAYCOUNT                PIC 9(2).
       01 LNK-IN-FREQ-MONTHS             PIC 9(2).
       01 LNK-IN-IED-DATE                PIC 9(8).
       01 LNK-IN-MD-DATE                 PIC 9(8).
       01 LNK-OUT-TOTAL-CASHFLOWS        PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-SCHEDULE-COUNT         PIC 9(4).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-PAM-OP LNK-IN-CONTRACT-ID
                                LNK-IN-PRINCIPAL LNK-IN-ANNUAL-RATE
                                LNK-IN-DAYCOUNT LNK-IN-FREQ-MONTHS
                                LNK-IN-IED-DATE LNK-IN-MD-DATE
                                LNK-OUT-TOTAL-CASHFLOWS
                                LNK-OUT-SCHEDULE-COUNT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-TOTAL-CASHFLOWS
           MOVE 0 TO LNK-OUT-SCHEDULE-COUNT
           MOVE 0 TO WS-FLOW-COUNT

           IF LNK-IN-PRINCIPAL <= 0 OR LNK-IN-MD-DATE <= LNK-IN-IED-DATE
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF LNK-IN-FREQ-MONTHS = 0
               MOVE 6 TO LNK-IN-FREQ-MONTHS
           END-IF

           MOVE LNK-IN-IED-DATE TO WS-CURR-DATE

      *> Loop through each coupon period up to maturity
           PERFORM UNTIL WS-CURR-DATE >= LNK-IN-MD-DATE OR WS-FLOW-COUNT >= 64
               ADD 1 TO WS-FLOW-COUNT

      *> Calculate next roll date by advancing months
               MOVE WS-CURR-DATE(1:4) TO WS-Y
               MOVE WS-CURR-DATE(5:2) TO WS-M
               MOVE WS-CURR-DATE(7:2) TO WS-D

               ADD LNK-IN-FREQ-MONTHS TO WS-M
               IF WS-M > 12
                   SUBTRACT 12 FROM WS-M
                   ADD 1 TO WS-Y
               END-IF
               COMPUTE WS-NEXT-DATE = (WS-Y * 10000) + (WS-M * 100) + WS-D

               IF WS-NEXT-DATE >= LNK-IN-MD-DATE
                   MOVE LNK-IN-MD-DATE TO WS-NEXT-DATE
               END-IF

      *> Compute day-count fraction for this coupon period
               CALL "BSLT-DAYCOUNT" USING LNK-IN-DAYCOUNT
                                          WS-CURR-DATE
                                          WS-NEXT-DATE
                                          WS-DAYS
                                          WS-YEAR-FRAC
                                          WS-STATUS

               COMPUTE WS-COUPON-AMT ROUNDED = 
                   LNK-IN-PRINCIPAL * LNK-IN-ANNUAL-RATE * WS-YEAR-FRAC

               MOVE WS-NEXT-DATE TO BS-FLOW-DATE(WS-FLOW-COUNT)
               MOVE WS-COUPON-AMT TO BS-FLOW-INTEREST-AMT(WS-FLOW-COUNT)

               IF WS-NEXT-DATE = LNK-IN-MD-DATE
      *> Maturity event: final coupon plus full principal return
                   MOVE 4 TO BS-FLOW-EVENT-TYPE(WS-FLOW-COUNT)
                   MOVE LNK-IN-PRINCIPAL 
                       TO BS-FLOW-PRINCIPAL-AMT(WS-FLOW-COUNT)
                   COMPUTE BS-FLOW-TOTAL-CASHFLOW(WS-FLOW-COUNT) = 
                       WS-COUPON-AMT + LNK-IN-PRINCIPAL
                   MOVE 0 TO BS-FLOW-REMAINING-BAL(WS-FLOW-COUNT)
               ELSE
      *> Regular coupon payment
                   MOVE 2 TO BS-FLOW-EVENT-TYPE(WS-FLOW-COUNT)
                   MOVE 0 TO BS-FLOW-PRINCIPAL-AMT(WS-FLOW-COUNT)
                   MOVE WS-COUPON-AMT 
                       TO BS-FLOW-TOTAL-CASHFLOW(WS-FLOW-COUNT)
                   MOVE LNK-IN-PRINCIPAL 
                       TO BS-FLOW-REMAINING-BAL(WS-FLOW-COUNT)
               END-IF

               ADD BS-FLOW-TOTAL-CASHFLOW(WS-FLOW-COUNT) 
                   TO LNK-OUT-TOTAL-CASHFLOWS
               MOVE WS-NEXT-DATE TO WS-CURR-DATE
           END-PERFORM

           MOVE WS-FLOW-COUNT TO LNK-OUT-SCHEDULE-COUNT.

           GOBACK.
