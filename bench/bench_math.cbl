       IDENTIFICATION DIVISION.
       PROGRAM-ID. BENCH-MATH.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - 128-BIT MATH BENCHMARK           *
      *> Measures execution throughput of exact fixed-decimal math.     *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".

       01 WS-BENCH-VARS.
          05 WS-ITERATIONS               PIC 9(8) VALUE 500000.
          05 WS-I                        PIC 9(8) VALUE 0.
          05 WS-A                        PIC S9(18)V9(8) COMP-3 VALUE 1234567.89012345.
          05 WS-B                        PIC S9(18)V9(8) COMP-3 VALUE 987654.32109876.
          05 WS-RES                      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STATUS                   PIC 9(4) VALUE 0.
          05 WS-ELAPSED-START            PIC 9(8) VALUE 0.
          05 WS-ELAPSED-END              PIC 9(8) VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "+========================================================+"
           DISPLAY "|           BASALT 128-BIT DECIMAL MATH BENCHMARK        |"
           DISPLAY "+========================================================+"
           DISPLAY " Running 500,000 fixed-point arithmetic operations..."

           MOVE FUNCTION CURRENT-DATE(9:8) TO WS-ELAPSED-START

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-ITERATIONS
               CALL "BSLT-FIXED-MATH" USING "ADD     " WS-A WS-B WS-RES WS-STATUS
               CALL "BSLT-FIXED-MATH" USING "SUB     " WS-RES WS-B WS-A WS-STATUS
               COMPUTE WS-RES = WS-A * 1.00000500
           END-PERFORM

           MOVE FUNCTION CURRENT-DATE(9:8) TO WS-ELAPSED-END

           DISPLAY " Benchmark Completed: 500,000 iterations."
           DISPLAY " Final Computed Result: " WS-RES
           DISPLAY "+========================================================+"
           GOBACK.
