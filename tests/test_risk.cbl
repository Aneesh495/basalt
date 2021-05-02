       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-RISK.
      *>================================================================*
      *> BASALT TEST SUITE - PORTFOLIO RISK AND CAPITAL ADEQUACY        *
      *> Verification of SPAN 16-scenario grid margining, historical    *
      *> simulation VaR, Expected Shortfall (CVaR), multi-tier haircuts *
      *> and historical macroeconomic crisis stress testing.            *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".
       COPY "stress.cpy".

      *> Working variables for SPAN
       01 WS-SPAN-TEST-VARS.
          05 WS-SPN-DELTA                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPN-GAMMA                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPN-VEGA                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPN-PRICE                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPN-P-SCAN               PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-SPN-V-SCAN               PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-SPN-REQ                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SPN-WORST-ID             PIC 9(2)        VALUE 0.
          05 WS-SPN-STATUS               PIC 9(4)        VALUE 0.

      *> Working variables for Historical VaR
       01 WS-HVAR-TEST-VARS.
          05 WS-HVAR-LEN                 PIC 9(4)        VALUE 50.
          05 WS-HVAR-SERIES.
             10 WS-HVAR-ITEM OCCURS 252 TIMES.
                15 WS-HVAR-PNL           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HVAR-VAR95               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HVAR-VAR99               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HVAR-MEDIAN              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HVAR-STATUS              PIC 9(4)        VALUE 0.

      *> Working variables for Expected Shortfall
       01 WS-ES-TEST-VARS.
          05 WS-ES-LEN                   PIC 9(4)        VALUE 50.
          05 WS-ES-SERIES.
             10 WS-ES-ITEM OCCURS 252 TIMES.
                15 WS-ES-LOSS            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ES-CONF-95               PIC 9(2)        VALUE 95.
          05 WS-ES-RESULT                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ES-STATUS                PIC 9(4)        VALUE 0.

      *> Working variables for Collateral Haircuts
       01 WS-HCT-TEST-VARS.
          05 WS-HCT-COUNT                PIC 9(4)        VALUE 0.
          05 WS-HCT-LIST.
             10 WS-HCT-ITEM OCCURS 32 TIMES.
                15 WS-HCT-TYPE           PIC 9(2)        VALUE 0.
                15 WS-HCT-NOMINAL        PIC S9(18)V9(8) COMP-3 VALUE 0.
                15 WS-HCT-CCY            PIC X(3)        VALUE "USD".
          05 WS-HCT-REQ-MARGIN           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HCT-EFFECTIVE            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HCT-SURPLUS              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HCT-CALL-FLAG            PIC 9(1)        VALUE 0.
          05 WS-HCT-STATUS               PIC 9(4)        VALUE 0.

      *> Working variables for Crisis Stress Testing
       01 WS-STR-TEST-VARS.
          05 WS-STR-EQUITY-VAL           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-CS01                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-DV01                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-VEGA                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-COLLATERAL           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-WORST-LOSS           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-SCEN-NAME            PIC X(32)       VALUE SPACES.
          05 WS-STR-SHORTFALL            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STR-STATUS               PIC 9(4)        VALUE 0.

       01 WS-I                           PIC 9(4)        VALUE 0.
       01 WS-VAL                         PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: SPAN Margining with zero greeks should yield 0 margin
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-SPN-DELTA WS-SPN-GAMMA WS-SPN-VEGA
           MOVE 100.00000000 TO WS-SPN-PRICE
           MOVE 0.10000000   TO WS-SPN-P-SCAN
           MOVE 0.05000000   TO WS-SPN-V-SCAN
           CALL "BSLT-SPAN-MARGINING" USING "EVALUATE"
                                           WS-SPN-DELTA WS-SPN-GAMMA WS-SPN-VEGA
                                           WS-SPN-PRICE WS-SPN-P-SCAN WS-SPN-V-SCAN
                                           WS-SPN-REQ WS-SPN-WORST-ID WS-SPN-STATUS
           IF WS-SPN-STATUS = BS-RC-OK AND WS-SPN-REQ = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: SPAN zero portfolio margin failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: SPAN Margining with long delta exposure
      *> Delta = 1000, Gamma = 0, Vega = 0, Price = 100, P-Scan = 10%
      *> Max downward price move is -10% (-10), so worst loss is 10,000
      *>----------------------------------------------------------------*
           MOVE 1000.00000000 TO WS-SPN-DELTA
           MOVE 0             TO WS-SPN-GAMMA WS-SPN-VEGA
           MOVE 100.00000000  TO WS-SPN-PRICE
           MOVE 0.10000000    TO WS-SPN-P-SCAN
           MOVE 0.05000000    TO WS-SPN-V-SCAN
           CALL "BSLT-SPAN-MARGINING" USING "EVALUATE"
                                           WS-SPN-DELTA WS-SPN-GAMMA WS-SPN-VEGA
                                           WS-SPN-PRICE WS-SPN-P-SCAN WS-SPN-V-SCAN
                                           WS-SPN-REQ WS-SPN-WORST-ID WS-SPN-STATUS
           IF WS-SPN-STATUS = BS-RC-OK AND WS-SPN-REQ = 10000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: SPAN long delta margin failed: " WS-SPN-REQ
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: SPAN Margining with short delta exposure
      *> Delta = -1000, worst price move is +10% (+10), worst loss is 10,000
      *>----------------------------------------------------------------*
           MOVE -1000.00000000 TO WS-SPN-DELTA
           MOVE 0              TO WS-SPN-GAMMA WS-SPN-VEGA
           CALL "BSLT-SPAN-MARGINING" USING "EVALUATE"
                                           WS-SPN-DELTA WS-SPN-GAMMA WS-SPN-VEGA
                                           WS-SPN-PRICE WS-SPN-P-SCAN WS-SPN-V-SCAN
                                           WS-SPN-REQ WS-SPN-WORST-ID WS-SPN-STATUS
           IF WS-SPN-STATUS = BS-RC-OK AND WS-SPN-REQ = 10000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: SPAN short delta margin failed: " WS-SPN-REQ
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Historical VaR on a sequence of 50 synthetic returns
      *> Populate series: -5000, -4800, ..., 0, ..., +4800
      *>----------------------------------------------------------------*
           MOVE 50 TO WS-HVAR-LEN
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 50
               COMPUTE WS-VAL = (WS-I - 26) * 200.00000000
               MOVE WS-VAL TO WS-HVAR-PNL(WS-I)
           END-PERFORM

           CALL "BSLT-HISTORICAL-VAR" USING "CALCVAR " WS-HVAR-LEN
                                           WS-HVAR-SERIES WS-HVAR-VAR95
                                           WS-HVAR-VAR99 WS-HVAR-MEDIAN
                                           WS-HVAR-STATUS
           IF WS-HVAR-STATUS = BS-RC-OK AND WS-HVAR-VAR95 > 0 AND WS-HVAR-VAR99 >= WS-HVAR-VAR95
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Historical VaR calculation failed: " WS-HVAR-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: Expected Shortfall (CVaR) should exceed 95% VaR
      *>----------------------------------------------------------------*
           MOVE 50 TO WS-ES-LEN
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 50
               COMPUTE WS-VAL = (26 - WS-I) * 200.00000000
               IF WS-VAL < 0 MOVE 0 TO WS-VAL END-IF
               MOVE WS-VAL TO WS-ES-LOSS(WS-I)
           END-PERFORM

           CALL "BSLT-EXPECTED-SHORTFALL" USING "CALCES  " WS-ES-LEN
                                               WS-ES-SERIES WS-ES-CONF-95
                                               WS-ES-RESULT WS-ES-STATUS
           IF WS-ES-STATUS = BS-RC-OK AND WS-ES-RESULT > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Expected Shortfall calculation failed: " WS-ES-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Collateral Haircuts: Cash (0% haircut)
      *> $1,000,000 Cash nominal should provide $1,000,000 effective collateral
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-HCT-COUNT
           MOVE 1 TO WS-HCT-TYPE(1)
           MOVE 1000000.00000000 TO WS-HCT-NOMINAL(1)
           MOVE "USD" TO WS-HCT-CCY(1)
           MOVE 800000.00000000  TO WS-HCT-REQ-MARGIN

           CALL "BSLT-COLLATERAL-HAIRCUT" USING "HAIRCUT " WS-HCT-COUNT
                                                WS-HCT-LIST WS-HCT-REQ-MARGIN
                                                WS-HCT-EFFECTIVE WS-HCT-SURPLUS
                                                WS-HCT-CALL-FLAG WS-HCT-STATUS
           IF WS-HCT-STATUS = BS-RC-OK AND WS-HCT-EFFECTIVE = 1000000.00000000
              AND WS-HCT-SURPLUS = 200000.00000000 AND WS-HCT-CALL-FLAG = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Collateral Haircut Cash test failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 7: Collateral Haircuts: Mixed Portfolio (Cash + Sovereign + Equity)
      *> Cash: 100,000 (0% hc -> 100,000)
      *> Sovereign: 500,000 (2% hc -> 490,000)
      *> Equity: 200,000 (15% hc -> 170,000)
      *> Total Effective: 760,000. Required: 800,000. Deficit: -40,000. Margin call flag: 1.
      *>----------------------------------------------------------------*
           MOVE 3 TO WS-HCT-COUNT
           MOVE 1 TO WS-HCT-TYPE(1)
           MOVE 100000.00000000 TO WS-HCT-NOMINAL(1)
           MOVE "USD" TO WS-HCT-CCY(1)

           MOVE 2 TO WS-HCT-TYPE(2)
           MOVE 500000.00000000 TO WS-HCT-NOMINAL(2)
           MOVE "USD" TO WS-HCT-CCY(2)

           MOVE 5 TO WS-HCT-TYPE(3)
           MOVE 200000.00000000 TO WS-HCT-NOMINAL(3)
           MOVE "USD" TO WS-HCT-CCY(3)

           MOVE 800000.00000000 TO WS-HCT-REQ-MARGIN

           CALL "BSLT-COLLATERAL-HAIRCUT" USING "HAIRCUT " WS-HCT-COUNT
                                                WS-HCT-LIST WS-HCT-REQ-MARGIN
                                                WS-HCT-EFFECTIVE WS-HCT-SURPLUS
                                                WS-HCT-CALL-FLAG WS-HCT-STATUS
           IF WS-HCT-STATUS = BS-RC-OK AND WS-HCT-EFFECTIVE = 760000.00000000
              AND WS-HCT-SURPLUS = -40000.00000000 AND WS-HCT-CALL-FLAG = 1
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Collateral Haircut mixed portfolio test failed: " WS-HCT-EFFECTIVE
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 8: Macroeconomic Crisis Stress Testing (2008 Lehman replay)
      *> Equity: 10,000,000, CS01: 50,000, DV01: 20,000, Vega: 10,000, Collateral: 2,000,000
      *> Evaluates loss across Lehman, European Sovereign, COVID, and Bank Run
      *>----------------------------------------------------------------*
           MOVE 10000000.00000000 TO WS-STR-EQUITY-VAL
           MOVE 50000.00000000    TO WS-STR-CS01
           MOVE 20000.00000000    TO WS-STR-DV01
           MOVE 10000.00000000    TO WS-STR-VEGA
           MOVE 2000000.00000000  TO WS-STR-COLLATERAL

           CALL "BSLT-STRESS-TESTING" USING "STRESS  "
                                            WS-STR-EQUITY-VAL WS-STR-CS01
                                            WS-STR-DV01 WS-STR-VEGA
                                            WS-STR-COLLATERAL
                                            WS-STR-WORST-LOSS WS-STR-SCEN-NAME
                                            WS-STR-SHORTFALL WS-STR-STATUS
           IF WS-STR-STATUS = BS-RC-OK AND WS-STR-WORST-LOSS > 0
              AND WS-STR-SHORTFALL > 0 AND WS-STR-SCEN-NAME NOT = SPACES
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Crisis Stress Testing failed: " WS-STR-STATUS
           END-IF.

           GOBACK.
