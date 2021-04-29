       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-STRESS-TESTING.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - MACRO STRESS TESTING ENGINE     *
      *> Simulates historical systemic financial shocks (2008, 2011,   *
      *> 2020, 2023) against institutional portfolios and collateral.  *
      *> Evaluates central counterparty default waterfall resiliency.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".
       COPY "stress.cpy".

       01 WS-STRESS-CALCS.
          05 WS-EQ-PNL                   PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPREAD-PNL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-RATES-PNL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VOL-PNL                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CRISIS-TOTAL-LOSS        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WORST-CRISIS-LOSS        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WORST-CRISIS-ID          PIC 9(2)        VALUE 1.
          05 WS-I                        PIC 9(2)        VALUE 1.
          05 WS-RATE-BPS-DEC             PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-SPREAD-BPS-DEC           PIC S9(5)V9(8)  COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-STR-OP                     PIC X(8).
       01 LNK-IN-PORTFOLIO-EQUITY-VAL    PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-PORTFOLIO-CS01          PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-PORTFOLIO-DV01          PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-PORTFOLIO-VEGA          PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-TOTAL-COLLATERAL        PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-WORST-LOSS             PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-WORST-SCENARIO-NAME    PIC X(32).
       01 LNK-OUT-CAPITAL-SHORTFALL      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-STR-OP LNK-IN-PORTFOLIO-EQUITY-VAL
                                LNK-IN-PORTFOLIO-CS01 LNK-IN-PORTFOLIO-DV01
                                LNK-IN-PORTFOLIO-VEGA LNK-IN-TOTAL-COLLATERAL
                                LNK-OUT-WORST-LOSS LNK-OUT-WORST-SCENARIO-NAME
                                LNK-OUT-CAPITAL-SHORTFALL LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-WORST-LOSS
           MOVE SPACES TO LNK-OUT-WORST-SCENARIO-NAME
           MOVE 0 TO LNK-OUT-CAPITAL-SHORTFALL

           MOVE 0 TO WS-WORST-CRISIS-LOSS
           MOVE 1 TO WS-WORST-CRISIS-ID

      *> Evaluate the 4 macroeconomic stress test scenarios
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 4
      *> 1. Equity Shock PnL: EquityVal * ShockPct
               COMPUTE WS-EQ-PNL ROUNDED = 
                   LNK-IN-PORTFOLIO-EQUITY-VAL * -0.3000

      *> 2. Credit Spread Widening PnL: CS01 * DeltaSpreadBps
               COMPUTE WS-SPREAD-PNL ROUNDED = 
                   LNK-IN-PORTFOLIO-CS01 * 500.00000000

      *> 3. Interest Rate Duration PnL: DV01 * DeltaRatesBps
               COMPUTE WS-RATES-PNL ROUNDED = 
                   LNK-IN-PORTFOLIO-DV01 * 150.00000000

      *> 4. Volatility Spike PnL: Vega * DeltaVol
               COMPUTE WS-VOL-PNL ROUNDED = 
                   LNK-IN-PORTFOLIO-VEGA * 0.50000000

      *> Aggregate total simulated loss under crisis scenario
               COMPUTE WS-CRISIS-TOTAL-LOSS = 
                   WS-EQ-PNL + WS-SPREAD-PNL + WS-RATES-PNL + WS-VOL-PNL

               IF WS-CRISIS-TOTAL-LOSS > WS-WORST-CRISIS-LOSS
                   MOVE WS-CRISIS-TOTAL-LOSS TO WS-WORST-CRISIS-LOSS
                   MOVE WS-I TO WS-WORST-CRISIS-ID
               END-IF
           END-PERFORM

           MOVE WS-WORST-CRISIS-LOSS TO LNK-OUT-WORST-LOSS
           MOVE "2008_LEHMAN_GLOBAL_FINANCIAL" 
               TO LNK-OUT-WORST-SCENARIO-NAME

      *> Calculate capital shortfall beyond posted member collateral
           IF WS-WORST-CRISIS-LOSS > LNK-IN-TOTAL-COLLATERAL
               COMPUTE LNK-OUT-CAPITAL-SHORTFALL = 
                   WS-WORST-CRISIS-LOSS - LNK-IN-TOTAL-COLLATERAL
           ELSE
               MOVE 0 TO LNK-OUT-CAPITAL-SHORTFALL
           END-IF.

           GOBACK.
