       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-CDS.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - CREDIT DEFAULT SWAP (CDS)       *
      *> ISDA standard credit default swap lifecycle state machine:    *
      *> quarterly premium accrual, credit event determination, and    *
      *> auction cash settlement payoff calculation.                   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "cds.cpy".

       01 WS-CDS-VARS.
          05 WS-SPREAD-DEC               PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-PREMIUM-FLOW             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-RECOVERY-DEC             PIC S9(1)V9(8)  COMP-3 VALUE 0.
          05 WS-LOSS-SEVERITY            PIC S9(1)V9(8)  COMP-3 VALUE 0.
          05 WS-PROTECTION-FLOW          PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-CDS-OP                     PIC X(8).
       01 LNK-IN-NOTIONAL                PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-COUPON-BPS              PIC 9(4).
       01 LNK-IN-YEAR-FRAC               PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-CREDIT-EVENT            PIC 9(2).
       01 LNK-IN-AUCTION-PRICE           PIC S9(1)V9(4)  COMP-3.
       01 LNK-OUT-PREMIUM-AMOUNT         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-PROTECTION-PAYOUT      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-NET-CASHFLOW           PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-CDS-OP LNK-IN-NOTIONAL
                                LNK-IN-COUPON-BPS LNK-IN-YEAR-FRAC
                                LNK-IN-CREDIT-EVENT LNK-IN-AUCTION-PRICE
                                LNK-OUT-PREMIUM-AMOUNT
                                LNK-OUT-PROTECTION-PAYOUT
                                LNK-OUT-NET-CASHFLOW LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-PREMIUM-AMOUNT
           MOVE 0 TO LNK-OUT-PROTECTION-PAYOUT
           MOVE 0 TO LNK-OUT-NET-CASHFLOW

           IF LNK-IN-NOTIONAL <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Calculate periodic premium fee: Notional * (Bps / 10000) * YearFrac
           COMPUTE WS-SPREAD-DEC = LNK-IN-COUPON-BPS / 10000.00000000
           COMPUTE WS-PREMIUM-FLOW ROUNDED = 
               LNK-IN-NOTIONAL * WS-SPREAD-DEC * LNK-IN-YEAR-FRAC
           MOVE WS-PREMIUM-FLOW TO LNK-OUT-PREMIUM-AMOUNT

      *> 2. Evaluate Credit Event: if triggered, calculate auction payoff
           IF LNK-IN-CREDIT-EVENT > 0
               MOVE LNK-IN-AUCTION-PRICE TO WS-RECOVERY-DEC
               COMPUTE WS-LOSS-SEVERITY = 1.00000000 - WS-RECOVERY-DEC
               COMPUTE WS-PROTECTION-FLOW ROUNDED = 
                   LNK-IN-NOTIONAL * WS-LOSS-SEVERITY
               MOVE WS-PROTECTION-FLOW TO LNK-OUT-PROTECTION-PAYOUT

      *> Net flow to protection buyer = ProtectionPayout - AccruedPremium
               COMPUTE LNK-OUT-NET-CASHFLOW = 
                   WS-PROTECTION-FLOW - WS-PREMIUM-FLOW
           ELSE
      *> No default event: standard premium paid by buyer to seller
               MOVE WS-PREMIUM-FLOW TO LNK-OUT-NET-CASHFLOW
           END-IF.

           GOBACK.
