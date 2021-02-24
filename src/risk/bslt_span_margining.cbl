       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SPAN-MARGINING.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SPAN PORTFOLIO MARGINING        *
      *> Standard Portfolio Analysis of Risk (SPAN) 16-scenario grid,   *
      *> worst-case liquidation loss selection, and margin add-ons.     *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-SPAN-WORKING.
          05 WS-PRICE-RANGE              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VOL-RANGE                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-PORTFOLIO-DELTA          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PORTFOLIO-GAMMA          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PORTFOLIO-VEGA           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WORST-LOSS               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SCENARIO-LOSS            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DELTA-PNL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-GAMMA-PNL                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VEGA-PNL                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-P-SHIFT                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-V-SHIFT                  PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-I                        PIC 9(2)        VALUE 1.

      *> Standard SPAN scenario multipliers: price fraction and vol sign
       01 WS-SCENARIO-PARAMS.
          05 WS-P-MULT OCCURS 16 TIMES   PIC S9(1)V9(4)  COMP-3.
          05 WS-V-MULT OCCURS 16 TIMES   PIC S9(1)V9(4)  COMP-3.

       LINKAGE SECTION.
       01 LNK-SPN-OP                     PIC X(8).
       01 LNK-IN-DELTA                   PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-GAMMA                   PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-VEGA                    PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-UNDERLYING-PRICE        PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-PRICE-SCAN-RANGE        PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-VOL-SCAN-RANGE          PIC S9(3)V9(8)  COMP-3.
       01 LNK-OUT-SPAN-REQUIREMENT       PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-WORST-SCENARIO-ID      PIC 9(2).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-SPN-OP LNK-IN-DELTA
                                LNK-IN-GAMMA LNK-IN-VEGA
                                LNK-IN-UNDERLYING-PRICE
                                LNK-IN-PRICE-SCAN-RANGE
                                LNK-IN-VOL-SCAN-RANGE
                                LNK-OUT-SPAN-REQUIREMENT
                                LNK-OUT-WORST-SCENARIO-ID
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-SPAN-REQUIREMENT
           MOVE 1 TO LNK-OUT-WORST-SCENARIO-ID

           PERFORM 1000-INIT-SCENARIOS
           PERFORM 2000-EVALUATE-GRID

           GOBACK.

       1000-INIT-SCENARIOS.
      *> Multipliers for price shift [-1.0 .. +1.0] and vol shift [-1.0, 0, +1.0]
           MOVE  0.0000 TO WS-P-MULT(1)   MOVE  0.0000 TO WS-V-MULT(1)
           MOVE  0.0000 TO WS-P-MULT(2)   MOVE  1.0000 TO WS-V-MULT(2)
           MOVE  0.0000 TO WS-P-MULT(3)   MOVE -1.0000 TO WS-V-MULT(3)
           MOVE  0.3333 TO WS-P-MULT(4)   MOVE  1.0000 TO WS-V-MULT(4)
           MOVE  0.3333 TO WS-P-MULT(5)   MOVE -1.0000 TO WS-V-MULT(5)
           MOVE -0.3333 TO WS-P-MULT(6)   MOVE  1.0000 TO WS-V-MULT(6)
           MOVE -0.3333 TO WS-P-MULT(7)   MOVE -1.0000 TO WS-V-MULT(7)
           MOVE  0.6667 TO WS-P-MULT(8)   MOVE  1.0000 TO WS-V-MULT(8)
           MOVE  0.6667 TO WS-P-MULT(9)   MOVE -1.0000 TO WS-V-MULT(9)
           MOVE -0.6667 TO WS-P-MULT(10)  MOVE  1.0000 TO WS-V-MULT(10)
           MOVE -0.6667 TO WS-P-MULT(11)  MOVE -1.0000 TO WS-V-MULT(11)
           MOVE  1.0000 TO WS-P-MULT(12)  MOVE  1.0000 TO WS-V-MULT(12)
           MOVE  1.0000 TO WS-P-MULT(13)  MOVE -1.0000 TO WS-V-MULT(13)
           MOVE -1.0000 TO WS-P-MULT(14)  MOVE  1.0000 TO WS-V-MULT(14)
           MOVE -1.0000 TO WS-P-MULT(15)  MOVE -1.0000 TO WS-V-MULT(15)
           MOVE  2.0000 TO WS-P-MULT(16)  MOVE  0.0000 TO WS-V-MULT(16).

       2000-EVALUATE-GRID.
           MOVE 0 TO WS-WORST-LOSS
           MOVE 1 TO LNK-OUT-WORST-SCENARIO-ID

      *> Price Scan Range in currency units
           COMPUTE WS-PRICE-RANGE ROUNDED = 
               LNK-IN-UNDERLYING-PRICE * LNK-IN-PRICE-SCAN-RANGE
           MOVE LNK-IN-VOL-SCAN-RANGE TO WS-VOL-RANGE

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 16
               COMPUTE WS-P-SHIFT ROUNDED = WS-PRICE-RANGE * WS-P-MULT(WS-I)
               COMPUTE WS-V-SHIFT ROUNDED = WS-VOL-RANGE * WS-V-MULT(WS-I)

      *> PnL = Delta*dP + 0.5*Gamma*dP^2 + Vega*dVol
               COMPUTE WS-DELTA-PNL ROUNDED = LNK-IN-DELTA * WS-P-SHIFT
               COMPUTE WS-GAMMA-PNL ROUNDED = 
                   0.50000000 * LNK-IN-GAMMA * (WS-P-SHIFT * WS-P-SHIFT)
               COMPUTE WS-VEGA-PNL ROUNDED = LNK-IN-VEGA * WS-V-SHIFT

               COMPUTE WS-SCENARIO-LOSS ROUNDED = 
                   0 - (WS-DELTA-PNL + WS-GAMMA-PNL + WS-VEGA-PNL)

      *> Scenario 16 extreme move: covered at 35% factor by SPAN rule
               IF WS-I = 16
                   COMPUTE WS-SCENARIO-LOSS ROUNDED = 
                       WS-SCENARIO-LOSS * 0.35000000
               END-IF

               IF WS-SCENARIO-LOSS > WS-WORST-LOSS
                   MOVE WS-SCENARIO-LOSS TO WS-WORST-LOSS
                   MOVE WS-I TO LNK-OUT-WORST-SCENARIO-ID
               END-IF
           END-PERFORM

           IF WS-WORST-LOSS < 0
               MOVE 0 TO WS-WORST-LOSS
           END-IF

           MOVE WS-WORST-LOSS TO LNK-OUT-SPAN-REQUIREMENT.
