       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-NETTING-BILATERAL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - BILATERAL NETTING ENGINE        *
      *> Pairwise counterparty obligation aggregator, mutual offset     *
      *> calculation, and liquidity compression ratio evaluation.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "order.cpy".

       01 WS-PAIR-ACCUMULATORS.
          05 WS-FLOW-A-TO-B              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FLOW-B-TO-A              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-NET-FLOW                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-GROSS-FLOW               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SAVINGS-AMT              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SAVINGS-PCT              PIC S9(3)V9(4)  COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.

       LINKAGE SECTION.
       01 LNK-BIL-OP                     PIC X(8).
       01 LNK-IN-PARTY-A-BIC             PIC X(11).
       01 LNK-IN-PARTY-B-BIC             PIC X(11).
       01 LNK-IN-ORDER-COUNT             PIC 9(4).
       01 LNK-IN-ORDERS.
          05 LNK-ORD-ITEM OCCURS 64 TIMES.
             10 LNK-O-DEBTOR             PIC X(11).
             10 LNK-O-CREDITOR           PIC X(11).
             10 LNK-O-AMOUNT             PIC S9(18)V9(8) COMP-3.
             10 LNK-O-CCY                PIC X(3).
       01 LNK-OUT-NET-DEBTOR             PIC X(11).
       01 LNK-OUT-NET-CREDITOR           PIC X(11).
       01 LNK-OUT-NET-AMOUNT             PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-GROSS-AMOUNT           PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-SAVINGS-PCT            PIC S9(3)V9(4)  COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-BIL-OP LNK-IN-PARTY-A-BIC
                                LNK-IN-PARTY-B-BIC LNK-IN-ORDER-COUNT
                                LNK-IN-ORDERS LNK-OUT-NET-DEBTOR
                                LNK-OUT-NET-CREDITOR LNK-OUT-NET-AMOUNT
                                LNK-OUT-GROSS-AMOUNT LNK-OUT-SAVINGS-PCT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-NET-AMOUNT
           MOVE 0 TO LNK-OUT-GROSS-AMOUNT
           MOVE 0 TO LNK-OUT-SAVINGS-PCT
           MOVE SPACES TO LNK-OUT-NET-DEBTOR
           MOVE SPACES TO LNK-OUT-NET-CREDITOR

           IF LNK-IN-ORDER-COUNT = 0 OR LNK-IN-ORDER-COUNT > 64
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           MOVE 0 TO WS-FLOW-A-TO-B
           MOVE 0 TO WS-FLOW-B-TO-A
           MOVE 0 TO WS-GROSS-FLOW

           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-ORDER-COUNT
               ADD LNK-O-AMOUNT(WS-I) TO WS-GROSS-FLOW
               IF LNK-O-DEBTOR(WS-I) = LNK-IN-PARTY-A-BIC AND
                  LNK-O-CREDITOR(WS-I) = LNK-IN-PARTY-B-BIC
                   ADD LNK-O-AMOUNT(WS-I) TO WS-FLOW-A-TO-B
               ELSE
                   IF LNK-O-DEBTOR(WS-I) = LNK-IN-PARTY-B-BIC AND
                      LNK-O-CREDITOR(WS-I) = LNK-IN-PARTY-A-BIC
                       ADD LNK-O-AMOUNT(WS-I) TO WS-FLOW-B-TO-A
                   END-IF
               END-IF
           END-PERFORM

           MOVE WS-GROSS-FLOW TO LNK-OUT-GROSS-AMOUNT

           IF WS-FLOW-A-TO-B > WS-FLOW-B-TO-A
               COMPUTE WS-NET-FLOW = WS-FLOW-A-TO-B - WS-FLOW-B-TO-A
               MOVE LNK-IN-PARTY-A-BIC TO LNK-OUT-NET-DEBTOR
               MOVE LNK-IN-PARTY-B-BIC TO LNK-OUT-NET-CREDITOR
               MOVE WS-NET-FLOW TO LNK-OUT-NET-AMOUNT
           ELSE
               IF WS-FLOW-B-TO-A > WS-FLOW-A-TO-B
                   COMPUTE WS-NET-FLOW = WS-FLOW-B-TO-A - WS-FLOW-A-TO-B
                   MOVE LNK-IN-PARTY-B-BIC TO LNK-OUT-NET-DEBTOR
                   MOVE LNK-IN-PARTY-A-BIC TO LNK-OUT-NET-CREDITOR
                   MOVE WS-NET-FLOW TO LNK-OUT-NET-AMOUNT
               ELSE
                   MOVE 0 TO LNK-OUT-NET-AMOUNT
                   MOVE SPACES TO LNK-OUT-NET-DEBTOR
                   MOVE SPACES TO LNK-OUT-NET-CREDITOR
               END-IF
           END-IF

           IF WS-GROSS-FLOW > 0
               COMPUTE WS-SAVINGS-AMT = WS-GROSS-FLOW - WS-NET-FLOW
               COMPUTE WS-SAVINGS-PCT ROUNDED = 
                   (WS-SAVINGS-AMT / WS-GROSS-FLOW) * 100.0000
               MOVE WS-SAVINGS-PCT TO LNK-OUT-SAVINGS-PCT
           END-IF

           GOBACK.
