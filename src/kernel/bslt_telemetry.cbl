       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-TELEMETRY.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - TELEMETRY AND MONITORING        *
      *> High-throughput metrics recorder, liquidity savings monitor,  *
      *> and latency distribution percentiles (P50, P90, P99).         *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "telemetry.cpy".

       01 WS-CALC-VARS.
          05 WS-SORTED-LAT OCCURS 1000 TIMES PIC 9(8) VALUE 0.
          05 WS-I                        PIC 9(4)     VALUE 0.
          05 WS-J                        PIC 9(4)     VALUE 0.
          05 WS-KEY                      PIC 9(8)     VALUE 0.
          05 WS-P50-IDX                  PIC 9(4)     VALUE 0.
          05 WS-P90-IDX                  PIC 9(4)     VALUE 0.
          05 WS-P99-IDX                  PIC 9(4)     VALUE 0.

       LINKAGE SECTION.
       01 LNK-TEL-OP                     PIC X(8).
       01 LNK-IN-LATENCY-US              PIC 9(8).
       01 LNK-IN-GROSS-DELTA             PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-NET-DELTA               PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-P50-US                 PIC 9(8).
       01 LNK-OUT-P90-US                 PIC 9(8).
       01 LNK-OUT-P99-US                 PIC 9(8).
       01 LNK-OUT-SAVINGS-PCT            PIC S9(3)V9(4)  COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-TEL-OP LNK-IN-LATENCY-US
                                LNK-IN-GROSS-DELTA LNK-IN-NET-DELTA
                                LNK-OUT-P50-US LNK-OUT-P90-US
                                LNK-OUT-P99-US LNK-OUT-SAVINGS-PCT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-TEL-OP
               WHEN "RECORD  "
                   PERFORM 1000-RECORD-METRIC
               WHEN "STATS   "
                   PERFORM 2000-COMPUTE-STATS
               WHEN "PRINT   "
                   PERFORM 3000-PRINT-SUMMARY
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-RECORD-METRIC.
           ADD 1 TO BS-TEL-ORDERS-TOTAL
           ADD 1 TO BS-TEL-ORDERS-CLEARED
           ADD LNK-IN-GROSS-DELTA TO BS-TEL-GROSS-NOTIONAL
           ADD LNK-IN-NET-DELTA   TO BS-TEL-NET-NOTIONAL

      *> Record latency sample in ring buffer
           IF BS-LAT-SAMPLE-COUNT < 1000
               ADD 1 TO BS-LAT-SAMPLE-COUNT
               MOVE LNK-IN-LATENCY-US TO BS-LAT-ENTRY(BS-LAT-SAMPLE-COUNT)
           END-IF

           IF LNK-IN-LATENCY-US < BS-LAT-MIN-US
               MOVE LNK-IN-LATENCY-US TO BS-LAT-MIN-US
           END-IF

           IF LNK-IN-LATENCY-US > BS-LAT-MAX-US
               MOVE LNK-IN-LATENCY-US TO BS-LAT-MAX-US
           END-IF

           ADD LNK-IN-LATENCY-US TO BS-LAT-SUM-US.

       2000-COMPUTE-STATS.
      *> Compute Liquidity Savings Percentage: (Gross - Net) / Gross * 100%
           IF BS-TEL-GROSS-NOTIONAL > 0
               COMPUTE BS-TEL-LIQUIDITY-SAVINGS = 
                   BS-TEL-GROSS-NOTIONAL - BS-TEL-NET-NOTIONAL
               COMPUTE BS-TEL-SAVINGS-PERCENT ROUNDED = 
                   (BS-TEL-LIQUIDITY-SAVINGS / BS-TEL-GROSS-NOTIONAL) * 100.0000
               MOVE BS-TEL-SAVINGS-PERCENT TO LNK-OUT-SAVINGS-PCT
           ELSE
               MOVE 0 TO LNK-OUT-SAVINGS-PCT
           END-IF

      *> Sort latency buffer to compute exact percentiles
           IF BS-LAT-SAMPLE-COUNT > 0
               PERFORM VARYING WS-I FROM 1 BY 1 
                       UNTIL WS-I > BS-LAT-SAMPLE-COUNT
                   MOVE BS-LAT-ENTRY(WS-I) TO WS-SORTED-LAT(WS-I)
               END-PERFORM

               PERFORM VARYING WS-I FROM 2 BY 1 
                       UNTIL WS-I > BS-LAT-SAMPLE-COUNT
                   MOVE WS-SORTED-LAT(WS-I) TO WS-KEY
                   COMPUTE WS-J = WS-I - 1
                   PERFORM UNTIL WS-J < 1 OR WS-SORTED-LAT(WS-J) <= WS-KEY
                       MOVE WS-SORTED-LAT(WS-J) TO WS-SORTED-LAT(WS-J + 1)
                       SUBTRACT 1 FROM WS-J
                   END-PERFORM
                   MOVE WS-KEY TO WS-SORTED-LAT(WS-J + 1)
               END-PERFORM

               COMPUTE WS-P50-IDX = (BS-LAT-SAMPLE-COUNT * 50) / 100
               COMPUTE WS-P90-IDX = (BS-LAT-SAMPLE-COUNT * 90) / 100
               COMPUTE WS-P99-IDX = (BS-LAT-SAMPLE-COUNT * 99) / 100
               IF WS-P50-IDX < 1 MOVE 1 TO WS-P50-IDX END-IF
               IF WS-P90-IDX < 1 MOVE 1 TO WS-P90-IDX END-IF
               IF WS-P99-IDX < 1 MOVE 1 TO WS-P99-IDX END-IF

               MOVE WS-SORTED-LAT(WS-P50-IDX) TO LNK-OUT-P50-US
               MOVE WS-SORTED-LAT(WS-P90-IDX) TO LNK-OUT-P90-US
               MOVE WS-SORTED-LAT(WS-P99-IDX) TO LNK-OUT-P99-US
           END-IF.

       3000-PRINT-SUMMARY.
           DISPLAY "+==================================================+"
           DISPLAY "|          BASALT CLEARINGHOUSE TELEMETRY          |"
           DISPLAY "+==================================================+"
           DISPLAY " Total Orders Processed : " BS-TEL-ORDERS-TOTAL
           DISPLAY " Total Orders Cleared   : " BS-TEL-ORDERS-CLEARED
           DISPLAY " Gross Notional Volume  : " BS-TEL-GROSS-NOTIONAL
           DISPLAY " Net Settled Volume     : " BS-TEL-NET-NOTIONAL
           DISPLAY " Liquidity Savings Pct  : " BS-TEL-SAVINGS-PERCENT "%"
           DISPLAY " Min Ingestion Latency  : " BS-LAT-MIN-US " us"
           DISPLAY " Max Ingestion Latency  : " BS-LAT-MAX-US " us"
           DISPLAY "+==================================================+".
