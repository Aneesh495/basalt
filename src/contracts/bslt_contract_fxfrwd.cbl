       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-FXFRWD.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FX FORWARD CONTRACT ENGINE      *
      *> Covered interest parity forward pricing, mark-to-market       *
      *> valuation, and currency delivery settlement calculations.     *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-FX-VARS.
          05 WS-THEO-FORWARD-RATE        PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-BASE-GROWTH              PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-QUOTE-GROWTH             PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-QUOTE-PAYMENT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MTM-VALUATION            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-RATE-DIFF                PIC S9(5)V9(8)  COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-FX-OP                      PIC X(8).
       01 LNK-IN-BASE-NOTIONAL           PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-AGREED-RATE             PIC S9(5)V9(8)  COMP-3.
       01 LNK-IN-SPOT-RATE               PIC S9(5)V9(8)  COMP-3.
       01 LNK-IN-BASE-RATE               PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-QUOTE-RATE              PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-TIME-FRAC               PIC S9(3)V9(8)  COMP-3.
       01 LNK-OUT-QUOTE-OBLIGATION       PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-THEORETICAL-FWD        PIC S9(5)V9(8)  COMP-3.
       01 LNK-OUT-MTM-VALUATION          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-FX-OP LNK-IN-BASE-NOTIONAL
                                LNK-IN-AGREED-RATE LNK-IN-SPOT-RATE
                                LNK-IN-BASE-RATE LNK-IN-QUOTE-RATE
                                LNK-IN-TIME-FRAC
                                LNK-OUT-QUOTE-OBLIGATION
                                LNK-OUT-THEORETICAL-FWD
                                LNK-OUT-MTM-VALUATION LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-QUOTE-OBLIGATION
           MOVE 0 TO LNK-OUT-THEORETICAL-FWD
           MOVE 0 TO LNK-OUT-MTM-VALUATION

           IF LNK-IN-BASE-NOTIONAL <= 0 OR LNK-IN-AGREED-RATE <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Contractual quote obligation = BaseNotional * AgreedRate
           COMPUTE WS-QUOTE-PAYMENT ROUNDED = 
               LNK-IN-BASE-NOTIONAL * LNK-IN-AGREED-RATE
           MOVE WS-QUOTE-PAYMENT TO LNK-OUT-QUOTE-OBLIGATION

      *> 2. Covered Interest Parity theoretical forward: F = S * (1 + r_q*t) / (1 + r_b*t)
           COMPUTE WS-QUOTE-GROWTH ROUNDED = 
               1.00000000 + (LNK-IN-QUOTE-RATE * LNK-IN-TIME-FRAC)
           COMPUTE WS-BASE-GROWTH ROUNDED = 
               1.00000000 + (LNK-IN-BASE-RATE * LNK-IN-TIME-FRAC)

           IF WS-BASE-GROWTH > 0
               COMPUTE WS-THEO-FORWARD-RATE ROUNDED = 
                   LNK-IN-SPOT-RATE * (WS-QUOTE-GROWTH / WS-BASE-GROWTH)
               MOVE WS-THEO-FORWARD-RATE TO LNK-OUT-THEORETICAL-FWD
           END-IF

      *> 3. Mark-to-Market valuation = BaseNotional * (TheoreticalForward - AgreedRate)
           COMPUTE WS-RATE-DIFF = 
               WS-THEO-FORWARD-RATE - LNK-IN-AGREED-RATE
           COMPUTE WS-MTM-VALUATION ROUNDED = 
               LNK-IN-BASE-NOTIONAL * WS-RATE-DIFF
           MOVE WS-MTM-VALUATION TO LNK-OUT-MTM-VALUATION.

           GOBACK.
