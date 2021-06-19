       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CLEARING-FACADE.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ENTERPRISE KERNEL FACADE         *
      *> Unified procedural facade routing high-level operations to     *
      *> underlying subsystems: Ledger, Netting, Risk, Storage, ACTUS.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "risk.cpy".
       COPY "graph.cpy".

       01 WS-FACADE-STATE.
          05 WS-CHK-DIRTY-COUNT          PIC 9(4)  VALUE 0.
          05 WS-CHK-ACTIVE-TX            PIC 9(4)  VALUE 0.
          05 WS-CHK-LSN                  PIC 9(18) VALUE 1048576.
          05 WS-SYS-STATUS               PIC 9(4)  VALUE 0.
          05 WS-CALL-ACC-ID              PIC X(16) VALUE SPACES.
          05 WS-CALL-BIC                 PIC X(11) VALUE SPACES.
          05 WS-CALL-CCY                 PIC X(3)  VALUE "USD".
          05 WS-CALL-TYPE                PIC 9(2)  VALUE 1.
          05 WS-CALL-AMT                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-LIMIT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-OUT-ACC             PIC X(256) VALUE SPACES.
          05 WS-NODES                    PIC 9(4)  VALUE 0.
          05 WS-EDGES                    PIC 9(6)  VALUE 0.
          05 WS-CYCLES                   PIC 9(4)  VALUE 0.
          05 WS-VOL                      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-MARGIN-ABS            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-FUND-ABS              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-SITG-ABS              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-MUTUAL-ABS            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-ASSESS-CALLED         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-VMGH-REQ              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-WF-POSTED-MRG            PIC S9(18)V9(8) COMP-3 VALUE 50000000.00000000.
          05 WS-WF-POSTED-DEF            PIC S9(18)V9(8) COMP-3 VALUE 10000000.00000000.

       LINKAGE SECTION.
       01 LNK-FACADE-OP                  PIC X(12).
       01 LNK-FACADE-PAYLOAD             PIC X(1024).
       01 LNK-FACADE-AMOUNT              PIC S9(18)V9(8) COMP-3.
       01 LNK-FACADE-RESULT              PIC S9(18)V9(8) COMP-3.
       01 LNK-FACADE-STATUS              PIC 9(4).

       PROCEDURE DIVISION USING LNK-FACADE-OP LNK-FACADE-PAYLOAD
                                LNK-FACADE-AMOUNT LNK-FACADE-RESULT
                                LNK-FACADE-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-FACADE-STATUS
           MOVE 0 TO LNK-FACADE-RESULT

           EVALUATE LNK-FACADE-OP
               WHEN "ACC-CREATE  "
                   PERFORM 1000-HANDLE-ACCOUNT-CREATE
               WHEN "ACC-GET     "
                   PERFORM 1100-HANDLE-ACCOUNT-GET
               WHEN "NET-CYCLES  "
                   PERFORM 2000-HANDLE-NETTING
               WHEN "RISK-SPAN   "
                   PERFORM 3000-HANDLE-RISK-SPAN
               WHEN "RISK-WFALL  "
                   PERFORM 3100-HANDLE-WATERFALL
               WHEN "STORAGE-CHK "
                   PERFORM 4000-HANDLE-CHECKPOINT
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-FACADE-STATUS
           END-EVALUATE

           GOBACK.

       1000-HANDLE-ACCOUNT-CREATE.
           MOVE LNK-FACADE-PAYLOAD(1:16)  TO WS-CALL-ACC-ID
           MOVE LNK-FACADE-PAYLOAD(17:11) TO WS-CALL-BIC
           MOVE LNK-FACADE-PAYLOAD(28:3)  TO WS-CALL-CCY
           MOVE 1                         TO WS-CALL-TYPE
           MOVE 0                         TO WS-CALL-AMT
           MOVE LNK-FACADE-AMOUNT         TO WS-CALL-LIMIT

           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         WS-CALL-ACC-ID
                                         WS-CALL-BIC
                                         WS-CALL-CCY
                                         WS-CALL-TYPE
                                         WS-CALL-AMT
                                         WS-CALL-LIMIT
                                         WS-CALL-OUT-ACC
                                         LNK-FACADE-STATUS.

       1100-HANDLE-ACCOUNT-GET.
           MOVE LNK-FACADE-PAYLOAD(1:16)  TO WS-CALL-ACC-ID
           CALL "BSLT-ACCOUNT-MGR" USING "GET     "
                                         WS-CALL-ACC-ID
                                         WS-CALL-BIC
                                         WS-CALL-CCY
                                         WS-CALL-TYPE
                                         WS-CALL-AMT
                                         WS-CALL-LIMIT
                                         WS-CALL-OUT-ACC
                                         LNK-FACADE-STATUS
           IF LNK-FACADE-STATUS = BS-RC-OK
               MOVE WS-CALL-OUT-ACC TO BS-ACCOUNT-RECORD
               MOVE BS-ACC-SETTLED-BAL TO LNK-FACADE-RESULT
           END-IF.

       2000-HANDLE-NETTING.
           COMPUTE WS-NODES = FUNCTION NUMVAL(LNK-FACADE-PAYLOAD(1:4))
           COMPUTE WS-EDGES = FUNCTION NUMVAL(LNK-FACADE-PAYLOAD(5:6))
           IF WS-NODES = 0 MOVE 10 TO WS-NODES END-IF
           IF WS-EDGES = 0 MOVE 25 TO WS-EDGES END-IF

           CALL "BSLT-CYCLE-CANCELLER" USING WS-NODES
                                             WS-EDGES
                                             WS-CYCLES
                                             WS-VOL
                                             LNK-FACADE-STATUS
           MOVE WS-VOL TO LNK-FACADE-RESULT.

       3000-HANDLE-RISK-SPAN.
      *> Calculates base portfolio margin
           COMPUTE LNK-FACADE-RESULT ROUNDED = LNK-FACADE-AMOUNT * 0.02500000.

       3100-HANDLE-WATERFALL.
      *> Evaluates default waterfall loss absorption
           MOVE LNK-FACADE-PAYLOAD(1:11) TO WS-CALL-BIC
           CALL "BSLT-LIQUIDITY-WATERFALL" USING "RESOLVE "
                                                 WS-CALL-BIC
                                                 LNK-FACADE-AMOUNT
                                                 WS-WF-POSTED-MRG
                                                 WS-WF-POSTED-DEF
                                                 WS-WF-MARGIN-ABS
                                                 WS-WF-FUND-ABS
                                                 WS-WF-SITG-ABS
                                                 WS-WF-MUTUAL-ABS
                                                 WS-WF-ASSESS-CALLED
                                                 WS-WF-VMGH-REQ
                                                 LNK-FACADE-RESULT
                                                 WS-CYCLES
                                                 LNK-FACADE-STATUS.

       4000-HANDLE-CHECKPOINT.
           CALL "BSLT-CHECKPOINT" USING "FLUSH   "
                                        WS-CHK-LSN
                                        WS-CHK-DIRTY-COUNT
                                        WS-CHK-ACTIVE-TX
                                        LNK-FACADE-STATUS.
