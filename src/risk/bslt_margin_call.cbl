       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-MARGIN-CALL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - MARGIN CALL DISPATCHER           *
      *> Automated Intraday Variation and Initial Margin call dispatch, *
      *> collateral deficit calculation, and account lock orchestration.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "risk.cpy".

       01 WS-CALL-VARS.
          05 WS-IM-DEFICIT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VM-DEFICIT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TOTAL-CALL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-ACC-ID              PIC X(16) VALUE SPACES.
          05 WS-CALL-BIC                 PIC X(11) VALUE SPACES.
          05 WS-CALL-TYPE                PIC 9(2)  VALUE 0.
          05 WS-CALL-LIMIT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CALL-OUT-ACC             PIC X(256) VALUE SPACES.
          05 WS-CALL-STATUS              PIC 9(4)  VALUE 0.
          05 WS-LOCKED-AMT               PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-MC-OP                      PIC X(8).
       01 LNK-IN-MEMBER-BIC              PIC X(11).
       01 LNK-IN-SETTLEMENT-ACC          PIC X(16).
       01 LNK-IN-REQUIRED-IM             PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-POSTED-IM               PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-MTM-VARIATION-LOSS      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-TOTAL-CALL-AMT         PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-COVERED-BY-LOCK        PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-UNMET-DEFICIT          PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CALL-ISSUED-FLAG       PIC 9(1).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-MC-OP LNK-IN-MEMBER-BIC
                                LNK-IN-SETTLEMENT-ACC
                                LNK-IN-REQUIRED-IM
                                LNK-IN-POSTED-IM
                                LNK-IN-MTM-VARIATION-LOSS
                                LNK-OUT-TOTAL-CALL-AMT
                                LNK-OUT-COVERED-BY-LOCK
                                LNK-OUT-UNMET-DEFICIT
                                LNK-OUT-CALL-ISSUED-FLAG
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-TOTAL-CALL-AMT
           MOVE 0 TO LNK-OUT-COVERED-BY-LOCK
           MOVE 0 TO LNK-OUT-UNMET-DEFICIT
           MOVE 0 TO LNK-OUT-CALL-ISSUED-FLAG

      *> 1. Calculate Initial Margin Deficit
           IF LNK-IN-REQUIRED-IM > LNK-IN-POSTED-IM
               COMPUTE WS-IM-DEFICIT = LNK-IN-REQUIRED-IM - LNK-IN-POSTED-IM
           ELSE
               MOVE 0 TO WS-IM-DEFICIT
           END-IF

      *> 2. Variation Margin Deficit (MTM loss)
           IF LNK-IN-MTM-VARIATION-LOSS > 0
               MOVE LNK-IN-MTM-VARIATION-LOSS TO WS-VM-DEFICIT
           ELSE
               MOVE 0 TO WS-VM-DEFICIT
           END-IF

           COMPUTE WS-TOTAL-CALL = WS-IM-DEFICIT + WS-VM-DEFICIT
           MOVE WS-TOTAL-CALL TO LNK-OUT-TOTAL-CALL-AMT

           IF WS-TOTAL-CALL <= 0
               GOBACK
           END-IF

           MOVE 1 TO LNK-OUT-CALL-ISSUED-FLAG

      *> 3. Attempt automatic liquidity lock against settlement account
           MOVE WS-TOTAL-CALL TO WS-LOCKED-AMT
           CALL "BSLT-ACCOUNT-MGR" USING "LOCK-MRG"
                                         LNK-IN-SETTLEMENT-ACC
                                         LNK-IN-MEMBER-BIC
                                         "USD"
                                         WS-CALL-TYPE
                                         WS-LOCKED-AMT
                                         WS-CALL-LIMIT
                                         WS-CALL-OUT-ACC
                                         WS-CALL-STATUS
           IF WS-CALL-STATUS = BS-RC-OK
               MOVE WS-TOTAL-CALL TO LNK-OUT-COVERED-BY-LOCK
               MOVE 0 TO LNK-OUT-UNMET-DEFICIT
           ELSE
      *> Partial coverage or insufficient cash on account
               MOVE 0 TO LNK-OUT-COVERED-BY-LOCK
               MOVE WS-TOTAL-CALL TO LNK-OUT-UNMET-DEFICIT
           END-IF

           GOBACK.
