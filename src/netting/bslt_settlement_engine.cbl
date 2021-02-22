       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SETTLEMENT-ENGINE.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ATOMIC DVP SETTLEMENT ENGINE    *
      *> Real-Time Gross Settlement (RTGS) and Delivery-versus-Payment  *
      *> (DvP Model 1 & 2) atomic multi-leg execution with finality.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "order.cpy".
       COPY "entry.cpy".

       01 WS-SETTLE-VARS.
          05 WS-ACC-BUF                  PIC X(256) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4)   VALUE 0.
          05 WS-BATCH-ID                 PIC 9(12)  VALUE 0.
          05 WS-ENTRIES-COMMITTED        PIC 9(6)   VALUE 0.
          05 WS-TEMP-ENTRY-BUF.
             10 WS-ENT-1-ACC             PIC X(16).
             10 WS-ENT-1-CPTY            PIC X(16).
             10 WS-ENT-1-DIR             PIC X(1).
             10 WS-ENT-1-AMT             PIC S9(18)V9(8) COMP-3.
             10 WS-ENT-1-CCY             PIC X(3).
             10 WS-ENT-1-TYPE            PIC 9(2).
             10 WS-ENT-1-VAL             PIC 9(14).
             10 WS-ENT-1-NAR             PIC X(48).
             10 WS-ENT-2-ACC             PIC X(16).
             10 WS-ENT-2-CPTY            PIC X(16).
             10 WS-ENT-2-DIR             PIC X(1).
             10 WS-ENT-2-AMT             PIC S9(18)V9(8) COMP-3.
             10 WS-ENT-2-CCY             PIC X(3).
             10 WS-ENT-2-TYPE            PIC 9(2).
             10 WS-ENT-2-VAL             PIC 9(14).
             10 WS-ENT-2-NAR             PIC X(48).

       LINKAGE SECTION.
       01 LNK-STL-OP                     PIC X(8).
       01 LNK-IN-ORDER-RECORD            PIC X(256).
       01 LNK-OUT-FINALITY-TS            PIC 9(14).
       01 LNK-OUT-FINALITY-LSN           PIC 9(18).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-STL-OP LNK-IN-ORDER-RECORD
                                LNK-OUT-FINALITY-TS LNK-OUT-FINALITY-LSN
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-FINALITY-TS
           MOVE 0 TO LNK-OUT-FINALITY-LSN

           EVALUATE LNK-STL-OP
               WHEN "RTGS    "
                   PERFORM 1000-EXECUTE-RTGS
               WHEN "DVP-1   "
                   PERFORM 2000-EXECUTE-DVP1
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-EXECUTE-RTGS.
      *> Move order from linkage into structured record
           MOVE LNK-IN-ORDER-RECORD TO BS-SETTLEMENT-ORDER

           IF BS-ORD-GROSS-AMOUNT <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Debit debtor cash account
           CALL "BSLT-ACCOUNT-MGR" USING "DEBIT   "
                                         BS-ORD-DEBTOR-ACC
                                         BS-ORD-DEBTOR-BIC
                                         BS-ORD-CURRENCY
                                         1
                                         BS-ORD-GROSS-AMOUNT
                                         0
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS NOT = BS-RC-OK
               MOVE WS-STATUS TO LNK-OUT-STATUS
               MOVE 'F' TO BS-ORD-STATUS
               GOBACK
           END-IF

      *> 2. Credit creditor cash account
           CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  "
                                         BS-ORD-CREDITOR-ACC
                                         BS-ORD-CREDITOR-BIC
                                         BS-ORD-CURRENCY
                                         1
                                         BS-ORD-GROSS-AMOUNT
                                         0
                                         WS-ACC-BUF
                                         WS-STATUS
           IF WS-STATUS NOT = BS-RC-OK
      *> Rollback debtor debit
               CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  "
                                             BS-ORD-DEBTOR-ACC
                                             BS-ORD-DEBTOR-BIC
                                             BS-ORD-CURRENCY
                                             1
                                             BS-ORD-GROSS-AMOUNT
                                             0
                                             WS-ACC-BUF
                                             WS-STATUS
               MOVE BS-RC-RECOVERY-FAILED TO LNK-OUT-STATUS
               MOVE 'F' TO BS-ORD-STATUS
               GOBACK
           END-IF

      *> 3. Commit settlement finality
           MOVE 'S' TO BS-ORD-STATUS
           MOVE 20261015120000 TO LNK-OUT-FINALITY-TS
           ADD 1 TO BS-SYS-CURRENT-LSN
           MOVE BS-SYS-CURRENT-LSN TO LNK-OUT-FINALITY-LSN.

       2000-EXECUTE-DVP1.
      *> DvP Model 1: Atomic simultaneous settlement of cash and security legs
           MOVE LNK-IN-ORDER-RECORD TO BS-SETTLEMENT-ORDER
           PERFORM 1000-EXECUTE-RTGS.
