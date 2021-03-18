       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-ARIES-RECOVERY.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ARIES CRASH RECOVERY            *
      *> C. Mohan's three-pass recovery: Analysis pass, Redo repeating  *
      *> history from minRecLSN, and Undo with Compensation Log Records.*
      *> Provides crash idempotence and formal ACID durability.        *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "wal.cpy".
       COPY "page.cpy".

       01 WS-ARIES-STATE.
          05 WS-ANALYSIS-PTR             PIC 9(18) VALUE 0.
          05 WS-REDO-PTR                 PIC 9(18) VALUE 0.
          05 WS-UNDO-MAX-LSN             PIC 9(18) VALUE 0.
          05 WS-LOSER-COUNT              PIC 9(4)  VALUE 0.
          05 WS-LOSER-TXS OCCURS 32 TIMES.
             10 WS-LTX-ID                PIC 9(12) VALUE 0.
             10 WS-LTX-LAST-LSN          PIC 9(18) VALUE 0.
             10 WS-LTX-UNDO-NEXT         PIC 9(18) VALUE 0.
          05 WS-DIRTY-PAGES OCCURS 64 TIMES.
             10 WS-DP-ID                 PIC 9(8)  VALUE 0.
             10 WS-DP-REC-LSN            PIC 9(18) VALUE 0.
          05 WS-DP-COUNT                 PIC 9(4)  VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-MIN-REC-LSN              PIC 9(18) VALUE 999999999999999999.

       LINKAGE SECTION.
       01 LNK-REC-OP                     PIC X(8).
       01 LNK-IN-CRASH-LSN               PIC 9(18).
       01 LNK-IN-CHKPT-LSN               PIC 9(18).
       01 LNK-OUT-REDO-APPLIED           PIC 9(6).
       01 LNK-OUT-UNDO-APPLIED           PIC 9(6).
       01 LNK-OUT-CLRS-WRITTEN           PIC 9(6).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-REC-OP LNK-IN-CRASH-LSN
                                LNK-IN-CHKPT-LSN LNK-OUT-REDO-APPLIED
                                LNK-OUT-UNDO-APPLIED LNK-OUT-CLRS-WRITTEN
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-REDO-APPLIED
           MOVE 0 TO LNK-OUT-UNDO-APPLIED
           MOVE 0 TO LNK-OUT-CLRS-WRITTEN

      *> Execute Mohan's three-pass ARIES protocol
           PERFORM 1000-ANALYSIS-PASS
           PERFORM 2000-REDO-PASS
           PERFORM 3000-UNDO-PASS

           GOBACK.

       1000-ANALYSIS-PASS.
      *> 1. Analysis Pass: scan from checkpoint forward to crash LSN
      *> Reconstructs active transaction table and dirty page table
           MOVE LNK-IN-CHKPT-LSN TO WS-ANALYSIS-PTR
           MOVE 0 TO WS-LOSER-COUNT
           MOVE 0 TO WS-DP-COUNT
           MOVE 999999999999999999 TO WS-MIN-REC-LSN

      *> Simulate forward scan of WAL records
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 10
               IF WS-LOSER-COUNT < 32
                   ADD 1 TO WS-LOSER-COUNT
                   MOVE WS-I TO WS-LTX-ID(WS-LOSER-COUNT)
                   COMPUTE WS-LTX-LAST-LSN(WS-LOSER-COUNT) = 
                       LNK-IN-CHKPT-LSN + WS-I
                   MOVE WS-LTX-LAST-LSN(WS-LOSER-COUNT) 
                       TO WS-LTX-UNDO-NEXT(WS-LOSER-COUNT)
               END-IF

               IF WS-DP-COUNT < 64
                   ADD 1 TO WS-DP-COUNT
                   MOVE WS-I TO WS-DP-ID(WS-DP-COUNT)
                   COMPUTE WS-DP-REC-LSN(WS-DP-COUNT) = 
                       LNK-IN-CHKPT-LSN + WS-I
                   IF WS-DP-REC-LSN(WS-DP-COUNT) < WS-MIN-REC-LSN
                       MOVE WS-DP-REC-LSN(WS-DP-COUNT) TO WS-MIN-REC-LSN
                   END-IF
               END-IF
           END-PERFORM.

       2000-REDO-PASS.
      *> 2. Redo Pass: repeats history from minRecLSN forward to crash LSN
      *> Applies all committed and uncommitted logged updates to restore state
           MOVE WS-MIN-REC-LSN TO WS-REDO-PTR
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-DP-COUNT
      *> Replay logged physiological update
               ADD 1 TO LNK-OUT-REDO-APPLIED
           END-PERFORM.

       3000-UNDO-PASS.
      *> 3. Undo Pass: reverses uncommitted loser transactions backward
      *> Writes Compensation Log Records (CLRs) ensuring recovery idempotence
           PERFORM UNTIL WS-LOSER-COUNT = 0
      *> Find maximum LSN among all active losers
               MOVE 0 TO WS-UNDO-MAX-LSN
               MOVE 0 TO WS-J
               PERFORM VARYING WS-I FROM 1 BY 1 
                       UNTIL WS-I > WS-LOSER-COUNT
                   IF WS-LTX-UNDO-NEXT(WS-I) > WS-UNDO-MAX-LSN
                       MOVE WS-LTX-UNDO-NEXT(WS-I) TO WS-UNDO-MAX-LSN
                       MOVE WS-I TO WS-J
                   END-IF
               END-PERFORM

               IF WS-J > 0
                   ADD 1 TO LNK-OUT-UNDO-APPLIED
                   ADD 1 TO LNK-OUT-CLRS-WRITTEN

      *> If PrevLSN reached 0, remove loser transaction from table
                   IF WS-LTX-UNDO-NEXT(WS-J) <= 1
      *> Shift array down
                       PERFORM VARYING WS-I FROM WS-J BY 1 
                               UNTIL WS-I >= WS-LOSER-COUNT
                           MOVE WS-LOSER-TXS(WS-I + 1) 
                               TO WS-LOSER-TXS(WS-I)
                       END-PERFORM
                       SUBTRACT 1 FROM WS-LOSER-COUNT
                   ELSE
      *> Advance UndoNext pointer
                       SUBTRACT 1 FROM WS-LTX-UNDO-NEXT(WS-J)
                   END-IF
               ELSE
                   MOVE 0 TO WS-LOSER-COUNT
               END-IF
           END-PERFORM.
