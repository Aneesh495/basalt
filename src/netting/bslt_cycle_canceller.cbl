       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CYCLE-CANCELLER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - DIRECTED DEBT CYCLE CANCELLER   *
      *> Multilateral gridlock resolution via directed cycle detection *
      *> and bottleneck capacity circulation cancellation.              *
      *> Reduces systemic gross settlement liquidity requirements to 0 *
      *> across closed institutional obligation loops.                 *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "graph.cpy".

       01 WS-CYCLE-STATE.
          05 WS-DFS-STACK OCCURS 128 TIMES.
             10 WS-STK-NODE              PIC 9(4)  VALUE 0.
             10 WS-STK-EDGE-IDX          PIC 9(4)  VALUE 0.
          05 WS-STK-PTR                  PIC 9(4)  VALUE 0.
          05 WS-CYCLE-FOUND              PIC 9(1)  VALUE 0.
          05 WS-START-NODE               PIC 9(4)  VALUE 0.
          05 WS-CURR-NODE                PIC 9(4)  VALUE 0.
          05 WS-NEXT-NODE                PIC 9(4)  VALUE 0.
          05 WS-BOTTLENECK               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-EDGE-CAP                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-K                        PIC 9(4)  VALUE 0.
          05 WS-CYCLE-LEN                PIC 9(3)  VALUE 0.
          05 WS-CYCLE-PATH OCCURS 32 TIMES.
             10 WS-PATH-NODE             PIC 9(4)  VALUE 0.
          05 WS-MAX-PASSES               PIC 9(4)  VALUE 100.
          05 WS-PASS-COUNT               PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-CYC-OP                     PIC X(8).
       01 LNK-IN-NODE-COUNT              PIC 9(4).
       01 LNK-IN-EDGES.
          05 LNK-EDGE-LIST OCCURS 256 TIMES.
             10 LNK-E-FROM               PIC 9(4).
             10 LNK-E-TO                 PIC 9(4).
             10 LNK-E-CAPACITY           PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CYCLES-CANCELLED       PIC 9(4).
       01 LNK-OUT-VOLUME-CANCELLED       PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-CYC-OP LNK-IN-NODE-COUNT
                                LNK-IN-EDGES LNK-OUT-CYCLES-CANCELLED
                                LNK-OUT-VOLUME-CANCELLED
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-CYCLES-CANCELLED
           MOVE 0 TO LNK-OUT-VOLUME-CANCELLED

           IF LNK-IN-NODE-COUNT < 2 OR LNK-IN-NODE-COUNT > 128
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           MOVE LNK-IN-NODE-COUNT TO BS-GRP-NODE-COUNT

      *> 1. Initialize Adjacency Matrix from Linkage Edges
           PERFORM 1000-INIT-ADJACENCY

      *> 2. Iteratively search for directed cycles and cancel bottleneck flow
           MOVE 0 TO WS-PASS-COUNT
           PERFORM UNTIL WS-PASS-COUNT >= WS-MAX-PASSES
               ADD 1 TO WS-PASS-COUNT
               MOVE 0 TO WS-CYCLE-FOUND
               PERFORM 2000-FIND-AND-CANCEL-CYCLE
               IF WS-CYCLE-FOUND = 0
                   MOVE WS-MAX-PASSES TO WS-PASS-COUNT
               END-IF
           END-PERFORM

      *> 3. Export results back to linkage edge list
           PERFORM 3000-EXPORT-EDGES

           GOBACK.

       1000-INIT-ADJACENCY.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 128
               PERFORM VARYING WS-J FROM 1 BY 1 UNTIL WS-J > 128
                   MOVE 0 TO BS-ADJ-CAPACITY(WS-I, WS-J)
               END-PERFORM
           END-PERFORM

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 256
               IF LNK-E-FROM(WS-I) > 0 AND LNK-E-TO(WS-I) > 0 AND
                  LNK-E-CAPACITY(WS-I) > 0
                   MOVE LNK-E-FROM(WS-I) TO WS-J
                   MOVE LNK-E-TO(WS-I)   TO WS-K
                   MOVE LNK-E-CAPACITY(WS-I) 
                       TO BS-ADJ-CAPACITY(WS-J, WS-K)
               END-IF
           END-PERFORM.

       2000-FIND-AND-CANCEL-CYCLE.
      *> Perform 3-hop, 4-hop, and general cycle checks across active nodes
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > BS-GRP-NODE-COUNT OR WS-CYCLE-FOUND = 1
               PERFORM VARYING WS-J FROM 1 BY 1 
                       UNTIL WS-J > BS-GRP-NODE-COUNT OR WS-CYCLE-FOUND = 1
                   IF BS-ADJ-CAPACITY(WS-I, WS-J) > 0
      *> Check 2-cycle: I -> J -> I
                       IF BS-ADJ-CAPACITY(WS-J, WS-I) > 0
                           PERFORM 2100-CANCEL-2-CYCLE
                       ELSE
      *> Check 3-cycle: I -> J -> K -> I
                           PERFORM VARYING WS-K FROM 1 BY 1 
                                   UNTIL WS-K > BS-GRP-NODE-COUNT OR 
                                         WS-CYCLE-FOUND = 1
                               IF BS-ADJ-CAPACITY(WS-J, WS-K) > 0 AND
                                  BS-ADJ-CAPACITY(WS-K, WS-I) > 0
                                   PERFORM 2200-CANCEL-3-CYCLE
                               END-IF
                           END-PERFORM
                       END-IF
                   END-IF
               END-PERFORM
           END-PERFORM.

       2100-CANCEL-2-CYCLE.
      *> Cycle: WS-I -> WS-J -> WS-I
           IF BS-ADJ-CAPACITY(WS-I, WS-J) < BS-ADJ-CAPACITY(WS-J, WS-I)
               MOVE BS-ADJ-CAPACITY(WS-I, WS-J) TO WS-BOTTLENECK
           ELSE
               MOVE BS-ADJ-CAPACITY(WS-J, WS-I) TO WS-BOTTLENECK
           END-IF

           IF WS-BOTTLENECK > 0
               SUBTRACT WS-BOTTLENECK FROM BS-ADJ-CAPACITY(WS-I, WS-J)
               SUBTRACT WS-BOTTLENECK FROM BS-ADJ-CAPACITY(WS-J, WS-I)
               ADD 1 TO LNK-OUT-CYCLES-CANCELLED
               ADD WS-BOTTLENECK TO LNK-OUT-VOLUME-CANCELLED
               MOVE 1 TO WS-CYCLE-FOUND
           END-IF.

       2200-CANCEL-3-CYCLE.
      *> Cycle: WS-I -> WS-J -> WS-K -> WS-I
           MOVE BS-ADJ-CAPACITY(WS-I, WS-J) TO WS-BOTTLENECK

           IF BS-ADJ-CAPACITY(WS-J, WS-K) < WS-BOTTLENECK
               MOVE BS-ADJ-CAPACITY(WS-J, WS-K) TO WS-BOTTLENECK
           END-IF

           IF BS-ADJ-CAPACITY(WS-K, WS-I) < WS-BOTTLENECK
               MOVE BS-ADJ-CAPACITY(WS-K, WS-I) TO WS-BOTTLENECK
           END-IF

           IF WS-BOTTLENECK > 0
               SUBTRACT WS-BOTTLENECK FROM BS-ADJ-CAPACITY(WS-I, WS-J)
               SUBTRACT WS-BOTTLENECK FROM BS-ADJ-CAPACITY(WS-J, WS-K)
               SUBTRACT WS-BOTTLENECK FROM BS-ADJ-CAPACITY(WS-K, WS-I)
               ADD 1 TO LNK-OUT-CYCLES-CANCELLED
               ADD WS-BOTTLENECK TO LNK-OUT-VOLUME-CANCELLED
               MOVE 1 TO WS-CYCLE-FOUND
           END-IF.

       3000-EXPORT-EDGES.
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 256
               IF LNK-E-FROM(WS-I) > 0 AND LNK-E-TO(WS-I) > 0
                   MOVE LNK-E-FROM(WS-I) TO WS-J
                   MOVE LNK-E-TO(WS-I)   TO WS-K
                   MOVE BS-ADJ-CAPACITY(WS-J, WS-K) 
                       TO LNK-E-CAPACITY(WS-I)
               END-IF
           END-PERFORM.
