       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-WATERFALL.
      *>================================================================*
      *> BASALT TEST SUITE - DEFAULT WATERFALL & MARGIN CALL DISPATCH   *
      *> Validation of CPMI-IOSCO multi-tranche loss absorption and     *
      *> automated liquidity locks on member settlement accounts.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-WF-TEST-VARS.
          05 WS-DEF-BIC                  PIC X(11) VALUE "TESTDEF1XXX".
          05 WS-LOSS-OBLIGATION          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-POSTED-MARGIN            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-POSTED-DEF-FUND          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MARGIN-ABSORBED          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DEF-FUND-ABSORBED        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CCP-SITG-ABSORBED        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MUTUAL-FUND-ABSORBED     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ASSESSMENT-CALLED        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VMGH-HAIRCUT             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FINAL-DEFICIT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TRANCHE-HIT              PIC 9(2)  VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: Loss fully contained within defaulter's initial margin
      *> Obligation: $25,000,000.00; Posted Margin: $40,000,000.00
      *> Expected: Tranche 1 hit, 0 deficit, $25M margin absorbed
      *>----------------------------------------------------------------*
           MOVE 25000000.00000000 TO WS-LOSS-OBLIGATION
           MOVE 40000000.00000000 TO WS-POSTED-MARGIN
           MOVE 10000000.00000000 TO WS-POSTED-DEF-FUND

           CALL "BSLT-LIQUIDITY-WATERFALL" USING "RESOLVE "
                                                 WS-DEF-BIC
                                                 WS-LOSS-OBLIGATION
                                                 WS-POSTED-MARGIN
                                                 WS-POSTED-DEF-FUND
                                                 WS-MARGIN-ABSORBED
                                                 WS-DEF-FUND-ABSORBED
                                                 WS-CCP-SITG-ABSORBED
                                                 WS-MUTUAL-FUND-ABSORBED
                                                 WS-ASSESSMENT-CALLED
                                                 WS-VMGH-HAIRCUT
                                                 WS-FINAL-DEFICIT
                                                 WS-TRANCHE-HIT
                                                 WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-TRANCHE-HIT = 1 
              AND WS-MARGIN-ABSORBED = 25000000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Tranche 1 margin containment failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Loss breaches margin, absorbed by defaulter default fund
      *> Obligation: $50,000,000.00; Margin: $40M; Def Fund: $20M
      *> Expected: Tranche 2 hit, $40M margin + $10M def fund absorbed
      *>----------------------------------------------------------------*
           MOVE 50000000.00000000 TO WS-LOSS-OBLIGATION
           MOVE 40000000.00000000 TO WS-POSTED-MARGIN
           MOVE 20000000.00000000 TO WS-POSTED-DEF-FUND

           CALL "BSLT-LIQUIDITY-WATERFALL" USING "RESOLVE "
                                                 WS-DEF-BIC
                                                 WS-LOSS-OBLIGATION
                                                 WS-POSTED-MARGIN
                                                 WS-POSTED-DEF-FUND
                                                 WS-MARGIN-ABSORBED
                                                 WS-DEF-FUND-ABSORBED
                                                 WS-CCP-SITG-ABSORBED
                                                 WS-MUTUAL-FUND-ABSORBED
                                                 WS-ASSESSMENT-CALLED
                                                 WS-VMGH-HAIRCUT
                                                 WS-FINAL-DEFICIT
                                                 WS-TRANCHE-HIT
                                                 WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-TRANCHE-HIT = 2 
              AND WS-MARGIN-ABSORBED = 40000000.00000000
              AND WS-DEF-FUND-ABSORBED = 10000000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Tranche 2 default fund absorption failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Extreme shock loss reaching CCP Skin-in-the-game
      *> Obligation: $120,000,000.00; Margin: $40M; Def Fund: $20M
      *> Remaining loss: $60M absorbed by CCP SITG (Tranche 3)
      *>----------------------------------------------------------------*
           MOVE 120000000.00000000 TO WS-LOSS-OBLIGATION
           MOVE 40000000.00000000  TO WS-POSTED-MARGIN
           MOVE 20000000.00000000  TO WS-POSTED-DEF-FUND

           CALL "BSLT-LIQUIDITY-WATERFALL" USING "RESOLVE "
                                                 WS-DEF-BIC
                                                 WS-LOSS-OBLIGATION
                                                 WS-POSTED-MARGIN
                                                 WS-POSTED-DEF-FUND
                                                 WS-MARGIN-ABSORBED
                                                 WS-DEF-FUND-ABSORBED
                                                 WS-CCP-SITG-ABSORBED
                                                 WS-MUTUAL-FUND-ABSORBED
                                                 WS-ASSESSMENT-CALLED
                                                 WS-VMGH-HAIRCUT
                                                 WS-FINAL-DEFICIT
                                                 WS-TRANCHE-HIT
                                                 WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-TRANCHE-HIT = 3
              AND WS-CCP-SITG-ABSORBED = 60000000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Tranche 3 CCP SITG absorption failed"
           END-IF

           GOBACK.
