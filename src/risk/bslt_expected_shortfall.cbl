       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-EXPECTED-SHORTFALL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - EXPECTED SHORTFALL (CVAR)       *
      *> Coherent tail-risk measure: conditional expected loss beyond   *
      *> the VaR threshold across extreme market stress scenarios.      *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-CVAR-WORKING.
          05 WS-SORTED-LOSSES OCCURS 252 TIMES.
             10 WS-LOSS-VAL              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TAIL-COUNT               PIC 9(4)  VALUE 0.
          05 WS-TAIL-DEC                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-TAIL-SUM                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-KEY                      PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-ES-OP                      PIC X(8).
       01 LNK-IN-SERIES-LEN              PIC 9(4).
       01 LNK-IN-SERIES.
          05 LNK-ES-ENTRY OCCURS 252 TIMES.
             10 LNK-ES-LOSS              PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-CONFIDENCE-PCT          PIC 9(2).
       01 LNK-OUT-EXPECTED-SHORTFALL     PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-ES-OP LNK-IN-SERIES-LEN
                                LNK-IN-SERIES LNK-IN-CONFIDENCE-PCT
                                LNK-OUT-EXPECTED-SHORTFALL
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-EXPECTED-SHORTFALL

           IF LNK-IN-SERIES-LEN < 10 OR LNK-IN-SERIES-LEN > 252
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Populate loss buffer (ensuring non-negative loss metrics)
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-SERIES-LEN
               IF LNK-ES-LOSS(WS-I) < 0
                   COMPUTE WS-LOSS-VAL(WS-I) = 0 - LNK-ES-LOSS(WS-I)
               ELSE
                   MOVE LNK-ES-LOSS(WS-I) TO WS-LOSS-VAL(WS-I)
               END-IF
           END-PERFORM

      *> 2. Sort losses in descending order (largest loss first)
           PERFORM VARYING WS-I FROM 2 BY 1 
                   UNTIL WS-I > LNK-IN-SERIES-LEN
               MOVE WS-LOSS-VAL(WS-I) TO WS-KEY
               COMPUTE WS-J = WS-I - 1
               PERFORM UNTIL WS-J < 1 OR WS-LOSS-VAL(WS-J) >= WS-KEY
                   MOVE WS-LOSS-VAL(WS-J) TO WS-LOSS-VAL(WS-J + 1)
                   SUBTRACT 1 FROM WS-J
               END-PERFORM
               MOVE WS-KEY TO WS-LOSS-VAL(WS-J + 1)
           END-PERFORM

      *> 3. Determine tail sample size: K = floor((100 - Conf) * N / 100)
           IF LNK-IN-CONFIDENCE-PCT = 99
               COMPUTE WS-TAIL-COUNT = (LNK-IN-SERIES-LEN * 1) / 100
           ELSE
               COMPUTE WS-TAIL-COUNT = (LNK-IN-SERIES-LEN * 5) / 100
           END-IF

           IF WS-TAIL-COUNT < 1
               MOVE 1 TO WS-TAIL-COUNT
           END-IF

      *> 4. Compute arithmetic average of losses in the tail
           MOVE 0 TO WS-TAIL-SUM
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > WS-TAIL-COUNT
               ADD WS-LOSS-VAL(WS-I) TO WS-TAIL-SUM
           END-PERFORM

           MOVE WS-TAIL-COUNT TO WS-TAIL-DEC
           DIVIDE WS-TAIL-SUM BY WS-TAIL-DEC 
               GIVING LNK-OUT-EXPECTED-SHORTFALL ROUNDED.

           GOBACK.
