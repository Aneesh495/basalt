      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - COMMON DEFINITIONS               *
      *> System constants, return codes, and global status fields       *
      *>================================================================*
       01 BS-COMMON-CONSTANTS.
          05 BS-MAX-ACCOUNTS             PIC 9(6)  VALUE 10000.
          05 BS-MAX-ENTRIES              PIC 9(8)  VALUE 1000000.
          05 BS-MAX-ORDERS               PIC 9(6)  VALUE 50000.
          05 BS-MAX-GRAPH-NODES          PIC 9(4)  VALUE 128.
          05 BS-MAX-GRAPH-EDGES          PIC 9(6)  VALUE 2048.
          05 BS-MAX-CYCLES               PIC 9(4)  VALUE 256.
          05 BS-MAX-CYCLE-LEN            PIC 9(3)  VALUE 32.
          05 BS-PAGE-SIZE                PIC 9(4)  VALUE 4096.
          05 BS-BUFFER-POOL-PAGES        PIC 9(4)  VALUE 256.
          05 BS-MAX-BTREE-KEYS           PIC 9(3)  VALUE 32.
          05 BS-MAX-CONTRACTS            PIC 9(4)  VALUE 1000.
          05 BS-MAX-SCENARIOS            PIC 9(2)  VALUE 16.
          05 BS-HASH-SIZE                PIC 9(2)  VALUE 32.
          05 BS-HEX-SIZE                 PIC 9(2)  VALUE 64.

       01 BS-RETURN-CODES.
          05 BS-RC-OK                    PIC 9(4)  VALUE 0.
          05 BS-RC-NOT-FOUND             PIC 9(4)  VALUE 1001.
          05 BS-RC-DUPLICATE             PIC 9(4)  VALUE 1002.
          05 BS-RC-INSUFFICIENT-FUNDS    PIC 9(4)  VALUE 1003.
          05 BS-RC-INVALID-AMOUNT        PIC 9(4)  VALUE 1004.
          05 BS-RC-INVALID-STATE         PIC 9(4)  VALUE 1005.
          05 BS-RC-UNBALANCED-ENTRY      PIC 9(4)  VALUE 1006.
          05 BS-RC-CYCLE-NOT-FOUND       PIC 9(4)  VALUE 2001.
          05 BS-RC-GRIDLOCK-UNRESOLVED   PIC 9(4)  VALUE 2002.
          05 BS-RC-MARGIN-BREACH         PIC 9(4)  VALUE 3001.
          05 BS-RC-HAIRCUT-FAILED        PIC 9(4)  VALUE 3002.
          05 BS-RC-PAGE-CORRUPT          PIC 9(4)  VALUE 4001.
          05 BS-RC-PAGE-FULL             PIC 9(4)  VALUE 4002.
          05 BS-RC-RECOVERY-FAILED       PIC 9(4)  VALUE 4003.
          05 BS-RC-WAL-CORRUPT           PIC 9(4)  VALUE 4004.
          05 BS-RC-MERKLE-INVALID        PIC 9(4)  VALUE 5001.
          05 BS-RC-PARSE-ERROR           PIC 9(4)  VALUE 6001.
          05 BS-RC-CHECKSUM-MISMATCH     PIC 9(4)  VALUE 6002.
          05 BS-RC-BUFFER-OVERFLOW       PIC 9(4)  VALUE 7001.
          05 BS-RC-MATH-OVERFLOW         PIC 9(4)  VALUE 8001.
          05 BS-RC-DIVISION-BY-ZERO      PIC 9(4)  VALUE 8002.

       01 BS-GLOBAL-STATUS.
          05 BS-STATUS-CODE              PIC 9(4)  VALUE 0.
          05 BS-STATUS-MESSAGE           PIC X(80) VALUE SPACES.
          05 BS-CURRENT-TIMESTAMP.
             10 BS-TS-YYYYMMDD           PIC 9(8)  VALUE 0.
             10 BS-TS-HHMMSS             PIC 9(6)  VALUE 0.
             10 BS-TS-MILLIS             PIC 9(4)  VALUE 0.

       01 BS-SYSTEM-TIME-STATE.
          05 BS-SYS-CURRENT-LSN          PIC 9(18) VALUE 0.
          05 BS-SYS-FLUSHED-LSN          PIC 9(18) VALUE 0.
          05 BS-SYS-CHECKPOINT-LSN       PIC 9(18) VALUE 0.
          05 BS-SYS-BATCH-ID             PIC 9(12) VALUE 0.
          05 BS-SYS-CYCLE-ID             PIC 9(8)  VALUE 0.
          05 BS-SYS-TX-COUNTER           PIC 9(12) VALUE 0.
