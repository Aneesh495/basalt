      *================================================================*
      * BASALT CLEARINGHOUSE ENGINE - DIRECTED DEBT GRAPH SCHEMAS      *
      * Graph topology, adjacency matrix, cycle detection buffers      *
      *================================================================*
       01 BS-DEBT-GRAPH.
          05 BS-GRP-NODE-COUNT           PIC 9(4)  VALUE 0.
          05 BS-GRP-EDGE-COUNT           PIC 9(6)  VALUE 0.
          05 BS-GRP-CURRENCY             PIC X(3)  VALUE "USD".

          05 BS-GRP-NODES OCCURS 128 TIMES INDEXED BY BS-GRP-NIDX.
             10 BS-ND-BIC                PIC X(11) VALUE SPACES.
             10 BS-ND-ACTIVE             PIC 9(1)  VALUE 0.
             10 BS-ND-GROSS-INFLOW       PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-ND-GROSS-OUTFLOW      PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-ND-NET-POSITION       PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-ND-SETTLED-CASH       PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-ND-CREDIT-LIMIT       PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-ND-DEFICIT-FLAG       PIC 9(1)  VALUE 0.
             10 BS-ND-VISITED            PIC 9(1)  VALUE 0.
             10 BS-ND-ON-STACK           PIC 9(1)  VALUE 0.
             10 BS-ND-LOWLINK            PIC 9(4)  VALUE 0.
             10 BS-ND-DISC-TIME          PIC 9(4)  VALUE 0.
             10 BS-ND-PARENT             PIC 9(4)  VALUE 0.

          05 BS-GRP-ADJACENCY-ROW OCCURS 128 TIMES INDEXED BY BS-GRP-ROW.
             10 BS-GRP-ADJ-COL OCCURS 128 TIMES INDEXED BY BS-GRP-COL.
                15 BS-ADJ-CAPACITY       PIC S9(18)V9(8) COMP-3 VALUE 0.
                15 BS-ADJ-ORDER-COUNT    PIC 9(4)  VALUE 0.

       01 BS-CYCLE-BUFFER.
          05 BS-CYC-TOTAL-FOUND          PIC 9(4)  VALUE 0.
          05 BS-CYC-ENTRY OCCURS 256 TIMES INDEXED BY BS-CYC-IDX.
             10 BS-CYC-LEN               PIC 9(3)  VALUE 0.
             10 BS-CYC-MIN-CAPACITY      PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-CYC-STATUS            PIC 9(1)  VALUE 0.
             10 BS-CYC-NODES OCCURS 32 TIMES INDEXED BY BS-CYC-NIDX.
                15 BS-CYC-NODE-ID        PIC 9(4)  VALUE 0.

       01 BS-NETTING-METRICS.
          05 BS-NET-GROSS-OBLIGATIONS    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-NET-NET-OBLIGATIONS      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-NET-CANCELLED-VOLUME     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-NET-COMPRESSION-RATIO    PIC S9(3)V9(4)  COMP-3 VALUE 0.
          05 BS-NET-CYCLES-CANCELLED     PIC 9(4)  VALUE 0.
          05 BS-NET-GRIDLOCK-ROUNDS      PIC 9(3)  VALUE 0.
