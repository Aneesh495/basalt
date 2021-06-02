       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-FIXED-MATH.
      *>================================================================*
      *> BASALT TEST SUITE - 128-BIT PACKED DECIMAL MATH VERIFICATION   *
      *> Precision arithmetic, Newton-Raphson sqrt, Taylor exponential, *
      *> and Abramowitz-Stegun normal distribution CDF verification.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".

       01 WS-TEST-VARS.
          05 WS-OP-CODE                  PIC X(8)  VALUE SPACES.
          05 WS-ARG-1                    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ARG-2                    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-RESULT                   PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-EXPECTED                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TOLERANCE                PIC S9(18)V9(8) COMP-3 VALUE 0.00010000.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> TEST 1: Addition 1234567.89012345 + 9876543.21987654
           MOVE 1234567.89012345 TO WS-ARG-1
           MOVE 9876543.21987654 TO WS-ARG-2
           MOVE 11111111.10999999 TO WS-EXPECTED
           CALL "BSLT-FIXED-MATH" USING "ADD     " WS-ARG-1 WS-ARG-2
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-RESULT = WS-EXPECTED
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fixed Math ADD mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 2: Subtraction 5000000.00000000 - 1234567.89012345
           MOVE 5000000.00000000 TO WS-ARG-1
           MOVE 1234567.89012345 TO WS-ARG-2
           MOVE 3765432.10987655 TO WS-EXPECTED
           CALL "BSLT-FIXED-MATH" USING "SUB     " WS-ARG-1 WS-ARG-2
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-RESULT = WS-EXPECTED
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fixed Math SUB mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 3: Multiplication 125000.50000000 * 4.00000000
           MOVE 125000.50000000 TO WS-ARG-1
           MOVE 4.00000000      TO WS-ARG-2
           MOVE 500002.00000000 TO WS-EXPECTED
           CALL "BSLT-FIXED-MATH" USING "MUL     " WS-ARG-1 WS-ARG-2
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-RESULT = WS-EXPECTED
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fixed Math MUL mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 4: Division 1000000.00000000 / 8.00000000
           MOVE 1000000.00000000 TO WS-ARG-1
           MOVE 8.00000000       TO WS-ARG-2
           MOVE 125000.00000000  TO WS-EXPECTED
           CALL "BSLT-FIXED-MATH" USING "DIV     " WS-ARG-1 WS-ARG-2
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-RESULT = WS-EXPECTED
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Fixed Math DIV mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 5: Division by zero trap
           MOVE 1000000.00000000 TO WS-ARG-1
           MOVE 0                TO WS-ARG-2
           CALL "BSLT-FIXED-MATH" USING "DIV     " WS-ARG-1 WS-ARG-2
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-DIVISION-BY-ZERO
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Division by zero not trapped."
           END-IF

      *> TEST 6: Newton-Raphson Sqrt of 4.00000000
           MOVE 4.00000000 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "SQRT    " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           COMPUTE WS-DIFF = WS-RESULT - 2.00000000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < WS-TOLERANCE
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Sqrt(4) mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 7: Newton-Raphson Sqrt of 10000.00000000
           MOVE 10000.00000000 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "SQRT    " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           COMPUTE WS-DIFF = WS-RESULT - 100.00000000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < WS-TOLERANCE
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Sqrt(10000) mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 8: Exponential e^0 = 1.00000000
           MOVE 0 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "EXP     " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-RESULT = 1.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Exp(0) mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 9: Normal CDF Phi(0) = 0.50000000
           MOVE 0 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "NORMCDF " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           COMPUTE WS-DIFF = WS-RESULT - 0.50000000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < WS-TOLERANCE
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NormCDF(0) mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 10: Normal CDF Phi(1.95996) approx 0.97500000
           MOVE 1.95996398 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "NORMCDF " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           COMPUTE WS-DIFF = WS-RESULT - 0.97500000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < 0.00100000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NormCDF(1.96) mismatch. Result: " WS-RESULT
           END-IF

      *> TEST 11: Normal CDF symmetry Phi(-1.96) = 1 - Phi(1.96) approx 0.025
           MOVE -1.95996398 TO WS-ARG-1
           CALL "BSLT-FIXED-MATH" USING "NORMCDF " WS-ARG-1 0
                                        WS-RESULT WS-STATUS
           COMPUTE WS-DIFF = WS-RESULT - 0.02500000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < 0.00100000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NormCDF(-1.96) mismatch. Result: " WS-RESULT
           END-IF.

           GOBACK.
