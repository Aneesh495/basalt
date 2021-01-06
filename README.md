# basalt

Deterministic bi-temporal clearinghouse and central counterparty settlement kernel written in standard COBOL.

Basalt is a high-assurance financial settlement engine and clearinghouse core implemented from first principles in standard COBOL. It couples algorithmic debt resolution, bi-temporal double-entry accounting, real-time portfolio risk margining, physiological crash recovery, and cryptographic audit proofs into a unified high-throughput architecture.

```
                          +-------------------------------------------------------+
                          |              Financial Ingestion Layer                |
                          |      ISO 20022 (pacs/camt/pain)  |  FIX 4.4 / 5.0     |
                          +-------------------------------------------------------+
                                                     |
                                                     v
+---------------------------------------------------------------------------------------------------------+
|                                      Basalt Kernel Core Orchestrator                                    |
|                                                                                                         |
|   +--------------------------+  +--------------------------+  +-------------------------------------+   |
|   |   Bi-Temporal Ledger     |  |   Multilateral Netting   |  |        Portfolio Risk Engine        |   |
|   |                          |  |                          |  |                                     |   |
|   | * Valid-Time (AS-OF)     |  | * Directed Debt Graphs   |  | * 128-bit Fixed Decimal Math        |   |
|   | * System-Time (AS-AT)    |  | * Cycle-Cancelling Min   |  | * SPAN Multi-Scenario Shocks        |   |
|   | * Double-Entry Vouchers  |  | * Gridlock Resolution    |  | * Historical VaR (99% Confidence)   |   |
|   | * Retroactive Rewind     |  | * Atomic DvP Execution   |  | * Expected Shortfall (CVaR)         |   |
|   +--------------------------+  +--------------------------+  +-------------------------------------+   |
|                 |                             |                                  |                      |
|                 +-----------------------------+----------------------------------+                      |
|                                               |                                                         |
|                                               v                                                         |
|   +-------------------------------------------------------------------------------------------------+   |
|   |                              Storage, Indexing, and Recovery Layer                              |   |
|   |                                                                                                 |   |
|   | * Slotted Buffer Pool Manager with PageLSN / FlushedLSN Tracking                                |   |
|   | * In-Memory Slotted B+Tree Index with Range Cursor Traversal                                    |   |
|   | * Physiological ARIES WAL: Three-Pass Crash Recovery (Analysis, Redo, Undo with CLRs)           |   |
|   | * RFC 6962 Merkle Tree State Accumulator with Native COBOL SHA-256 Engine                       |   |
|   +-------------------------------------------------------------------------------------------------+   |
|                                               |                                                         |
|                                               v                                                         |
|   +-------------------------------------------------------------------------------------------------+   |
|   |                                ACTUS Contract Lifecycle Machine                                 |   |
|   |                                                                                                 |   |
|   | * ISDA Day-Count Algebra: 30E/360, 30/360, ACT/360, ACT/365, ACT/ACT                           |   |
|   | * Cash-Flow Engines: Fixed Bonds (PAM), Annuities (ANN), Swaps (IRS), FX Forwards               |   |
|   +-------------------------------------------------------------------------------------------------+   |
+---------------------------------------------------------------------------------------------------------+
```

## Architectural Highlights

### 1. Multilateral Cycle-Cancelling Netting
Rather than settling gross bilateral obligations requiring vast amounts of central bank liquidity, Basalt models interbank debt obligations as a directed capacity graph $G = (V, E)$. The engine detects closed debt cycles using cycle-finding traversals and cancels the minimum circulating capacity flow $\min_{e \in C} c(e)$ along each cycle. This resolves gridlock and eliminates gross debt across multi-party banking networks with zero cash movements.

### 2. Bi-Temporal Double-Entry Ledger
Financial ledgers require two orthogonal time dimensions:
- Valid Time: When the real-world economic event occurred (Trade Date, Value Date).
- Transaction Time: When the event was asserted into the clearinghouse database (System LSN).

Basalt provides native `QUERY-AS-OF` (valid-time balance reconstruction) and `QUERY-AS-AT` (system-time historical audit trail), supporting retrospective adjustments without mutating historical log records.

### 3. Precision Fixed-Point Math and Risk Margining
Floating-point IEEE-754 arithmetic introduces fractional cent rounding drift that is unacceptable in high-value settlement. Basalt enforces exact 128-bit packed decimal arithmetic (`PIC S9(18)V9(8) COMP-3`) for every financial calculation. The risk subsystem implements:
- Standard Portfolio Analysis of Risk (SPAN) 16-scenario grid evaluations.
- Historical Simulation Value-at-Risk (VaR) at 95% and 99% confidence intervals.
- Expected Shortfall (CVaR) for tail-risk exposure measurement.
- Multi-tier collateral haircut schedules.

### 4. Physiological ARIES Recovery
Basalt implements the gold standard of database recovery: C. Mohan's ARIES (Algorithm for Recovery and Isolation Exploiting Semantics). The engine maintains log sequence numbers (LSNs) across slotted memory pages, executing a complete three-pass recovery protocol upon crash restart:
- Analysis Pass: Scans the WAL forward from the latest checkpoint, reconstructing the Dirty Page Table (DPT) and Transaction Table.
- Redo Pass: Repeats history from the minimum `recLSN`, restoring both committed and uncommitted states to the exact crash point.
- Undo Pass: Reverses uncommitted loser transactions backward, writing Compensation Log Records (CLRs) to ensure crash idempotence during recovery.

### 5. Native COBOL Cryptographic State Tree
Basalt includes a fully conformant SHA-256 cryptographic hash implementation written natively in standard COBOL. It constructs an RFC 6962 Merkle tree over all settled transaction batches and account state nodes, producing compact audit inclusion proofs and tamper-evident state roots.

## Directory Structure

```
basalt/
  copy/          COBOL copybooks defining record layouts, schemas, and enums
  src/
    math/        128-bit fixed decimal math, SHA-256, Merkle tree, statistics
    ledger/      Bi-temporal accounts, double-entry journal, reconciliation
    netting/     Bilateral netting, cycle-cancelling, gridlock, DvP engine
    risk/        SPAN margining, Historical VaR, Expected Shortfall, haircuts
    storage/     Buffer pool, B+Tree index, ARIES WAL logger and recovery
    contracts/   ACTUS financial contracts (PAM, ANN, IRS, FXFRWD) and day-count
    messages/    ISO 20022 XML parser/serializer, FIX 4.4/5.0 engine
    kernel/      Kernel orchestrator, event bus, interactive REPL, telemetry
  tests/         Exhaustive test runner, subsystem verification, and fuzz harness
  c/             C-shared library bridge and API bindings
  python/        Python telemetry tools, visualization harness, and stress tests
  docs/          Formal specifications, mathematical models, and recovery proofs
  Makefile       Automated build and test harness
```

## Quick Start

### Prerequisites
- GnuCOBOL 3.x (`cobc`)
- C compiler (Clang or GCC)
- Python 3.8+ (for visualization and telemetry tools)

### Build and Test
```bash
# Build the core kernel and test runner
make

# Run the complete test suite
make test

# Run settlement and clearing benchmarks
make bench

# Launch interactive operator shell
./bin/basalt --repl
```
