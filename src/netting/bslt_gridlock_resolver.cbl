       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-GRIDLOCK-RESOLVER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - MULTILATERAL GRIDLOCK RESOLVER  *
      *> Resolves queued settlement deadlocks under liquidity limits   *
      *> by iteratively finding maximal feasible order subgraphs.      *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "graph.cpy".
       COPY "order.cpy".

       01 WS-GRIDLOCK-STATE.
          05 WS-DEFICIT-FOUND            PIC 9(1)  VALUE 0.
          05 WS-DEFICIT-NODE             PIC 9(4)  VALUE 0.
          05 WS-WORST-DEFICIT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CANDIDATE-MASK OCCURS 64 TIMES.
             10 WS-INCLUDED              PIC 9(1)  VALUE 1.
          05 WS-SIM-BALANCE OCCURS 128 TIMES.
             10 WS-SIM-BAL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-ROUND-COUNT              PIC 9(4)  VALUE 0.
          05 WS-MAX-ROUNDS               PIC 9(4)  VALUE 64.
          05 WS-ELIMINATED-ORDER         PIC 9(4)  VALUE 0.
          05 WS-MAX-ORDER-VAL            PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-GLR-OP                     PIC X(8).
       01 LNK-IN-NODE-COUNT              PIC 9(4).
       01 LNK-IN-NODE-LIMITS.
          05 LNK-NODE-PARAM OCCURS 128 TIMES.
             10 LNK-N-CASH               PIC S9(18)V9(8) COMP-3.
             10 LNK-N-CREDIT             PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-ORDER-COUNT             PIC 9(4).
       01 LNK-IN-QUEUED-ORDERS.
          05 LNK-Q-ORD OCCURS 64 TIMES.
             10 LNK-Q-FROM               PIC 9(4).
             10 LNK-Q-TO                 PIC 9(4).
             10 LNK-Q-AMT                PIC S9(18)V9(8) COMP-3.
             10 LNK-Q-SETTLED            PIC 9(1).
       01 LNK-OUT-SETTLED-COUNT          PIC 9(4).
       01 LNK-OUT-UNRESOLVED-COUNT       PIC 9(4).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-GLR-OP LNK-IN-NODE-COUNT
                                LNK-IN-NODE-LIMITS LNK-IN-ORDER-COUNT
                                LNK-IN-QUEUED-ORDERS
                                LNK-OUT-SETTLED-COUNT
                                LNK-OUT-UNRESOLVED-COUNT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-SETTLED-COUNT
           MOVE 0 TO LNK-OUT-UNRESOLVED-COUNT

           IF LNK-IN-ORDER-COUNT = 0 OR LNK-IN-ORDER-COUNT > 64
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> Initially include all queued orders in candidate set
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-ORDER-COUNT
               MOVE 1 TO WS-INCLUDED(WS-I)
           END-PERFORM

      *> Iteratively test liquidity feasibility; prune worst debtor order on deficit
           MOVE 0 TO WS-ROUND-COUNT
           PERFORM UNTIL WS-ROUND-COUNT >= WS-MAX-ROUNDS
               ADD 1 TO WS-ROUND-COUNT
               PERFORM 1000-SIMULATE-BALANCES
               IF WS-DEFICIT-FOUND = 0
      *> Feasible state found: all included orders can settle simultaneously
                   MOVE WS-MAX-ROUNDS TO WS-ROUND-COUNT
               ELSE
      *> Eliminate largest outgoing order of deficit node to restore balance
                   PERFORM 2000-PRUNE-DEFICIT-ORDER
                   IF WS-ELIMINATED-ORDER = 0
      *> No further orders can be pruned
                       MOVE WS-MAX-ROUNDS TO WS-ROUND-COUNT
                   END-IF
               END-IF
           END-PERFORM

      *> Export settlement decisions
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-ORDER-COUNT
               IF WS-INCLUDED(WS-I) = 1
                   MOVE 1 TO LNK-Q-SETTLED(WS-I)
                   ADD 1 TO LNK-OUT-SETTLED-COUNT
               ELSE
                   MOVE 0 TO LNK-Q-SETTLED(WS-I)
                   ADD 1 TO LNK-OUT-UNRESOLVED-COUNT
               END-IF
           END-PERFORM

           GOBACK.

       1000-SIMULATE-BALANCES.
      *> Initialize simulated balance with starting cash + credit limit
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-NODE-COUNT
               COMPUTE WS-SIM-BAL(WS-I) = 
                   LNK-N-CASH(WS-I) + LNK-N-CREDIT(WS-I)
           END-PERFORM

      *> Apply all candidate order inflows and outflows
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-ORDER-COUNT
               IF WS-INCLUDED(WS-I) = 1
                   MOVE LNK-Q-FROM(WS-I) TO WS-J
                   SUBTRACT LNK-Q-AMT(WS-I) FROM WS-SIM-BAL(WS-J)
                   MOVE LNK-Q-TO(WS-I) TO WS-J
                   ADD LNK-Q-AMT(WS-I) TO WS-SIM-BAL(WS-J)
               END-IF
           END-PERFORM

      *> Identify if any node is in deficit (< 0)
           MOVE 0 TO WS-DEFICIT-FOUND
           MOVE 0 TO WS-DEFICIT-NODE
           MOVE 0 TO WS-WORST-DEFICIT

           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-NODE-COUNT
               IF WS-SIM-BAL(WS-I) < 0
                   MOVE 1 TO WS-DEFICIT-FOUND
                   IF WS-SIM-BAL(WS-I) < WS-WORST-DEFICIT
                       MOVE WS-SIM-BAL(WS-I) TO WS-WORST-DEFICIT
                       MOVE WS-I TO WS-DEFICIT-NODE
                   END-IF
               END-IF
           END-PERFORM.

       2000-PRUNE-DEFICIT-ORDER.
      *> Find largest outgoing order from the node with worst deficit
           MOVE 0 TO WS-ELIMINATED-ORDER
           MOVE 0 TO WS-MAX-ORDER-VAL

           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-ORDER-COUNT
               IF WS-INCLUDED(WS-I) = 1 AND 
                  LNK-Q-FROM(WS-I) = WS-DEFICIT-NODE
                   IF LNK-Q-AMT(WS-I) > WS-MAX-ORDER-VAL
                       MOVE LNK-Q-AMT(WS-I) TO WS-MAX-ORDER-VAL
                       MOVE WS-I TO WS-ELIMINATED-ORDER
                   END-IF
               END-IF
           END-PERFORM

           IF WS-ELIMINATED-ORDER > 0
               MOVE 0 TO WS-INCLUDED(WS-ELIMINATED-ORDER)
           END-IF.
