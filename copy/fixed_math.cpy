      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FIXED-POINT MATHEMATICS          *
      *> 128-bit packed decimal structures with 8 decimal places        *
      *>================================================================*
       01 BS-MATH-CONFIG.
          05 BS-MATH-SCALE               PIC 9(9)  VALUE 100000000.
          05 BS-MATH-ROUND-HALF-EVEN     PIC 9(1)  VALUE 1.
          05 BS-MATH-ROUND-UP            PIC 9(1)  VALUE 2.
          05 BS-MATH-ROUND-DOWN          PIC 9(1)  VALUE 3.
          05 BS-MATH-ROUND-TRUNC         PIC 9(1)  VALUE 4.

       01 BS-FIXED-DECIMAL-BUFFER.
          05 BS-MATH-OP-A                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-OP-B                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-OP-C                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-RESULT              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-REMAINDER           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-ROUND-MODE          PIC 9(1)  VALUE 1.
          05 BS-MATH-ERROR-FLAG          PIC 9(1)  VALUE 0.

       01 BS-TRANSCENDENTAL-BUFFER.
          05 BS-MATH-INPUT-X             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-OUTPUT-Y            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-MATH-TAYLOR-TERMS        PIC 9(3)  VALUE 32.
          05 BS-MATH-NEWTON-ITERS        PIC 9(3)  VALUE 24.
          05 BS-MATH-CONVERGED-FLAG      PIC 9(1)  VALUE 0.

       01 BS-NORMAL-DISTRIB-BUFFER.
          05 BS-NORM-INPUT-Z             PIC S9(9)V9(8)  COMP-3 VALUE 0.
          05 BS-NORM-CDF-RESULT          PIC S9(9)V9(8)  COMP-3 VALUE 0.
          05 BS-NORM-PDF-RESULT          PIC S9(9)V9(8)  COMP-3 VALUE 0.
          05 BS-NORM-INV-PROB            PIC S9(9)V9(8)  COMP-3 VALUE 0.
          05 BS-NORM-QUANTILE-RESULT     PIC S9(9)V9(8)  COMP-3 VALUE 0.
