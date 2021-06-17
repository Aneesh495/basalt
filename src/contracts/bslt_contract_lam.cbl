       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-LAM.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ACTUS LAM CONTRACT LIFECYCLE     *
      *> Linear Amortizer (LAM): Equal principal reduction per period,  *
      *> decreasing interest accrual, and full terminal paydown.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-LAM-VARS.
          05 WS-FLOW-COUNT               PIC 9(4)        VALUE 0.
          05 WS-TOTAL-PERIODS            PIC 9(4)        VALUE 0.
          05 WS-CURR-DATE                PIC 9(8)        VALUE 0.
          05 WS-NEXT-DATE                PIC 9(8)        VALUE 0.
          05 WS-REMAINING-PRINCIPAL      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PRIN-PAYMENT             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-INTEREST-PAYMENT         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PERIOD-TOTAL             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-YEAR-FRAC                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-DAYS                     PIC 9(6)        VALUE 0.
          05 WS-STATUS                   PIC 9(4)        VALUE 0.
          05 WS-Y                        PIC 9(4)        VALUE 0.
          05 WS-M                        PIC 9(2)        VALUE 0.
          05 WS-D                        PIC 9(2)        VALUE 0.
          05 WS-SPAN-MONTHS              PIC 9(4)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-LAM-OP                     PIC X(8).
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

       PROCEDURE DIVISION USING LNK-LAM-OP LNK-IN-CONTRACT-ID
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

           MOVE LNK-IN-PRINCIPAL TO WS-REMAINING-PRINCIPAL
           MOVE LNK-IN-IED-DATE  TO WS-CURR-DATE

      *> Estimate total number of amortization periods
           MOVE LNK-IN-IED-DATE(1:4) TO WS-Y
           MOVE LNK-IN-IED-DATE(5:2) TO WS-M
           MOVE LNK-IN-MD-DATE(1:4)  TO WS-DAYS
           MOVE LNK-IN-MD-DATE(5:2)  TO WS-D
           COMPUTE WS-SPAN-MONTHS = 
               ((WS-DAYS - WS-Y) * 12) + (WS-D - WS-M)
           IF WS-SPAN-MONTHS <= 0
               MOVE 12 TO WS-SPAN-MONTHS
           END-IF

           DIVIDE WS-SPAN-MONTHS BY LNK-IN-FREQ-MONTHS GIVING WS-TOTAL-PERIODS
           IF WS-TOTAL-PERIODS = 0
               MOVE 1 TO WS-TOTAL-PERIODS
           END-IF

           DIVIDE LNK-IN-PRINCIPAL BY WS-TOTAL-PERIODS GIVING WS-PRIN-PAYMENT ROUNDED

           PERFORM UNTIL WS-CURR-DATE >= LNK-IN-MD-DATE OR WS-FLOW-COUNT >= 120
               ADD 1 TO WS-FLOW-COUNT

      *> Advance date by frequency months
               MOVE WS-CURR-DATE(1:4) TO WS-Y
               MOVE WS-CURR-DATE(5:2) TO WS-M
               MOVE WS-CURR-DATE(7:2) TO WS-D

               ADD LNK-IN-FREQ-MONTHS TO WS-M
               IF WS-M > 12
                   SUBTRACT 12 FROM WS-M
                   ADD 1 TO WS-Y
               END-IF

               COMPUTE WS-NEXT-DATE = (WS-Y * 10000) + (WS-M * 100) + WS-D
               IF WS-NEXT-DATE > LNK-IN-MD-DATE
                   MOVE LNK-IN-MD-DATE TO WS-NEXT-DATE
               END-IF

      *> Calculate day count fraction for interest period
               CALL "BSLT-DAYCOUNT" USING LNK-IN-DAYCOUNT
                                          WS-CURR-DATE
                                          WS-NEXT-DATE
                                          WS-DAYS
                                          WS-YEAR-FRAC
                                          WS-STATUS

      *> Interest payment on remaining balance
               COMPUTE WS-INTEREST-PAYMENT ROUNDED = 
                   WS-REMAINING-PRINCIPAL * LNK-IN-ANNUAL-RATE * WS-YEAR-FRAC

      *> If final period, pay down all remaining principal
               IF WS-NEXT-DATE = LNK-IN-MD-DATE OR WS-FLOW-COUNT = WS-TOTAL-PERIODS
                   MOVE WS-REMAINING-PRINCIPAL TO WS-PRIN-PAYMENT
               END-IF

               COMPUTE WS-PERIOD-TOTAL = WS-PRIN-PAYMENT + WS-INTEREST-PAYMENT
               ADD WS-PERIOD-TOTAL TO LNK-OUT-TOTAL-CASHFLOWS

               SUBTRACT WS-PRIN-PAYMENT FROM WS-REMAINING-PRINCIPAL
               IF WS-REMAINING-PRINCIPAL < 0
                   MOVE 0 TO WS-REMAINING-PRINCIPAL
               END-IF

               MOVE WS-NEXT-DATE TO WS-CURR-DATE
           END-PERFORM

           MOVE WS-FLOW-COUNT TO LNK-OUT-SCHEDULE-COUNT
           GOBACK.
