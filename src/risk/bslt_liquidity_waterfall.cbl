       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-LIQUIDITY-WATERFALL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - CPMI-IOSCO DEFAULT WATERFALL     *
      *> Multi-tranche loss mutualization and capital absorption engine:*
      *> 1. Defaulter Initial Margin and Pledged Collateral             *
      *> 2. Defaulter Default Fund (Guaranty Fund) Contribution         *
      *> 3. CCP Dedicated Skin-in-the-Game (SITG) First Tranche         *
      *> 4. Non-Defaulting Clearing Members Mutualized Default Fund     *
      *> 5. Secondary CCP Equity Tranche (SITG Tranche 2)               *
      *> 6. Cash Assessment Calls on Surviving Clearing Participants    *
      *> 7. Variation Margin Gains Haircutting (VMGH) Deficit Resolution*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-WATERFALL-STATE.
          05 WS-DEF-INITIAL-MARGIN       PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DEF-GUARANTY-FUND        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CCP-SITG-1               PIC S9(18)V9(8) COMP-3 VALUE 100000000.00000000.
          05 WS-MUTUALIZED-FUND-TOTAL    PIC S9(18)V9(8) COMP-3 VALUE 500000000.00000000.
          05 WS-CCP-SITG-2               PIC S9(18)V9(8) COMP-3 VALUE 50000000.00000000.
          05 WS-MAX-ASSESSMENT-CAP       PIC S9(18)V9(8) COMP-3 VALUE 1000000000.00000000.
          05 WS-CUMULATIVE-ABSORBED      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-UNCOVERED-LOSS           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CURRENT-TRANCHE          PIC 9(2)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-WF-OP                      PIC X(8).
       01 LNK-IN-MEMBER-BIC              PIC X(11).
       01 LNK-IN-TOTAL-LOSS-OBLIGATION   PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-POSTED-MARGIN           PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-POSTED-DEF-FUND         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MARGIN-ABSORBED        PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-DEF-FUND-ABSORBED      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CCP-SITG-ABSORBED      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MUTUAL-FUND-ABSORBED   PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-ASSESSMENT-CALLED      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-VMGH-HAIRCUT-REQUIRED  PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-FINAL-DEFICIT          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-HIGHEST-TRANCHE-HIT    PIC 9(2).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-WF-OP LNK-IN-MEMBER-BIC
                                LNK-IN-TOTAL-LOSS-OBLIGATION
                                LNK-IN-POSTED-MARGIN
                                LNK-IN-POSTED-DEF-FUND
                                LNK-OUT-MARGIN-ABSORBED
                                LNK-OUT-DEF-FUND-ABSORBED
                                LNK-OUT-CCP-SITG-ABSORBED
                                LNK-OUT-MUTUAL-FUND-ABSORBED
                                LNK-OUT-ASSESSMENT-CALLED
                                LNK-OUT-VMGH-HAIRCUT-REQUIRED
                                LNK-OUT-FINAL-DEFICIT
                                LNK-OUT-HIGHEST-TRANCHE-HIT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-MARGIN-ABSORBED
           MOVE 0 TO LNK-OUT-DEF-FUND-ABSORBED
           MOVE 0 TO LNK-OUT-CCP-SITG-ABSORBED
           MOVE 0 TO LNK-OUT-MUTUAL-FUND-ABSORBED
           MOVE 0 TO LNK-OUT-ASSESSMENT-CALLED
           MOVE 0 TO LNK-OUT-VMGH-HAIRCUT-REQUIRED
           MOVE 0 TO LNK-OUT-FINAL-DEFICIT
           MOVE 0 TO LNK-OUT-HIGHEST-TRANCHE-HIT

           IF LNK-IN-TOTAL-LOSS-OBLIGATION <= 0
               GOBACK
           END-IF

           MOVE LNK-IN-TOTAL-LOSS-OBLIGATION TO WS-UNCOVERED-LOSS

      *> TRANCHE 1: Defaulter Margin
           MOVE 1 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= LNK-IN-POSTED-MARGIN
               MOVE WS-UNCOVERED-LOSS TO LNK-OUT-MARGIN-ABSORBED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               MOVE LNK-IN-POSTED-MARGIN TO LNK-OUT-MARGIN-ABSORBED
               SUBTRACT LNK-IN-POSTED-MARGIN FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 2: Defaulter Default Fund
           MOVE 2 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= LNK-IN-POSTED-DEF-FUND
               MOVE WS-UNCOVERED-LOSS TO LNK-OUT-DEF-FUND-ABSORBED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               MOVE LNK-IN-POSTED-DEF-FUND TO LNK-OUT-DEF-FUND-ABSORBED
               SUBTRACT LNK-IN-POSTED-DEF-FUND FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 3: CCP Skin-in-the-game Tranche 1
           MOVE 3 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= WS-CCP-SITG-1
               MOVE WS-UNCOVERED-LOSS TO LNK-OUT-CCP-SITG-ABSORBED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               MOVE WS-CCP-SITG-1 TO LNK-OUT-CCP-SITG-ABSORBED
               SUBTRACT WS-CCP-SITG-1 FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 4: Mutualized Default Fund Contributions of Surviving Members
           MOVE 4 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= WS-MUTUALIZED-FUND-TOTAL
               MOVE WS-UNCOVERED-LOSS TO LNK-OUT-MUTUAL-FUND-ABSORBED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               MOVE WS-MUTUALIZED-FUND-TOTAL TO LNK-OUT-MUTUAL-FUND-ABSORBED
               SUBTRACT WS-MUTUALIZED-FUND-TOTAL FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 5: CCP Skin-in-the-game Tranche 2
           MOVE 5 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= WS-CCP-SITG-2
               ADD WS-UNCOVERED-LOSS TO LNK-OUT-CCP-SITG-ABSORBED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               ADD WS-CCP-SITG-2 TO LNK-OUT-CCP-SITG-ABSORBED
               SUBTRACT WS-CCP-SITG-2 FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 6: Cash Assessment Calls on Non-Defaulting Clearing Members
           MOVE 6 TO WS-CURRENT-TRANCHE
           IF WS-UNCOVERED-LOSS <= WS-MAX-ASSESSMENT-CAP
               MOVE WS-UNCOVERED-LOSS TO LNK-OUT-ASSESSMENT-CALLED
               MOVE 0 TO WS-UNCOVERED-LOSS
               MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
               GOBACK
           ELSE
               MOVE WS-MAX-ASSESSMENT-CAP TO LNK-OUT-ASSESSMENT-CALLED
               SUBTRACT WS-MAX-ASSESSMENT-CAP FROM WS-UNCOVERED-LOSS
           END-IF

      *> TRANCHE 7: Variation Margin Gains Haircutting (VMGH)
           MOVE 7 TO WS-CURRENT-TRANCHE
           MOVE WS-UNCOVERED-LOSS TO LNK-OUT-VMGH-HAIRCUT-REQUIRED
           MOVE WS-CURRENT-TRANCHE TO LNK-OUT-HIGHEST-TRANCHE-HIT
           MOVE 0 TO WS-UNCOVERED-LOSS

           GOBACK.
