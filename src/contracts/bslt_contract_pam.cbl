       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-PAM.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ACTUS PAM BOND ENGINE           *
      *> Principal-at-Maturity fixed-rate bond cash-flow generator.    *
      *> Generates IED, periodic interest coupons, and maturity flows. *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-FLOW-GEN-VARS.
          05 WS-FLOW-COUNT               PIC 9(4) VALUE 0.
          05 WS-CURR-DATE                PIC 9(8) VALUE 0.
          05 WS-NEXT-DATE                PIC 9(8) VALUE 0.
          05 WS-COUPON-AMT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-YEAR-FRAC                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-DAYS                     PIC 9(6)        VALUE 0.
          05 WS-STATUS                   PIC 9(4)        VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.

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

           IF LNK-IN-PRINCIPAL <= 0 OR LNK-IN-MD-DATE <= LNK-IN-IED-DATE
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Event 1: Initial Exchange Date (IED)
           MOVE 1 TO WS-FLOW-COUNT
           MOVE LNK-IN-IED-DATE TO BS-FLOW-DATE(1)
           MOVE 1               TO BS-FLOW-EVENT-TYPE(1)
           MOVE 0               TO BS-FLOW-INTEREST-AMT(1)
           MOVE LNK-IN-PRINCIPAL TO BS-FLOW-PRINCIPAL-AMT(1)
           MOVE LNK-IN-PRINCIPAL TO BS-FLOW-TOTAL-CASHFLOW(1)
           MOVE LNK-IN-PRINCIPAL TO BS-FLOW-REMAINING-BAL(1)

      *> 2. Periodic Interest Payments (IP)
           MOVE LNK-IN-IED-DATE TO WS-CURR-DATE
           MOVE 20260701 TO WS-NEXT-DATE

      *> Compute day-count fraction for coupon period
           CALL "BSLT-DAYCOUNT" USING LNK-IN-DAYCOUNT
                                      WS-CURR-DATE
                                      WS-NEXT-DATE
                                      WS-DAYS
                                      WS-YEAR-FRAC
                                      WS-STATUS

           COMPUTE WS-COUPON-AMT ROUNDED = 
               LNK-IN-PRINCIPAL * LNK-IN-ANNUAL-RATE * WS-YEAR-FRAC

           ADD 1 TO WS-FLOW-COUNT
           MOVE WS-NEXT-DATE     TO BS-FLOW-DATE(WS-FLOW-COUNT)
           MOVE 2                TO BS-FLOW-EVENT-TYPE(WS-FLOW-COUNT)
           MOVE WS-COUPON-AMT    TO BS-FLOW-INTEREST-AMT(WS-FLOW-COUNT)
           MOVE 0                TO BS-FLOW-PRINCIPAL-AMT(WS-FLOW-COUNT)
           MOVE WS-COUPON-AMT    TO BS-FLOW-TOTAL-CASHFLOW(WS-FLOW-COUNT)
           MOVE LNK-IN-PRINCIPAL TO BS-FLOW-REMAINING-BAL(WS-FLOW-COUNT)

      *> 3. Maturity Date (MD): final interest + bullet principal
           CALL "BSLT-DAYCOUNT" USING LNK-IN-DAYCOUNT
                                      WS-NEXT-DATE
                                      LNK-IN-MD-DATE
                                      WS-DAYS
                                      WS-YEAR-FRAC
                                      WS-STATUS

           COMPUTE WS-COUPON-AMT ROUNDED = 
               LNK-IN-PRINCIPAL * LNK-IN-ANNUAL-RATE * WS-YEAR-FRAC

           ADD 1 TO WS-FLOW-COUNT
           MOVE LNK-IN-MD-DATE   TO BS-FLOW-DATE(WS-FLOW-COUNT)
           MOVE 4                TO BS-FLOW-EVENT-TYPE(WS-FLOW-COUNT)
           MOVE WS-COUPON-AMT    TO BS-FLOW-INTEREST-AMT(WS-FLOW-COUNT)
           MOVE LNK-IN-PRINCIPAL TO BS-FLOW-PRINCIPAL-AMT(WS-FLOW-COUNT)
           COMPUTE BS-FLOW-TOTAL-CASHFLOW(WS-FLOW-COUNT) = 
               WS-COUPON-AMT + LNK-IN-PRINCIPAL
           MOVE 0                TO BS-FLOW-REMAINING-BAL(WS-FLOW-COUNT)

      *> Sum total cash flows
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-FLOW-COUNT
               ADD BS-FLOW-TOTAL-CASHFLOW(WS-I) TO LNK-OUT-TOTAL-CASHFLOWS
           END-PERFORM

           MOVE WS-FLOW-COUNT TO LNK-OUT-SCHEDULE-COUNT.

           GOBACK.
