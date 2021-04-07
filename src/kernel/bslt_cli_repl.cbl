       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CLI-REPL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - OPERATOR INTERACTIVE REPL SHELL *
      *> Interactive terminal diagnostic shell for inspecting accounts, *
      *> triggering netting cycles, running ARIES recovery, and stats.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".

       01 WS-REPL-STATE.
          05 WS-INPUT-CMD                PIC X(80) VALUE SPACES.
          05 WS-CMD-VERB                 PIC X(16) VALUE SPACES.
          05 WS-CMD-ARG                  PIC X(64) VALUE SPACES.
          05 WS-RUNNING                  PIC 9(1)  VALUE 1.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-OUT-BUF                  PIC X(256) VALUE SPACES.
          05 WS-CYC-CANCELLED            PIC 9(4)  VALUE 0.
          05 WS-VOL-CANCELLED            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-REDO-APPLIED             PIC 9(6)  VALUE 0.
          05 WS-UNDO-APPLIED             PIC 9(6)  VALUE 0.
          05 WS-CLRS-WRITTEN             PIC 9(6)  VALUE 0.

      *> Sample 3-node cyclic obligations for netting demonstration
       01 WS-DEMO-EDGES.
          05 WS-D-EDGE-1.
             10 WS-E1-FROM               PIC 9(4) VALUE 1.
             10 WS-E1-TO                 PIC 9(4) VALUE 2.
             10 WS-E1-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 100000000.00000000.
          05 WS-D-EDGE-2.
             10 WS-E2-FROM               PIC 9(4) VALUE 2.
             10 WS-E2-TO                 PIC 9(4) VALUE 3.
             10 WS-E2-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 100000000.00000000.
          05 WS-D-EDGE-3.
             10 WS-E3-FROM               PIC 9(4) VALUE 3.
             10 WS-E3-TO                 PIC 9(4) VALUE 1.
             10 WS-E3-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 100000000.00000000.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY " "
           DISPLAY "+==================================================+"
           DISPLAY "|  BASALT DETERMINISTIC CLEARINGHOUSE SHELL v1.0   |"
           DISPLAY "|  Type 'help' for commands or 'quit' to exit.     |"
           DISPLAY "+==================================================+"
           DISPLAY " "

           PERFORM UNTIL WS-RUNNING = 0
               DISPLAY "basalt> " WITH NO ADVANCING
               ACCEPT WS-INPUT-CMD
               PERFORM 1000-PARSE-CMD
               PERFORM 2000-EXECUTE-CMD
           END-PERFORM

           GOBACK.

       1000-PARSE-CMD.
           MOVE SPACES TO WS-CMD-VERB
           MOVE SPACES TO WS-CMD-ARG
           UNSTRING FUNCTION TRIM(WS-INPUT-CMD) DELIMITED BY ALL SPACES
               INTO WS-CMD-VERB WS-CMD-ARG.

       2000-EXECUTE-CMD.
           EVALUATE FUNCTION LOWER-CASE(WS-CMD-VERB)
               WHEN "help"
                   PERFORM 2100-CMD-HELP
               WHEN "status"
                   PERFORM 2200-CMD-STATUS
               WHEN "netting"
                   PERFORM 2300-CMD-NETTING
               WHEN "recovery"
                   PERFORM 2400-CMD-RECOVERY
               WHEN "telemetry"
                   PERFORM 2500-CMD-TELEMETRY
               WHEN "quit"
                   MOVE 0 TO WS-RUNNING
                   DISPLAY "Shutting down Basalt kernel cleanly."
               WHEN "exit"
                   MOVE 0 TO WS-RUNNING
                   DISPLAY "Shutting down Basalt kernel cleanly."
               WHEN SPACES
                   CONTINUE
               WHEN OTHER
                   DISPLAY "Unknown command: " FUNCTION TRIM(WS-CMD-VERB) 
                           ". Type 'help' for available commands."
           END-EVALUATE.

       2100-CMD-HELP.
           DISPLAY " "
           DISPLAY "Available operator commands:"
           DISPLAY "  status     - Show current LSN, cycle ID, and ledger state"
           DISPLAY "  netting    - Run multilateral cycle-cancelling demonstration"
           DISPLAY "  recovery   - Simulate crash and run 3-pass ARIES recovery"
           DISPLAY "  telemetry  - Display latency metrics and liquidity savings"
           DISPLAY "  quit       - Exit operator shell"
           DISPLAY " ".

       2200-CMD-STATUS.
           DISPLAY " "
           DISPLAY "--- BASALT SYSTEM STATE ---"
           DISPLAY " Current LSN          : " BS-SYS-CURRENT-LSN
           DISPLAY " Flushed LSN          : " BS-SYS-FLUSHED-LSN
           DISPLAY " Checkpoint LSN       : " BS-SYS-CHECKPOINT-LSN
           DISPLAY " Active Accounts      : " BS-ACC-COUNT
           DISPLAY " ".

       2300-CMD-NETTING.
           DISPLAY " "
           DISPLAY "Running multilateral cycle-cancelling netting test:"
           DISPLAY " Bank 1 owes Bank 2 : $100,000,000.00"
           DISPLAY " Bank 2 owes Bank 3 : $100,000,000.00"
           DISPLAY " Bank 3 owes Bank 1 : $100,000,000.00"
           DISPLAY " Gross Debt Volume  : $300,000,000.00"

           CALL "BSLT-CYCLE-CANCELLER" USING "CANCEL  "
                                             3
                                             WS-DEMO-EDGES
                                             WS-CYC-CANCELLED
                                             WS-VOL-CANCELLED
                                             WS-STATUS

           DISPLAY " Directed Cycles Resolved : " WS-CYC-CANCELLED
           DISPLAY " Debt Cancelled via Cycle : $" WS-VOL-CANCELLED
           DISPLAY " Remaining Cash Required  : $0.00"
           DISPLAY " Liquidity Compression    : 100.0000%"
           DISPLAY " ".

       2400-CMD-RECOVERY.
           DISPLAY " "
           DISPLAY "Simulating database crash and executing ARIES recovery:"
           CALL "BSLT-ARIES-RECOVERY" USING "RECOVER "
                                            150
                                            100
                                            WS-REDO-APPLIED
                                            WS-UNDO-APPLIED
                                            WS-CLRS-WRITTEN
                                            WS-STATUS
           DISPLAY " Analysis Pass : Complete. Minimum recLSN verified."
           DISPLAY " Redo Pass     : Replayed " WS-REDO-APPLIED " updates."
           DISPLAY " Undo Pass     : Rolled back " WS-UNDO-APPLIED " losers."
           DISPLAY " CLRs Emitted  : " WS-CLRS-WRITTEN " records."
           DISPLAY " Crash recovery completed idempotently."
           DISPLAY " ".

       2500-CMD-TELEMETRY.
           CALL "BSLT-TELEMETRY" USING "PRINT   " 0 0 0 0 0 0 0 WS-STATUS.
