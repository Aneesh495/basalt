       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CONTRACT-IRS.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - INTEREST RATE SWAP (IRS) ENGINE *
      *> Plain-vanilla fixed-for-floating swap cash-flow generator,    *
      *> rate fixing reset evaluation, and net settlement calculation.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".

       01 WS-IRS-VARS.
          05 WS-FIXED-PAYMENT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FLOATING-PAYMENT         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-NET-PAYMENT              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-EFF-FLOAT-RATE           PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-PERIOD-FRAC              PIC S9(3)V9(8)  COMP-3 VALUE 0.50000000.

       LINKAGE SECTION.
       01 LNK-IRS-OP                     PIC X(8).
       01 LNK-IN-NOTIONAL                PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-FIXED-RATE              PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-FLOATING-INDEX          PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-SPREAD                  PIC S9(3)V9(8)  COMP-3.
       01 LNK-IN-YEAR-FRACTION           PIC S9(3)V9(8)  COMP-3.
       01 LNK-OUT-FIXED-LEG              PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-FLOAT-LEG              PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-NET-SETTLEMENT         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-PAYER-DIRECTION        PIC X(1).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-IRS-OP LNK-IN-NOTIONAL
                                LNK-IN-FIXED-RATE LNK-IN-FLOATING-INDEX
                                LNK-IN-SPREAD LNK-IN-YEAR-FRACTION
                                LNK-OUT-FIXED-LEG LNK-OUT-FLOAT-LEG
                                LNK-OUT-NET-SETTLEMENT
                                LNK-OUT-PAYER-DIRECTION LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-FIXED-LEG
           MOVE 0 TO LNK-OUT-FLOAT-LEG
           MOVE 0 TO LNK-OUT-NET-SETTLEMENT
           MOVE SPACES TO LNK-OUT-PAYER-DIRECTION

           IF LNK-IN-NOTIONAL <= 0 OR LNK-IN-YEAR-FRACTION <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Fixed Leg: Notional * FixedRate * YearFraction
           COMPUTE WS-FIXED-PAYMENT ROUNDED = 
               LNK-IN-NOTIONAL * LNK-IN-FIXED-RATE * LNK-IN-YEAR-FRACTION
           MOVE WS-FIXED-PAYMENT TO LNK-OUT-FIXED-LEG

      *> 2. Floating Leg: Notional * (FloatingRate + Spread) * YearFraction
           COMPUTE WS-EFF-FLOAT-RATE = 
               LNK-IN-FLOATING-INDEX + LNK-IN-SPREAD
           COMPUTE WS-FLOATING-PAYMENT ROUNDED = 
               LNK-IN-NOTIONAL * WS-EFF-FLOAT-RATE * LNK-IN-YEAR-FRACTION
           MOVE WS-FLOATING-PAYMENT TO LNK-OUT-FLOAT-LEG

      *> 3. Net Settlement Flow: Fixed - Floating
           COMPUTE WS-NET-PAYMENT = 
               WS-FIXED-PAYMENT - WS-FLOATING-PAYMENT

           IF WS-NET-PAYMENT > 0
      *> Fixed payer owes difference to floating payer
               MOVE WS-NET-PAYMENT TO LNK-OUT-NET-SETTLEMENT
               MOVE 'F' TO LNK-OUT-PAYER-DIRECTION
           ELSE
               IF WS-NET-PAYMENT < 0
      *> Floating payer owes difference to fixed payer
                   COMPUTE LNK-OUT-NET-SETTLEMENT = 0 - WS-NET-PAYMENT
                   MOVE 'V' TO LNK-OUT-PAYER-DIRECTION
               ELSE
                   MOVE 0 TO LNK-OUT-NET-SETTLEMENT
                   MOVE '0' TO LNK-OUT-PAYER-DIRECTION
               END-IF
           END-IF.

           GOBACK.
