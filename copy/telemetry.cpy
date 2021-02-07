      *================================================================*
      * BASALT CLEARINGHOUSE ENGINE - TELEMETRY AND METRICS            *
      * Performance counters, latency histograms, settlement savings   *
      *================================================================*
       01 BS-TELEMETRY-METRICS.
          05 BS-TEL-ORDERS-TOTAL         PIC 9(10) VALUE 0.
          05 BS-TEL-ORDERS-CLEARED       PIC 9(10) VALUE 0.
          05 BS-TEL-ORDERS-REJECTED      PIC 9(10) VALUE 0.
          05 BS-TEL-GROSS-NOTIONAL       PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-TEL-NET-NOTIONAL         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-TEL-LIQUIDITY-SAVINGS    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-TEL-SAVINGS-PERCENT      PIC S9(3)V9(4)  COMP-3 VALUE 0.
          05 BS-TEL-CYCLES-TOTAL         PIC 9(8)  VALUE 0.
          05 BS-TEL-CYCLES-RESOLVED      PIC 9(8)  VALUE 0.
          05 BS-TEL-GRIDLOCK-TOTAL       PIC 9(8)  VALUE 0.

       01 BS-WAL-TELEMETRY.
          05 BS-WTEL-RECORDS-WRITTEN     PIC 9(12) VALUE 0.
          05 BS-WTEL-BYTES-WRITTEN       PIC 9(14) VALUE 0.
          05 BS-WTEL-SYNC-FLUSHES        PIC 9(8)  VALUE 0.
          05 BS-WTEL-CHECKPOINTS         PIC 9(6)  VALUE 0.
          05 BS-WTEL-RECOVERY-TIME-MS    PIC 9(8)  VALUE 0.

       01 BS-LATENCY-RECORDER.
          05 BS-LAT-SAMPLE-COUNT         PIC 9(6)  VALUE 0.
          05 BS-LAT-MIN-US               PIC 9(8)  VALUE 99999999.
          05 BS-LAT-MAX-US               PIC 9(8)  VALUE 0.
          05 BS-LAT-SUM-US               PIC 9(12) VALUE 0.
          05 BS-LAT-MEAN-US              PIC 9(8)  VALUE 0.
          05 BS-LAT-P50-US               PIC 9(8)  VALUE 0.
          05 BS-LAT-P90-US               PIC 9(8)  VALUE 0.
          05 BS-LAT-P99-US               PIC 9(8)  VALUE 0.
          05 BS-LAT-BUFFER OCCURS 1000 TIMES INDEXED BY BS-LAT-IDX.
             10 BS-LAT-ENTRY             PIC 9(8)  VALUE 0.
