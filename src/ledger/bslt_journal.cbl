       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-JOURNAL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - DOUBLE-ENTRY JOURNAL ENGINE     *
      *> Append-only immutable journal, batch balancing invariant,     *
      *> atomic all-or-nothing multi-leg debit/credit execution.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "entry.cpy".

       01 WS-JOURNAL-STATE.
          05 WS-TOTAL-ENTRIES            PIC 9(8)  VALUE 0.
          05 WS-JOURNAL-STORE OCCURS 1000 TIMES INDEXED BY WS-JRN-IDX.
             10 WS-J-ID                  PIC 9(12).
             10 WS-J-BATCH-ID            PIC 9(12).
             10 WS-J-TX-ID               PIC 9(12).
             10 WS-J-ACC-ID              PIC X(16).
             10 WS-J-CPTY-ID             PIC X(16).
             10 WS-J-DIR                 PIC X(1).
             10 WS-J-AMT                 PIC S9(18)V9(8) COMP-3.
             10 WS-J-CCY                 PIC X(3).
             10 WS-J-TYPE                PIC 9(2).
             10 WS-J-VAL-FROM            PIC 9(14).
             10 WS-J-VAL-TO              PIC 9(14).
             10 WS-J-SYS-FROM            PIC 9(14).
             10 WS-J-SYS-TO              PIC 9(14).
             10 WS-J-PARENT-ID           PIC 9(12).
             10 WS-J-LSN                 PIC 9(18).
             10 WS-J-NARRATIVE           PIC X(48).

       01 WS-BATCH-CHECK-VARS.
          05 WS-SUM-DEBITS               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM-CREDITS              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-ACC-STATUS               PIC 9(4)  VALUE 0.
          05 WS-TEMP-ACC-BUF             PIC X(256) VALUE SPACES.

       LINKAGE SECTION.
       01 LNK-JRN-OP                     PIC X(8).
       01 LNK-IN-BATCH-ID                PIC 9(12).
       01 LNK-IN-BATCH-COUNT             PIC 9(4).
       01 LNK-IN-BATCH-ENTRIES.
          05 LNK-BATCH-ENTRY OCCURS 64 TIMES.
             10 LNK-B-ACC-ID             PIC X(16).
             10 LNK-B-CPTY-ID            PIC X(16).
             10 LNK-B-DIR                PIC X(1).
             10 LNK-B-AMT                PIC S9(18)V9(8) COMP-3.
             10 LNK-B-CCY                PIC X(3).
             10 LNK-B-TYPE               PIC 9(2).
             10 LNK-B-VAL-DATE           PIC 9(14).
             10 LNK-B-NARRATIVE          PIC X(48).
       01 LNK-OUT-ENTRIES-COMMITTED      PIC 9(6).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-JRN-OP LNK-IN-BATCH-ID
                                LNK-IN-BATCH-COUNT LNK-IN-BATCH-ENTRIES
                                LNK-OUT-ENTRIES-COMMITTED
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-ENTRIES-COMMITTED

           EVALUATE LNK-JRN-OP
               WHEN "POST    "
                   PERFORM 1000-POST-BATCH
               WHEN "COUNT   "
                   MOVE WS-TOTAL-ENTRIES TO LNK-OUT-ENTRIES-COMMITTED
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-POST-BATCH.
           IF LNK-IN-BATCH-COUNT = 0 OR LNK-IN-BATCH-COUNT > 64
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Verify double-entry balance invariant: sum(Debits) == sum(Credits)
           MOVE 0 TO WS-SUM-DEBITS
           MOVE 0 TO WS-SUM-CREDITS
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-BATCH-COUNT
               IF LNK-B-DIR(WS-I) = 'D'
                   ADD LNK-B-AMT(WS-I) TO WS-SUM-DEBITS
               ELSE
                   IF LNK-B-DIR(WS-I) = 'C'
                       ADD LNK-B-AMT(WS-I) TO WS-SUM-CREDITS
                   ELSE
                       MOVE BS-RC-UNBALANCED-ENTRY TO LNK-OUT-STATUS
                       GOBACK
                   END-IF
               END-IF
           END-PERFORM

           COMPUTE WS-DIFF = WS-SUM-DEBITS - WS-SUM-CREDITS
           IF WS-DIFF NOT = 0
               MOVE BS-RC-UNBALANCED-ENTRY TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 2. Execute debit/credit account balance updates
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-BATCH-COUNT
               IF LNK-B-DIR(WS-I) = 'D'
                   CALL "BSLT-ACCOUNT-MGR" USING "DEBIT   "
                                                 LNK-B-ACC-ID(WS-I)
                                                 SPACES
                                                 LNK-B-CCY(WS-I)
                                                 1
                                                 LNK-B-AMT(WS-I)
                                                 0
                                                 WS-TEMP-ACC-BUF
                                                 WS-ACC-STATUS
               ELSE
                   CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  "
                                                 LNK-B-ACC-ID(WS-I)
                                                 SPACES
                                                 LNK-B-CCY(WS-I)
                                                 1
                                                 LNK-B-AMT(WS-I)
                                                 0
                                                 WS-TEMP-ACC-BUF
                                                 WS-ACC-STATUS
               END-IF

               IF WS-ACC-STATUS NOT = BS-RC-OK
                   MOVE WS-ACC-STATUS TO LNK-OUT-STATUS
                   PERFORM 2000-ROLLBACK-BATCH
                   GOBACK
               END-IF
           END-PERFORM

      *> 3. Append to immutable journal store
           ADD 1 TO BS-SYS-CURRENT-LSN
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-BATCH-COUNT
               IF WS-TOTAL-ENTRIES < 1000
                   ADD 1 TO WS-TOTAL-ENTRIES
                   MOVE WS-TOTAL-ENTRIES TO WS-J-ID(WS-TOTAL-ENTRIES)
                   MOVE LNK-IN-BATCH-ID  TO WS-J-BATCH-ID(WS-TOTAL-ENTRIES)
                   MOVE LNK-IN-BATCH-ID  TO WS-J-TX-ID(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-ACC-ID(WS-I) TO WS-J-ACC-ID(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-CPTY-ID(WS-I) TO WS-J-CPTY-ID(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-DIR(WS-I)  TO WS-J-DIR(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-AMT(WS-I)  TO WS-J-AMT(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-CCY(WS-I)  TO WS-J-CCY(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-TYPE(WS-I) TO WS-J-TYPE(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-VAL-DATE(WS-I) TO WS-J-VAL-FROM(WS-TOTAL-ENTRIES)
                   MOVE 99999999999999   TO WS-J-VAL-TO(WS-TOTAL-ENTRIES)
                   MOVE 20260101000000   TO WS-J-SYS-FROM(WS-TOTAL-ENTRIES)
                   MOVE 99999999999999   TO WS-J-SYS-TO(WS-TOTAL-ENTRIES)
                   MOVE 0                TO WS-J-PARENT-ID(WS-TOTAL-ENTRIES)
                   MOVE BS-SYS-CURRENT-LSN TO WS-J-LSN(WS-TOTAL-ENTRIES)
                   MOVE LNK-B-NARRATIVE(WS-I) 
                       TO WS-J-NARRATIVE(WS-TOTAL-ENTRIES)
               END-IF
           END-PERFORM

           MOVE LNK-IN-BATCH-COUNT TO LNK-OUT-ENTRIES-COMMITTED.

       2000-ROLLBACK-BATCH.
      *> Revert previously applied account debits/credits in this failed batch
           SUBTRACT 1 FROM WS-I
           PERFORM UNTIL WS-I < 1
               IF LNK-B-DIR(WS-I) = 'D'
      *> Reverse debit by applying credit
                   CALL "BSLT-ACCOUNT-MGR" USING "CREDIT  "
                                                 LNK-B-ACC-ID(WS-I)
                                                 SPACES
                                                 LNK-B-CCY(WS-I)
                                                 1
                                                 LNK-B-AMT(WS-I)
                                                 0
                                                 WS-TEMP-ACC-BUF
                                                 WS-ACC-STATUS
               ELSE
      *> Reverse credit by applying debit
                   CALL "BSLT-ACCOUNT-MGR" USING "DEBIT   "
                                                 LNK-B-ACC-ID(WS-I)
                                                 SPACES
                                                 LNK-B-CCY(WS-I)
                                                 1
                                                 LNK-B-AMT(WS-I)
                                                 0
                                                 WS-TEMP-ACC-BUF
                                                 WS-ACC-STATUS
               END-IF
               SUBTRACT 1 FROM WS-I
           END-PERFORM.
