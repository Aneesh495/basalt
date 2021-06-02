       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-NETTING.
      *>================================================================*
      *> BASALT TEST SUITE - MULTILATERAL NETTING AND GRIDLOCK TESTS   *
      *> Bilateral obligation offsets, 3-node directed cycle cancelling *
      *> and liquidity constraint relaxation under gridlock.           *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "graph.cpy".
       COPY "order.cpy".

       01 WS-NET-VARS.
          05 WS-NET-DEBTOR               PIC X(11) VALUE SPACES.
          05 WS-NET-CREDITOR             PIC X(11) VALUE SPACES.
          05 WS-NET-AMT                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-GROSS-AMT                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SAVINGS-PCT              PIC S9(3)V9(4)  COMP-3 VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-CYCLES-CANCELLED         PIC 9(4)  VALUE 0.
          05 WS-VOL-CANCELLED            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SETTLED-COUNT            PIC 9(4)  VALUE 0.
          05 WS-UNRESOLVED-COUNT         PIC 9(4)  VALUE 0.
          05 WS-PARAM-COUNT-2            PIC 9(4)  VALUE 2.
          05 WS-PARAM-COUNT-3            PIC 9(4)  VALUE 3.
          05 WS-PARTY-A                  PIC X(11) VALUE "BANKAXXXXXX".
          05 WS-PARTY-B                  PIC X(11) VALUE "BANKBXXXXXX".

       01 WS-BILATERAL-ORDERS.
          05 WS-BO-ENTRY OCCURS 64 TIMES.
             10 WS-BO-DEBTOR PIC X(11) VALUE SPACES.
             10 WS-BO-CREDITOR PIC X(11) VALUE SPACES.
             10 WS-BO-AMT PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-BO-CCY PIC X(3)  VALUE "USD".

       01 WS-ASYM-EDGES.
          05 WS-AE-ENTRY OCCURS 256 TIMES.
             10 WS-AE-FROM PIC 9(4) VALUE 0.
             10 WS-AE-TO   PIC 9(4) VALUE 0.
             10 WS-AE-CAP  PIC S9(18)V9(8) COMP-3 VALUE 0.

       01 WS-GRIDLOCK-NODES.
          05 WS-GN-ENTRY OCCURS 128 TIMES.
             10 WS-GN-CASH   PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-GN-CREDIT PIC S9(18)V9(8) COMP-3 VALUE 0.

       01 WS-GRIDLOCK-ORDERS.
          05 WS-GO-ENTRY OCCURS 64 TIMES.
             10 WS-GO-FROM PIC 9(4) VALUE 0.
             10 WS-GO-TO   PIC 9(4) VALUE 0.
             10 WS-GO-AMT  PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 WS-GO-SET  PIC 9(1) VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> Populate bilateral test orders
           MOVE "BANKAXXXXXX"        TO WS-BO-DEBTOR(1)
           MOVE "BANKBXXXXXX"        TO WS-BO-CREDITOR(1)
           MOVE 30000000.00000000    TO WS-BO-AMT(1)
           MOVE "USD"                TO WS-BO-CCY(1)

           MOVE "BANKBXXXXXX"        TO WS-BO-DEBTOR(2)
           MOVE "BANKAXXXXXX"        TO WS-BO-CREDITOR(2)
           MOVE 10000000.00000000    TO WS-BO-AMT(2)
           MOVE "USD"                TO WS-BO-CCY(2)

      *> Populate 3-node cycle edges (1->2 $150M, 2->3 $100M, 3->1 $100M)
           MOVE 1                    TO WS-AE-FROM(1)
           MOVE 2                    TO WS-AE-TO(1)
           MOVE 150000000.00000000   TO WS-AE-CAP(1)

           MOVE 2                    TO WS-AE-FROM(2)
           MOVE 3                    TO WS-AE-TO(2)
           MOVE 100000000.00000000   TO WS-AE-CAP(2)

           MOVE 3                    TO WS-AE-FROM(3)
           MOVE 1                    TO WS-AE-TO(3)
           MOVE 100000000.00000000   TO WS-AE-CAP(3)

      *> Populate gridlock nodes
           MOVE 50000000.00000000    TO WS-GN-CASH(1)
           MOVE 50000000.00000000    TO WS-GN-CREDIT(1)

           MOVE 20000000.00000000    TO WS-GN-CASH(2)
           MOVE 20000000.00000000    TO WS-GN-CREDIT(2)

           MOVE 10000000.00000000    TO WS-GN-CASH(3)
           MOVE 10000000.00000000    TO WS-GN-CREDIT(3)

      *> Populate gridlock orders
           MOVE 1                    TO WS-GO-FROM(1)
           MOVE 2                    TO WS-GO-TO(1)
           MOVE 80000000.00000000    TO WS-GO-AMT(1)
           MOVE 0                    TO WS-GO-SET(1)

           MOVE 2                    TO WS-GO-FROM(2)
           MOVE 3                    TO WS-GO-TO(2)
           MOVE 30000000.00000000    TO WS-GO-AMT(2)
           MOVE 0                    TO WS-GO-SET(2)

      *>----------------------------------------------------------------*
      *> TEST 1: Bilateral Netting Offset ($30M vs $10M = $20M net)
      *>----------------------------------------------------------------*
           MOVE 2 TO WS-PARAM-COUNT-2
           CALL "BSLT-NETTING-BILATERAL" USING "NETPAIR "
                                               WS-PARTY-A
                                               WS-PARTY-B
                                               WS-PARAM-COUNT-2
                                               WS-BILATERAL-ORDERS
                                               WS-NET-DEBTOR
                                               WS-NET-CREDITOR
                                               WS-NET-AMT
                                               WS-GROSS-AMT
                                               WS-SAVINGS-PCT
                                               WS-STATUS
           IF WS-STATUS = BS-RC-OK AND
              WS-NET-DEBTOR = "BANKAXXXXXX" AND
              WS-NET-CREDITOR = "BANKBXXXXXX" AND
              WS-NET-AMT = 20000000.00000000 AND
              WS-GROSS-AMT = 40000000.00000000 AND
              WS-SAVINGS-PCT = 50.0000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Bilateral netting calculation failed."
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Asymmetric 3-node cycle cancelling
      *>----------------------------------------------------------------*
           MOVE 3 TO WS-PARAM-COUNT-3
           CALL "BSLT-CYCLE-CANCELLER" USING "CANCEL  "
                                             WS-PARAM-COUNT-3
                                             WS-ASYM-EDGES
                                             WS-CYCLES-CANCELLED
                                             WS-VOL-CANCELLED
                                             WS-STATUS
           IF WS-STATUS = BS-RC-OK AND
              WS-CYCLES-CANCELLED = 1 AND
              WS-VOL-CANCELLED = 100000000.00000000 AND
              WS-AE-CAP(1) = 50000000.00000000 AND
              WS-AE-CAP(2) = 0 AND
              WS-AE-CAP(3) = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Asymmetric cycle cancelling failed."
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Multilateral gridlock resolution under liquidity limits
      *>----------------------------------------------------------------*
           MOVE 3 TO WS-PARAM-COUNT-3
           MOVE 2 TO WS-PARAM-COUNT-2
           CALL "BSLT-GRIDLOCK-RESOLVER" USING "RESOLVE "
                                              WS-PARAM-COUNT-3
                                              WS-GRIDLOCK-NODES
                                              WS-PARAM-COUNT-2
                                              WS-GRIDLOCK-ORDERS
                                              WS-SETTLED-COUNT
                                              WS-UNRESOLVED-COUNT
                                              WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-SETTLED-COUNT > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Gridlock resolution failed."
           END-IF.

           GOBACK.
