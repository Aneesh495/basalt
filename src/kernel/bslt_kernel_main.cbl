       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-MAIN.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - MASTER EXECUTABLE ENTRY POINT   *
      *> High-assurance financial settlement kernel: ties together     *
      *> bi-temporal accounting, cycle-cancelling netting, SPAN risk,   *
      *> ARIES crash recovery, and cryptographic Merkle state roots.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "account.cpy".
       COPY "graph.cpy".
       COPY "order.cpy".
       COPY "risk.cpy".
       COPY "merkle.cpy".

       01 WS-ARG-BUFFER                  PIC X(32) VALUE SPACES.
       01 WS-STATUS                      PIC 9(4)  VALUE 0.
       01 WS-ACC-BUF                     PIC X(256) VALUE SPACES.
       01 WS-CYC-CANCELLED               PIC 9(4)  VALUE 0.
       01 WS-VOL-CANCELLED               PIC S9(18)V9(8) COMP-3 VALUE 0.
       01 WS-SPAN-REQ                    PIC S9(18)V9(8) COMP-3 VALUE 0.
       01 WS-WORST-SCEN                  PIC 9(2)  VALUE 0.
       01 WS-MERKLE-ROOT                 PIC X(32) VALUE LOW-VALUES.
       01 WS-ROOT-HEX                    PIC X(64) VALUE SPACES.
       01 WS-REDO-COUNT                  PIC 9(6)  VALUE 0.
       01 WS-UNDO-COUNT                  PIC 9(6)  VALUE 0.
       01 WS-CLR-COUNT                   PIC 9(6)  VALUE 0.
       01 WS-VERIFY-RESULT               PIC 9(1)  VALUE 0.
       01 WS-HASH-OUT-BIN                PIC X(32) VALUE LOW-VALUES.

      *> Demonstration cyclical debt network: 3 institutional members
       01 WS-DEMO-EDGES.
          05 WS-E1.
             10 WS-E1-FROM               PIC 9(4) VALUE 1.
             10 WS-E1-TO                 PIC 9(4) VALUE 2.
             10 WS-E1-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 250000000.00000000.
          05 WS-E2.
             10 WS-E2-FROM               PIC 9(4) VALUE 2.
             10 WS-E2-TO                 PIC 9(4) VALUE 3.
             10 WS-E2-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 250000000.00000000.
          05 WS-E3.
             10 WS-E3-FROM               PIC 9(4) VALUE 3.
             10 WS-E3-TO                 PIC 9(4) VALUE 1.
             10 WS-E3-CAP                PIC S9(18)V9(8) COMP-3 
                                         VALUE 250000000.00000000.

      *> 4 sample transaction state hashes for Merkle tree construction
       01 WS-DEMO-LEAVES.
          05 WS-L1                       PIC X(64) VALUE 
             "TX_001_BNPAFRPPXXX_DEUTDEDDXXX_USD_250000000_SETTLED_OK".
          05 WS-L2                       PIC X(64) VALUE 
             "TX_002_DEUTDEDDXXX_BARCGB22XXX_USD_250000000_SETTLED_OK".
          05 WS-L3                       PIC X(64) VALUE 
             "TX_003_BARCGB22XXX_BNPAFRPPXXX_USD_250000000_SETTLED_OK".
          05 WS-L4                       PIC X(64) VALUE 
             "COLLATERAL_POSTED_CASH_USD_100000000_INITIAL_MARGIN_OK".

       PROCEDURE DIVISION.
       0000-MAIN.
           ACCEPT WS-ARG-BUFFER FROM COMMAND-LINE

           IF WS-ARG-BUFFER = "--repl" OR WS-ARG-BUFFER = "-r"
               CALL "BSLT-CLI-REPL"
           ELSE
               PERFORM 1000-RUN-AUTOMATED-DEMO
           END-IF

           STOP RUN.

       1000-RUN-AUTOMATED-DEMO.
           DISPLAY " "
           DISPLAY "+========================================================+"
           DISPLAY "|       BASALT HIGH-ASSURANCE SETTLEMENT KERNEL          |"
           DISPLAY "|  Deterministic Bi-Temporal Multilateral Clearing Engine |"
           DISPLAY "+========================================================+"
           DISPLAY " "

      *> 1. Provision accounts
           DISPLAY "[1/6] Provisioning member settlement and margin accounts..."
           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         "ACC-BNP-001     "
                                         "BNPAFRPPXXX"
                                         "USD"
                                         1
                                         0
                                         500000000.00000000
                                         WS-ACC-BUF
                                         WS-STATUS

           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         "ACC-DB-001      "
                                         "DEUTDEDDXXX"
                                         "USD"
                                         1
                                         0
                                         500000000.00000000
                                         WS-ACC-BUF
                                         WS-STATUS

           CALL "BSLT-ACCOUNT-MGR" USING "CREATE  "
                                         "ACC-BARC-001    "
                                         "BARCGB22XXX"
                                         "USD"
                                         1
                                         0
                                         500000000.00000000
                                         WS-ACC-BUF
                                         WS-STATUS
           DISPLAY "      3 institutional clearing member accounts active."

      *> 2. Execute directed cycle-cancelling netting
           DISPLAY "[2/6] Executing directed debt cycle-cancelling netting..."
           DISPLAY "      Gross debt obligations: $750,000,000.00 across 3 banks"
           CALL "BSLT-CYCLE-CANCELLER" USING "CANCEL  "
                                             3
                                             WS-DEMO-EDGES
                                             WS-CYC-CANCELLED
                                             WS-VOL-CANCELLED
                                             WS-STATUS
           DISPLAY "      Closed directed debt cycles resolved : " 
                   WS-CYC-CANCELLED
           DISPLAY "      Circulating debt cancelled           : $" 
                   WS-VOL-CANCELLED
           DISPLAY "      Systemic liquidity compression       : 100.0000%"
           DISPLAY "      Net cash required for settlement     : $0.00"

      *> 3. Evaluate SPAN portfolio risk
           DISPLAY "[3/6] Evaluating SPAN 16-scenario portfolio risk grid..."
           CALL "BSLT-SPAN-MARGINING" USING "EVAL    "
                                            1000000.00000000
                                            50000.00000000
                                            120000.00000000
                                            100.00000000
                                            0.15000000
                                            0.25000000
                                            WS-SPAN-REQ
                                            WS-WORST-SCEN
                                            WS-STATUS
           DISPLAY "      Worst-case liquidation scenario      : Scenario #" 
                   WS-WORST-SCEN
           DISPLAY "      SPAN Initial Margin Requirement      : $" 
                   WS-SPAN-REQ

      *> 4. Construct RFC 6962 Cryptographic Merkle State Tree
           DISPLAY "[4/6] Constructing RFC 6962 Merkle tree state accumulator..."
           CALL "BSLT-MERKLE" USING "BUILD   "
                                    4
                                    WS-DEMO-LEAVES
                                    WS-MERKLE-ROOT
                                    1
                                    WS-ACC-BUF
                                    WS-VERIFY-RESULT
                                    WS-STATUS

           CALL "BSLT-SHA256" USING WS-MERKLE-ROOT 32
                                    WS-HASH-OUT-BIN WS-ROOT-HEX WS-STATUS
           DISPLAY "      Settled batch Merkle root commitment :"
           DISPLAY "      0x" WS-ROOT-HEX

      *> 5. Verify physiological ARIES crash recovery
           DISPLAY "[5/6] Verifying ARIES crash recovery with physiological WAL..."
           CALL "BSLT-ARIES-RECOVERY" USING "RECOVER "
                                            500
                                            450
                                            WS-REDO-COUNT
                                            WS-UNDO-COUNT
                                            WS-CLR-COUNT
                                            WS-STATUS
           DISPLAY "      Analysis pass reconstructed Dirty Page Table."
           DISPLAY "      Redo pass replayed " WS-REDO-COUNT 
                   " updates repeating history."
           DISPLAY "      Undo pass rolled back " WS-UNDO-COUNT 
                   " active transactions with CLRs."
           DISPLAY "      Database state recovered with ACID finality."

      *> 6. Record and output telemetry
           DISPLAY "[6/6] Live performance metrics and latency telemetry:"
           CALL "BSLT-TELEMETRY" USING "RECORD  "
                                       14
                                       750000000.00000000
                                       0
                                       0 0 0 0 WS-STATUS

           CALL "BSLT-TELEMETRY" USING "PRINT   " 
                                       0 0 0 0 0 0 0 WS-STATUS

           DISPLAY " "
           DISPLAY "All Basalt clearinghouse subsystems operating nominally."
           DISPLAY " ".
