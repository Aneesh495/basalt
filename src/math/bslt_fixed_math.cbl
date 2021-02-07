       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-FIXED-MATH.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - PRECISION FIXED-POINT MATH       *
      *> 128-bit packed decimal arithmetic, Newton-Raphson square root, *
      *> Taylor series exponentials, and Abramowitz-Stegun normal CDF.  *
      *> Zero floating-point drift: exact decimal rounding throughout.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".

       01 WS-TEMP-VARS.
          05 WS-ITER-COUNT               PIC 9(4)  VALUE 0.
          05 WS-X-PREV                   PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-X-CURR                   PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-EPSILON                  PIC S9(18)V9(8) COMP-3 VALUE 0.00000001.
          05 WS-HALF                     PIC S9(1)V9(8)  COMP-3 VALUE 0.50000000.
          05 WS-ONE                      PIC S9(1)V9(8)  COMP-3 VALUE 1.00000000.
          05 WS-TWO                      PIC S9(1)V9(8)  COMP-3 VALUE 2.00000000.
          05 WS-TERM                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM                      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FACTORIAL                PIC S9(18)V9(8) COMP-3 VALUE 1.00000000.
          05 WS-POWER-X                  PIC S9(18)V9(8) COMP-3 VALUE 1.00000000.

      *> Abramowitz-Stegun constants for Normal CDF
       01 WS-NORM-CONSTANTS.
          05 WS-CONST-P                  PIC S9(1)V9(8) COMP-3 VALUE 0.23164190.
          05 WS-CONST-B1                 PIC S9(1)V9(8) COMP-3 VALUE 0.31938153.
          05 WS-CONST-B2                 PIC S9(1)V9(8) COMP-3 VALUE -0.35656378.
          05 WS-CONST-B3                 PIC S9(1)V9(8) COMP-3 VALUE 1.78147794.
          05 WS-CONST-B4                 PIC S9(1)V9(8) COMP-3 VALUE -1.82125598.
          05 WS-CONST-B5                 PIC S9(1)V9(8) COMP-3 VALUE 1.33027443.
          05 WS-CONST-INV-SQRT-2PI       PIC S9(1)V9(8) COMP-3 VALUE 0.39894228.
          05 WS-NORM-T                   PIC S9(1)V9(8) COMP-3 VALUE 0.
          05 WS-NORM-POLY                PIC S9(3)V9(8) COMP-3 VALUE 0.
          05 WS-NORM-EXP                 PIC S9(3)V9(8) COMP-3 VALUE 0.
          05 WS-NORM-Z-SQR               PIC S9(5)V9(8) COMP-3 VALUE 0.
          05 WS-NORM-ABS-Z               PIC S9(3)V9(8) COMP-3 VALUE 0.
          05 WS-NORM-SIGN-FLAG           PIC 9(1)       VALUE 0.

       LINKAGE SECTION.
       01 LNK-MATH-OP                    PIC X(8).
       01 LNK-MATH-IN-1                  PIC S9(18)V9(8) COMP-3.
       01 LNK-MATH-IN-2                  PIC S9(18)V9(8) COMP-3.
       01 LNK-MATH-OUT                   PIC S9(18)V9(8) COMP-3.
       01 LNK-MATH-STATUS                PIC 9(4).

       PROCEDURE DIVISION USING LNK-MATH-OP LNK-MATH-IN-1 LNK-MATH-IN-2
                                LNK-MATH-OUT LNK-MATH-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-MATH-STATUS
           MOVE 0 TO LNK-MATH-OUT

           EVALUATE LNK-MATH-OP
               WHEN "ADD     "
                   PERFORM 1000-ADD
               WHEN "SUB     "
                   PERFORM 2000-SUB
               WHEN "MUL     "
                   PERFORM 3000-MUL
               WHEN "DIV     "
                   PERFORM 4000-DIV
               WHEN "SQRT    "
                   PERFORM 5000-SQRT
               WHEN "EXP     "
                   PERFORM 6000-EXP
               WHEN "NORMCDF "
                   PERFORM 7000-NORM-CDF
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-MATH-STATUS
           END-EVALUATE

           GOBACK.

       1000-ADD.
           ADD LNK-MATH-IN-1 TO LNK-MATH-IN-2 GIVING LNK-MATH-OUT
               ON SIZE ERROR
                   MOVE BS-RC-MATH-OVERFLOW TO LNK-MATH-STATUS
           END-ADD.

       2000-SUB.
           SUBTRACT LNK-MATH-IN-2 FROM LNK-MATH-IN-1 GIVING LNK-MATH-OUT
               ON SIZE ERROR
                   MOVE BS-RC-MATH-OVERFLOW TO LNK-MATH-STATUS
           END-SUBTRACT.

       3000-MUL.
           MULTIPLY LNK-MATH-IN-1 BY LNK-MATH-IN-2 GIVING LNK-MATH-OUT
               ROUNDED
               ON SIZE ERROR
                   MOVE BS-RC-MATH-OVERFLOW TO LNK-MATH-STATUS
           END-MULTIPLY.

       4000-DIV.
           IF LNK-MATH-IN-2 = 0
               MOVE BS-RC-DIVISION-BY-ZERO TO LNK-MATH-STATUS
               MOVE 0 TO LNK-MATH-OUT
           ELSE
               DIVIDE LNK-MATH-IN-1 BY LNK-MATH-IN-2 GIVING LNK-MATH-OUT
                   ROUNDED
                   ON SIZE ERROR
                       MOVE BS-RC-MATH-OVERFLOW TO LNK-MATH-STATUS
               END-DIVIDE
           END-IF.

       5000-SQRT.
      *> Newton-Raphson approximation for square root in fixed-point decimal
           IF LNK-MATH-IN-1 < 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-MATH-STATUS
               MOVE 0 TO LNK-MATH-OUT
           ELSE
               IF LNK-MATH-IN-1 = 0
                   MOVE 0 TO LNK-MATH-OUT
               ELSE
      *> Initial guess x0 = (S + 1) / 2
                   COMPUTE WS-X-CURR = (LNK-MATH-IN-1 + WS-ONE) * WS-HALF
                   MOVE 0 TO WS-ITER-COUNT
                   PERFORM UNTIL WS-ITER-COUNT >= 24
                       ADD 1 TO WS-ITER-COUNT
                       MOVE WS-X-CURR TO WS-X-PREV
                       IF WS-X-CURR > 0
                           COMPUTE WS-X-CURR ROUNDED = 
                               WS-HALF * (WS-X-PREV + 
                               (LNK-MATH-IN-1 / WS-X-PREV))
                           COMPUTE WS-DIFF = WS-X-CURR - WS-X-PREV
                           IF WS-DIFF < 0
                               COMPUTE WS-DIFF = 0 - WS-DIFF
                           END-IF
                           IF WS-DIFF < WS-EPSILON
                               MOVE 24 TO WS-ITER-COUNT
                           END-IF
                       END-IF
                   END-PERFORM
                   MOVE WS-X-CURR TO LNK-MATH-OUT
               END-IF
           END-IF.

       6000-EXP.
      *> Taylor series expansion for e^x: sum(x^n / n!) for n=0..20
           IF LNK-MATH-IN-1 > 10.00000000
               MOVE BS-RC-MATH-OVERFLOW TO LNK-MATH-STATUS
               MOVE 0 TO LNK-MATH-OUT
           ELSE
               MOVE WS-ONE TO WS-SUM
               MOVE WS-ONE TO WS-POWER-X
               MOVE WS-ONE TO WS-FACTORIAL
               MOVE 1 TO WS-ITER-COUNT
               PERFORM UNTIL WS-ITER-COUNT > 20
                   COMPUTE WS-POWER-X ROUNDED = 
                       WS-POWER-X * LNK-MATH-IN-1
                   COMPUTE WS-FACTORIAL = 
                       WS-FACTORIAL * WS-ITER-COUNT
                   COMPUTE WS-TERM ROUNDED = 
                       WS-POWER-X / WS-FACTORIAL
                   ADD WS-TERM TO WS-SUM
                   ADD 1 TO WS-ITER-COUNT
               END-PERFORM
               MOVE WS-SUM TO LNK-MATH-OUT
           END-IF.

       7000-NORM-CDF.
      *> Abramowitz and Stegun 26.2.17 polynomial approximation
           IF LNK-MATH-IN-1 < 0
               MOVE 1 TO WS-NORM-SIGN-FLAG
               COMPUTE WS-NORM-ABS-Z = 0 - LNK-MATH-IN-1
           ELSE
               MOVE 0 TO WS-NORM-SIGN-FLAG
               MOVE LNK-MATH-IN-1 TO WS-NORM-ABS-Z
           END-IF

           IF WS-NORM-ABS-Z > 7.00000000
               IF WS-NORM-SIGN-FLAG = 1
                   MOVE 0 TO LNK-MATH-OUT
               ELSE
                   MOVE WS-ONE TO LNK-MATH-OUT
               END-IF
           ELSE
               COMPUTE WS-NORM-T ROUNDED = 
                   WS-ONE / (WS-ONE + (WS-CONST-P * WS-NORM-ABS-Z))
               COMPUTE WS-NORM-Z-SQR ROUNDED = 
                   (WS-NORM-ABS-Z * WS-NORM-ABS-Z) * WS-HALF
               
      *> Approximate exp(-z^2 / 2) via Taylor series
               COMPUTE WS-TERM = 0 - WS-NORM-Z-SQR
               MOVE WS-ONE TO WS-NORM-EXP
               MOVE WS-ONE TO WS-POWER-X
               MOVE WS-ONE TO WS-FACTORIAL
               MOVE 1 TO WS-ITER-COUNT
               PERFORM UNTIL WS-ITER-COUNT > 16
                   COMPUTE WS-POWER-X ROUNDED = WS-POWER-X * WS-TERM
                   COMPUTE WS-FACTORIAL = WS-FACTORIAL * WS-ITER-COUNT
                   COMPUTE WS-DIFF ROUNDED = WS-POWER-X / WS-FACTORIAL
                   ADD WS-DIFF TO WS-NORM-EXP
                   ADD 1 TO WS-ITER-COUNT
               END-PERFORM

               COMPUTE WS-NORM-POLY ROUNDED = 
                   WS-NORM-T * (WS-CONST-B1 + 
                   WS-NORM-T * (WS-CONST-B2 + 
                   WS-NORM-T * (WS-CONST-B3 + 
                   WS-NORM-T * (WS-CONST-B4 + 
                   WS-NORM-T * WS-CONST-B5))))

               COMPUTE WS-SUM ROUNDED = 
                   WS-CONST-INV-SQRT-2PI * WS-NORM-EXP * WS-NORM-POLY

               IF WS-NORM-SIGN-FLAG = 1
                   MOVE WS-SUM TO LNK-MATH-OUT
               ELSE
                   COMPUTE LNK-MATH-OUT = WS-ONE - WS-SUM
               END-IF
           END-IF.
