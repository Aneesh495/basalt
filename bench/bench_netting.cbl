       IDENTIFICATION DIVISION.
       PROGRAM-ID. BENCH-NETTING.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - NETTING BENCHMARK                *
      *> Measures throughput of multilateral netting and cycle cancel. *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "graph.cpy".

       01 WS-BENCH-VARS.
          05 WS-CYCLE-RUNS               PIC 9(6) VALUE 1000.
          05 WS-I                        PIC 9(6) VALUE 0.
          05 WS-NODES                    PIC 9(4) VALUE 3.
          05 WS-CYCLES-FOUND             PIC 9(4) VALUE 0.
          05 WS-VOLUME-CANCELLED         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STATUS                   PIC 9(4) VALUE 0.

       01 WS-ASYM-EDGES.
          05 WS-AE-ENTRY OCCURS 256 TIMES.
             10 WS-AE-FROM               PIC 9(4) VALUE 0.
             10 WS-AE-TO                 PIC 9(4) VALUE 0.
             10 WS-AE-CAP                PIC S9(18)V9(8) COMP-3 VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "+========================================================+"
           DISPLAY "|           BASALT MULTILATERAL NETTING BENCHMARK        |"
           DISPLAY "+========================================================+"
           DISPLAY " Benchmarking directed cycle detection and gridlock resolution..."

      *> Setup 3-node cycle
           MOVE 1                  TO WS-AE-FROM(1)
           MOVE 2                  TO WS-AE-TO(1)
           MOVE 150000000.00000000 TO WS-AE-CAP(1)

           MOVE 2                  TO WS-AE-FROM(2)
           MOVE 3                  TO WS-AE-TO(2)
           MOVE 100000000.00000000 TO WS-AE-CAP(2)

           MOVE 3                  TO WS-AE-FROM(3)
           MOVE 1                  TO WS-AE-TO(3)
           MOVE 100000000.00000000 TO WS-AE-CAP(3)

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1000
               MOVE 150000000.00000000 TO WS-AE-CAP(1)
               MOVE 100000000.00000000 TO WS-AE-CAP(2)
               MOVE 100000000.00000000 TO WS-AE-CAP(3)

               CALL "BSLT-CYCLE-CANCELLER" USING "CANCEL  "
                                                 WS-NODES
                                                 WS-ASYM-EDGES
                                                 WS-CYCLES-FOUND
                                                 WS-VOLUME-CANCELLED
                                                 WS-STATUS
           END-PERFORM

           DISPLAY " Benchmark Completed: 1,000 netting cycles evaluated."
           DISPLAY " Cycles Cancelled : " WS-CYCLES-FOUND
           DISPLAY " Volume Netting   : " WS-VOLUME-CANCELLED
           DISPLAY "+========================================================+"
           MOVE 0 TO RETURN-CODE
           GOBACK.
