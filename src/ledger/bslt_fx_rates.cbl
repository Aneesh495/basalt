       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-FX-RATES.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FX CROSS-RATE TRIANGULATION     *
      *> Tri-party currency cross-rate matrix, indirect quote conversion*
      *> via base reference peg, and bid/ask spread evaluation.        *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "iso4217.cpy".

       01 WS-TRIANGULATION-VARS.
          05 WS-RATE-FROM-USD            PIC S9(9)V9(8) COMP-3 VALUE 1.00000000.
          05 WS-RATE-TO-USD              PIC S9(9)V9(8) COMP-3 VALUE 1.00000000.
          05 WS-CROSS-RATE               PIC S9(9)V9(8) COMP-3 VALUE 1.00000000.
          05 WS-I                        PIC 9(3)       VALUE 1.
          05 WS-FOUND-FROM               PIC 9(1)       VALUE 0.
          05 WS-FOUND-TO                 PIC 9(1)       VALUE 0.

       LINKAGE SECTION.
       01 LNK-FXR-OP                     PIC X(8).
       01 LNK-IN-BASE-CCY                PIC X(3).
       01 LNK-IN-QUOTE-CCY               PIC X(3).
       01 LNK-IN-BASE-AMOUNT             PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CONVERTED-AMT          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CROSS-RATE             PIC S9(9)V9(8)  COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-FXR-OP LNK-IN-BASE-CCY
                                LNK-IN-QUOTE-CCY LNK-IN-BASE-AMOUNT
                                LNK-OUT-CONVERTED-AMT
                                LNK-OUT-CROSS-RATE LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-CONVERTED-AMT
           MOVE 1.00000000 TO LNK-OUT-CROSS-RATE

           IF LNK-IN-BASE-AMOUNT < 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           IF LNK-IN-BASE-CCY = LNK-IN-QUOTE-CCY
               MOVE LNK-IN-BASE-AMOUNT TO LNK-OUT-CONVERTED-AMT
               MOVE 1.00000000 TO LNK-OUT-CROSS-RATE
               GOBACK
           END-IF

      *> 1. Lookup reference rates to USD
           PERFORM 1000-LOOKUP-RATES

           IF WS-FOUND-FROM = 0 OR WS-FOUND-TO = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 2. Cross Rate = (Base->USD) / (Quote->USD)
           IF WS-RATE-TO-USD > 0
               COMPUTE WS-CROSS-RATE ROUNDED = 
                   WS-RATE-FROM-USD / WS-RATE-TO-USD
               MOVE WS-CROSS-RATE TO LNK-OUT-CROSS-RATE
               COMPUTE LNK-OUT-CONVERTED-AMT ROUNDED = 
                   LNK-IN-BASE-AMOUNT * WS-CROSS-RATE
           ELSE
               MOVE BS-RC-DIVISION-BY-ZERO TO LNK-OUT-STATUS
           END-IF.

           GOBACK.

       1000-LOOKUP-RATES.
      *> Pre-calibrated reference rates
           MOVE 0 TO WS-FOUND-FROM
           MOVE 0 TO WS-FOUND-TO
           MOVE 1.00000000 TO WS-RATE-FROM-USD
           MOVE 1.00000000 TO WS-RATE-TO-USD

           IF LNK-IN-BASE-CCY = "USD"
               MOVE 1.00000000 TO WS-RATE-FROM-USD
               MOVE 1 TO WS-FOUND-FROM
           END-IF
           IF LNK-IN-BASE-CCY = "EUR"
               MOVE 1.08500000 TO WS-RATE-FROM-USD
               MOVE 1 TO WS-FOUND-FROM
           END-IF
           IF LNK-IN-BASE-CCY = "GBP"
               MOVE 1.27500000 TO WS-RATE-FROM-USD
               MOVE 1 TO WS-FOUND-FROM
           END-IF
           IF LNK-IN-BASE-CCY = "JPY"
               MOVE 0.00650000 TO WS-RATE-FROM-USD
               MOVE 1 TO WS-FOUND-FROM
           END-IF
           IF LNK-IN-BASE-CCY = "CHF"
               MOVE 1.14000000 TO WS-RATE-FROM-USD
               MOVE 1 TO WS-FOUND-FROM
           END-IF

           IF LNK-IN-QUOTE-CCY = "USD"
               MOVE 1.00000000 TO WS-RATE-TO-USD
               MOVE 1 TO WS-FOUND-TO
           END-IF
           IF LNK-IN-QUOTE-CCY = "EUR"
               MOVE 1.08500000 TO WS-RATE-TO-USD
               MOVE 1 TO WS-FOUND-TO
           END-IF
           IF LNK-IN-QUOTE-CCY = "GBP"
               MOVE 1.27500000 TO WS-RATE-TO-USD
               MOVE 1 TO WS-FOUND-TO
           END-IF
           IF LNK-IN-QUOTE-CCY = "JPY"
               MOVE 0.00650000 TO WS-RATE-TO-USD
               MOVE 1 TO WS-FOUND-TO
           END-IF
           IF LNK-IN-QUOTE-CCY = "CHF"
               MOVE 1.14000000 TO WS-RATE-TO-USD
               MOVE 1 TO WS-FOUND-TO
           END-IF.
