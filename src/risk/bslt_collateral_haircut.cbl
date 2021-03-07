       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-COLLATERAL-HAIRCUT.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - COLLATERAL HAIRCUT ENGINE       *
      *> Tiered asset haircut evaluation, effective collateral value   *
      *> calculation, and automated margin deficit call trigger.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-HAIRCUT-TABLE.
          05 WS-HC-RATES OCCURS 7 TIMES PIC S9(1)V9(4) COMP-3.

       01 WS-CALC-VARS.
          05 WS-TOTAL-EFFECTIVE          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ASSET-EFFECTIVE          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-HAIRCUT-FACTOR           PIC S9(1)V9(8)  COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.
          05 WS-TYPE                     PIC 9(2)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-HCT-OP                     PIC X(8).
       01 LNK-IN-COLLATERAL-COUNT        PIC 9(4).
       01 LNK-IN-COLLATERAL-LIST.
          05 LNK-C-ASSET OCCURS 32 TIMES.
             10 LNK-C-TYPE               PIC 9(2).
             10 LNK-C-NOMINAL-VAL        PIC S9(18)V9(8) COMP-3.
             10 LNK-C-CCY                PIC X(3).
       01 LNK-IN-REQUIRED-MARGIN         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-EFFECTIVE-COLLATERAL   PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-SURPLUS-DEFICIT        PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MARGIN-CALL-FLAG       PIC 9(1).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-HCT-OP LNK-IN-COLLATERAL-COUNT
                                LNK-IN-COLLATERAL-LIST
                                LNK-IN-REQUIRED-MARGIN
                                LNK-OUT-EFFECTIVE-COLLATERAL
                                LNK-OUT-SURPLUS-DEFICIT
                                LNK-OUT-MARGIN-CALL-FLAG
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-EFFECTIVE-COLLATERAL
           MOVE 0 TO LNK-OUT-SURPLUS-DEFICIT
           MOVE 0 TO LNK-OUT-MARGIN-CALL-FLAG

           PERFORM 1000-INIT-HAIRCUTS
           PERFORM 2000-EVALUATE-COLLATERAL

           GOBACK.

       1000-INIT-HAIRCUTS.
      *> Haircut percentages: Cash 0%, Sovereign T1 2%, T2 5%,
      *> Corp AAA 8%, Corp BBB 15%, Eq Large 20%, Eq MidSmall 35%
           MOVE 0.0000 TO WS-HC-RATES(1)
           MOVE 0.0200 TO WS-HC-RATES(2)
           MOVE 0.0500 TO WS-HC-RATES(3)
           MOVE 0.0800 TO WS-HC-RATES(4)
           MOVE 0.1500 TO WS-HC-RATES(5)
           MOVE 0.2000 TO WS-HC-RATES(6)
           MOVE 0.3500 TO WS-HC-RATES(7).

       2000-EVALUATE-COLLATERAL.
           MOVE 0 TO WS-TOTAL-EFFECTIVE

           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-COLLATERAL-COUNT
               MOVE LNK-C-TYPE(WS-I) TO WS-TYPE
               IF WS-TYPE < 1 OR WS-TYPE > 7
                   MOVE 7 TO WS-TYPE
               END-IF

               COMPUTE WS-HAIRCUT-FACTOR = 1.00000000 - WS-HC-RATES(WS-TYPE)
               COMPUTE WS-ASSET-EFFECTIVE ROUNDED = 
                   LNK-C-NOMINAL-VAL(WS-I) * WS-HAIRCUT-FACTOR
               ADD WS-ASSET-EFFECTIVE TO WS-TOTAL-EFFECTIVE
           END-PERFORM

           MOVE WS-TOTAL-EFFECTIVE TO LNK-OUT-EFFECTIVE-COLLATERAL

      *> Surplus/Deficit = Effective Collateral - Required Margin
           COMPUTE LNK-OUT-SURPLUS-DEFICIT = 
               WS-TOTAL-EFFECTIVE - LNK-IN-REQUIRED-MARGIN

           IF LNK-OUT-SURPLUS-DEFICIT < 0
               MOVE 1 TO LNK-OUT-MARGIN-CALL-FLAG
           ELSE
               MOVE 0 TO LNK-OUT-MARGIN-CALL-FLAG
           END-IF.
