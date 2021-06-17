       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-FXSWAP.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FX SWAP CONTRACT LIFECYCLE       *
      *> Foreign Exchange Swap (FXSWAP): Near-leg spot settlement and   *
      *> far-leg forward settlement with interest rate parity points.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-FXS-VARS.
          05 WS-NEAR-QUOTE-AMT           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FAR-QUOTE-AMT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-NET-QUOTE-DIFF           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FWD-POINTS               PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-DAYS                     PIC 9(6)        VALUE 0.
          05 WS-YEAR-FRAC                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-STATUS                   PIC 9(4)        VALUE 0.
          05 WS-RATE-DIFF                PIC S9(3)V9(8)  COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-FXS-OP                     PIC X(8).
       01 LNK-IN-BASE-CCY                PIC X(3).
       01 LNK-IN-QUOTE-CCY               PIC X(3).
       01 LNK-IN-BASE-NOTIONAL           PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-SPOT-RATE               PIC S9(9)V9(8)  COMP-3.
       01 LNK-IN-FAR-RATE                PIC S9(9)V9(8)  COMP-3.
       01 LNK-IN-NEAR-DATE               PIC 9(8).
       01 LNK-IN-FAR-DATE                PIC 9(8).
       01 LNK-OUT-NEAR-QUOTE-AMT         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-FAR-QUOTE-AMT          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-NET-COST               PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-FXS-OP LNK-IN-BASE-CCY
                                LNK-IN-QUOTE-CCY LNK-IN-BASE-NOTIONAL
                                LNK-IN-SPOT-RATE LNK-IN-FAR-RATE
                                LNK-IN-NEAR-DATE LNK-IN-FAR-DATE
                                LNK-OUT-NEAR-QUOTE-AMT
                                LNK-OUT-FAR-QUOTE-AMT
                                LNK-OUT-NET-COST
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-NEAR-QUOTE-AMT
           MOVE 0 TO LNK-OUT-FAR-QUOTE-AMT
           MOVE 0 TO LNK-OUT-NET-COST

           IF LNK-IN-BASE-NOTIONAL <= 0 OR LNK-IN-SPOT-RATE <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF LNK-IN-FAR-DATE <= LNK-IN-NEAR-DATE
               MOVE BS-RC-INVALID-STATE TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> Near leg settlement amount in quote currency
           COMPUTE WS-NEAR-QUOTE-AMT ROUNDED = 
               LNK-IN-BASE-NOTIONAL * LNK-IN-SPOT-RATE

      *> Far leg settlement amount in quote currency
           IF LNK-IN-FAR-RATE > 0
               COMPUTE WS-FAR-QUOTE-AMT ROUNDED = 
                   LNK-IN-BASE-NOTIONAL * LNK-IN-FAR-RATE
           ELSE
      *> Approximate forward rate via ACT/360 daycount with base spread
               CALL "BSLT-DAYCOUNT" USING 3
                                          LNK-IN-NEAR-DATE
                                          LNK-IN-FAR-DATE
                                          WS-DAYS
                                          WS-YEAR-FRAC
                                          WS-STATUS
               COMPUTE WS-RATE-DIFF = 0.01500000 * WS-YEAR-FRAC
               COMPUTE WS-FAR-QUOTE-AMT ROUNDED = 
                   LNK-IN-BASE-NOTIONAL * (LNK-IN-SPOT-RATE * (1.00000000 + WS-RATE-DIFF))
           END-IF

           COMPUTE WS-NET-QUOTE-DIFF = WS-FAR-QUOTE-AMT - WS-NEAR-QUOTE-AMT

           MOVE WS-NEAR-QUOTE-AMT TO LNK-OUT-NEAR-QUOTE-AMT
           MOVE WS-FAR-QUOTE-AMT  TO LNK-OUT-FAR-QUOTE-AMT
           MOVE WS-NET-QUOTE-DIFF TO LNK-OUT-NET-COST

           GOBACK.
