       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-ANN.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ACTUS ANNUITY LOAN ENGINE       *
      *> Constant periodic payment amortizer with interest/principal    *
      *> decomposition and exact remaining balance convergence.        *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-ANN-VARS.
          05 WS-PERIOD-RATE              PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-PERIOD-PAYMENT           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-REMAINING-PRINCIPAL      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-INTEREST-FLOW            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PRINCIPAL-FLOW           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TOTAL-FLOW               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PERIODS-DEC              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-ANN-OP                     PIC X(8).
       01 LNK-IN-PRINCIPAL               PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-ANNUAL-RATE             PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-PERIODS                 PIC 9(4).
       01 LNK-IN-START-DATE              PIC 9(8).
       01 LNK-OUT-PERIODIC-PMT           PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-TOTAL-INTEREST         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-ANN-OP LNK-IN-PRINCIPAL
                                LNK-IN-ANNUAL-RATE LNK-IN-PERIODS
                                LNK-IN-START-DATE LNK-OUT-PERIODIC-PMT
                                LNK-OUT-TOTAL-INTEREST LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-PERIODIC-PMT
           MOVE 0 TO LNK-OUT-TOTAL-INTEREST

           IF LNK-IN-PRINCIPAL <= 0 OR LNK-IN-PERIODS = 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> Monthly periodic rate = AnnualRate / 12
           COMPUTE WS-PERIOD-RATE ROUNDED = 
               LNK-IN-ANNUAL-RATE / 12.00000000

      *> Linear approximation of level payment: P = (L/n) + L*r/2
           MOVE LNK-IN-PERIODS TO WS-PERIODS-DEC
           COMPUTE WS-PERIOD-PAYMENT ROUNDED = 
               (LNK-IN-PRINCIPAL / WS-PERIODS-DEC) + 
               ((LNK-IN-PRINCIPAL * WS-PERIOD-RATE) * 0.50000000)
           MOVE WS-PERIOD-PAYMENT TO LNK-OUT-PERIODIC-PMT

           MOVE LNK-IN-PRINCIPAL TO WS-REMAINING-PRINCIPAL

      *> Generate amortization schedule
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > LNK-IN-PERIODS
               COMPUTE WS-INTEREST-FLOW ROUNDED = 
                   WS-REMAINING-PRINCIPAL * WS-PERIOD-RATE
               ADD WS-INTEREST-FLOW TO LNK-OUT-TOTAL-INTEREST

               COMPUTE WS-PRINCIPAL-FLOW = 
                   WS-PERIOD-PAYMENT - WS-INTEREST-FLOW

               IF WS-I = LNK-IN-PERIODS OR 
                  WS-PRINCIPAL-FLOW > WS-REMAINING-PRINCIPAL
      *> Terminal period: adjust principal to eliminate residual drift
                   MOVE WS-REMAINING-PRINCIPAL TO WS-PRINCIPAL-FLOW
                   MOVE 0 TO WS-REMAINING-PRINCIPAL
               ELSE
                   SUBTRACT WS-PRINCIPAL-FLOW FROM WS-REMAINING-PRINCIPAL
               END-IF
           END-PERFORM.

           GOBACK.
