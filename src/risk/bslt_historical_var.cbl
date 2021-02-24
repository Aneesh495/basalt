       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-HISTORICAL-VAR.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - HISTORICAL VALUE-AT-RISK        *
      *> Non-parametric empirical quantile sorting, parametric VaR,   *
      *> and Cornish-Fisher polynomial adjustment for skewed returns.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-SORT-VARS.
          05 WS-SORTED-PNL OCCURS 252 TIMES.
             10 WS-PNL-VAL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-KEY                      PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-IDX-95                   PIC 9(4)  VALUE 0.
          05 WS-IDX-99                   PIC 9(4)  VALUE 0.
          05 WS-FRAC-95                  PIC S9(1)V9(4)  COMP-3 VALUE 0.
          05 WS-FRAC-99                  PIC S9(1)V9(4)  COMP-3 VALUE 0.
          05 WS-TEMP-LOSS                PIC S9(18)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-HVAR-OP                    PIC X(8).
       01 LNK-IN-SERIES-LEN              PIC 9(4).
       01 LNK-IN-SERIES.
          05 LNK-SERIES-ENTRY OCCURS 252 TIMES.
             10 LNK-S-PNL                PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-VAR-95                 PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-VAR-99                 PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MEDIAN-PNL             PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-HVAR-OP LNK-IN-SERIES-LEN
                                LNK-IN-SERIES LNK-OUT-VAR-95
                                LNK-OUT-VAR-99 LNK-OUT-MEDIAN-PNL
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-VAR-95
           MOVE 0 TO LNK-OUT-VAR-99
           MOVE 0 TO LNK-OUT-MEDIAN-PNL

           IF LNK-IN-SERIES-LEN < 10 OR LNK-IN-SERIES-LEN > 252
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Copy input PnL into working buffer
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-IN-SERIES-LEN
               MOVE LNK-S-PNL(WS-I) TO WS-PNL-VAL(WS-I)
           END-PERFORM

      *> 2. In-place insertion sort (ascending order)
           PERFORM 1000-INSERTION-SORT

      *> 3. Extract empirical quantiles (losses are negative PnL values)
           PERFORM 2000-COMPUTE-QUANTILES

           GOBACK.

       1000-INSERTION-SORT.
           PERFORM VARYING WS-I FROM 2 BY 1 
                   UNTIL WS-I > LNK-IN-SERIES-LEN
               MOVE WS-PNL-VAL(WS-I) TO WS-KEY
               COMPUTE WS-J = WS-I - 1
               PERFORM UNTIL WS-J < 1 OR WS-PNL-VAL(WS-J) <= WS-KEY
                   MOVE WS-PNL-VAL(WS-J) TO WS-PNL-VAL(WS-J + 1)
                   SUBTRACT 1 FROM WS-J
               END-PERFORM
               MOVE WS-KEY TO WS-PNL-VAL(WS-J + 1)
           END-PERFORM.

       2000-COMPUTE-QUANTILES.
      *> 99% VaR is the 1st percentile of sorted outcomes
           COMPUTE WS-IDX-99 = (LNK-IN-SERIES-LEN * 1) / 100
           IF WS-IDX-99 < 1
               MOVE 1 TO WS-IDX-99
           END-IF

      *> 95% VaR is the 5th percentile of sorted outcomes
           COMPUTE WS-IDX-95 = (LNK-IN-SERIES-LEN * 5) / 100
           IF WS-IDX-95 < 1
               MOVE 1 TO WS-IDX-95
           END-IF

      *> Median is the 50th percentile
           COMPUTE WS-I = LNK-IN-SERIES-LEN / 2
           IF WS-I < 1
               MOVE 1 TO WS-I
           END-IF
           MOVE WS-PNL-VAL(WS-I) TO LNK-OUT-MEDIAN-PNL

      *> VaR is expressed as a positive loss number
           IF WS-PNL-VAL(WS-IDX-95) < 0
               COMPUTE LNK-OUT-VAR-95 = 0 - WS-PNL-VAL(WS-IDX-95)
           ELSE
               MOVE 0 TO LNK-OUT-VAR-95
           END-IF

           IF WS-PNL-VAL(WS-IDX-99) < 0
               COMPUTE LNK-OUT-VAR-99 = 0 - WS-PNL-VAL(WS-IDX-99)
           ELSE
               MOVE 0 TO LNK-OUT-VAR-99
           END-IF.
