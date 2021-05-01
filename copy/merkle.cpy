      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - CRYPTOGRAPHIC MERKLE TREE        *
      *> RFC 6962 tree accumulator, SHA-256 state, audit proofs         *
      *>================================================================*
       01 BS-SHA256-STATE.
          05 BS-SHA-H0                   PIC 9(10) VALUE 1779033703.
          05 BS-SHA-H1                   PIC 9(10) VALUE 3144134277.
          05 BS-SHA-H2                   PIC 9(10) VALUE 1013904242.
          05 BS-SHA-H3                   PIC 9(10) VALUE 2773480762.
          05 BS-SHA-H4                   PIC 9(10) VALUE 1359893119.
          05 BS-SHA-H5                   PIC 9(10) VALUE 2600822924.
          05 BS-SHA-H6                   PIC 9(10) VALUE 528734635.
          05 BS-SHA-H7                   PIC 9(10) VALUE 1541459225.
          05 BS-SHA-MSG-LEN              PIC 9(8)  VALUE 0.
          05 BS-SHA-MSG-BUFFER           PIC X(4096) VALUE LOW-VALUES.
          05 BS-SHA-DIGEST-BIN           PIC X(32) VALUE LOW-VALUES.
          05 BS-SHA-DIGEST-HEX           PIC X(64) VALUE SPACES.

       01 BS-SHA256-SCHEDULE.
          05 BS-SHA-W OCCURS 64 TIMES INDEXED BY BS-SHA-WIDX.
             10 BS-SHA-W-VAL             PIC 9(10) VALUE 0.

       01 BS-MERKLE-TREE.
          05 BS-MKL-LEAF-COUNT           PIC 9(4)  VALUE 0.
          05 BS-MKL-NODE-COUNT           PIC 9(4)  VALUE 0.
          05 BS-MKL-ROOT-HASH            PIC X(32) VALUE LOW-VALUES.
          05 BS-MKL-ROOT-HEX             PIC X(64) VALUE SPACES.
          05 BS-MKL-NODES OCCURS 1024 TIMES INDEXED BY BS-MKL-NIDX.
             10 BS-MKL-NODE-ID           PIC 9(4).
             10 BS-MKL-LEVEL             PIC 9(2).
             10 BS-MKL-LEFT-CHILD        PIC 9(4).
             10 BS-MKL-RIGHT-CHILD       PIC 9(4).
             10 BS-MKL-HASH              PIC X(32).

       01 BS-MERKLE-PROOF.
          05 BS-PRF-LEAF-INDEX           PIC 9(4)  VALUE 0.
          05 BS-PRF-LEAF-HASH            PIC X(32) VALUE LOW-VALUES.
          05 BS-PRF-DEPTH                PIC 9(2)  VALUE 0.
          05 BS-PRF-STEPS OCCURS 16 TIMES INDEXED BY BS-PRF-SIDX.
             10 BS-PRF-SIBLING-HASH      PIC X(32).
             10 BS-PRF-DIRECTION         PIC 9(1).
                88 BS-PRF-SIBLING-LEFT   VALUE 1.
                88 BS-PRF-SIBLING-RIGHT  VALUE 2.
          05 BS-PRF-ROOT-TO-CHECK        PIC X(32) VALUE LOW-VALUES.
          05 BS-PRF-IS-VALID             PIC 9(1)  VALUE 0.
