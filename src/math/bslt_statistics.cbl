       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-STATISTICS.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FINANCIAL STATISTICS             *
      *> Sample moments: mean, variance, skewness, excess kurtosis, and *
      *> Cornish-Fisher expansion for non-normal value-at-risk.         *
      *> All calculations performed in exact 128-bit packed decimal.    *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "risk.cpy".

       01 WS-STAT-INTERMEDIATES.
          05 WS-COUNT-DEC                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-COUNT-MINUS-1            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM-X                    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM-DIFF-SQ              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM-DIFF-CU              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SUM-DIFF-QU              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF                     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF-SQ                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF-CU                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIFF-QU                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-VARIANCE                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STDEV                    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MOMENT-3                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MOMENT-4                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STD-CUBE                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-STD-QUAD                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-I                        PIC 9(4)        VALUE 0.
          05 WS-MATH-STATUS              PIC 9(4)        VALUE 0.

      *> Cornish-Fisher expansion constants (z = 2.32634790 for 99%)
       01 WS-CF-CONSTANTS.
          05 WS-CF-Z99                   PIC S9(3)V9(8)  COMP-3 VALUE 2.32634790.
          05 WS-CF-Z-SQ                  PIC S9(3)V9(8)  COMP-3 VALUE 5.41189456.
          05 WS-CF-Z-CU                  PIC S9(5)V9(8)  COMP-3 VALUE 12.59015000.
          05 WS-CF-TERM-1                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-CF-TERM-2                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-CF-TERM-3                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-CF-Z-ADJUSTED            PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-SIX                      PIC S9(3)V9(8)  COMP-3 VALUE 6.00000000.
          05 WS-TWENTY-FOUR              PIC S9(3)V9(8)  COMP-3 VALUE 24.00000000.
          05 WS-THIRTY-SIX               PIC S9(3)V9(8)  COMP-3 VALUE 36.00000000.
          05 WS-THREE                    PIC S9(3)V9(8)  COMP-3 VALUE 3.00000000.

       LINKAGE SECTION.
       01 LNK-STAT-OP                    PIC X(8).
       01 LNK-STAT-COUNT                 PIC 9(4).
       01 LNK-STAT-SERIES.
          05 LNK-OBSERVATION OCCURS 252 TIMES.
             10 LNK-OBS-VAL              PIC S9(18)V9(8) COMP-3.
       01 LNK-STAT-MEAN                  PIC S9(18)V9(8) COMP-3.
       01 LNK-STAT-STDEV                 PIC S9(18)V9(8) COMP-3.
       01 LNK-STAT-SKEW                  PIC S9(3)V9(8)  COMP-3.
       01 LNK-STAT-KURT                  PIC S9(3)V9(8)  COMP-3.
       01 LNK-STAT-CF-QUANTILE           PIC S9(3)V9(8)  COMP-3.
       01 LNK-STAT-STATUS                PIC 9(4).

       PROCEDURE DIVISION USING LNK-STAT-OP LNK-STAT-COUNT
                                LNK-STAT-SERIES LNK-STAT-MEAN
                                LNK-STAT-STDEV LNK-STAT-SKEW
                                LNK-STAT-KURT LNK-STAT-CF-QUANTILE
                                LNK-STAT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-STAT-STATUS
           IF LNK-STAT-COUNT < 4
               MOVE BS-RC-INVALID-AMOUNT TO LNK-STAT-STATUS
               GOBACK
           END-IF

           PERFORM 1000-COMPUTE-MEAN
           PERFORM 2000-COMPUTE-VARIANCE
           PERFORM 3000-COMPUTE-MOMENTS
           PERFORM 4000-CORNISH-FISHER

           GOBACK.

       1000-COMPUTE-MEAN.
           MOVE 0 TO WS-SUM-X
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > LNK-STAT-COUNT
               ADD LNK-OBS-VAL(WS-I) TO WS-SUM-X
           END-PERFORM

           MOVE LNK-STAT-COUNT TO WS-COUNT-DEC
           DIVIDE WS-SUM-X BY WS-COUNT-DEC GIVING LNK-STAT-MEAN ROUNDED.

       2000-COMPUTE-VARIANCE.
           MOVE 0 TO WS-SUM-DIFF-SQ
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > LNK-STAT-COUNT
               COMPUTE WS-DIFF = LNK-OBS-VAL(WS-I) - LNK-STAT-MEAN
               COMPUTE WS-DIFF-SQ ROUNDED = WS-DIFF * WS-DIFF
               ADD WS-DIFF-SQ TO WS-SUM-DIFF-SQ
           END-PERFORM

           COMPUTE WS-COUNT-MINUS-1 = WS-COUNT-DEC - 1.00000000
           DIVIDE WS-SUM-DIFF-SQ BY WS-COUNT-MINUS-1 
               GIVING WS-VARIANCE ROUNDED

      *> Calculate standard deviation via fixed-math square root
           CALL "BSLT-FIXED-MATH" USING "SQRT    " WS-VARIANCE 0
                                        WS-STDEV WS-MATH-STATUS
           MOVE WS-STDEV TO LNK-STAT-STDEV.

       3000-COMPUTE-MOMENTS.
           IF WS-STDEV = 0
               MOVE 0 TO LNK-STAT-SKEW
               MOVE 0 TO LNK-STAT-KURT
               GOBACK
           END-IF

           MOVE 0 TO WS-SUM-DIFF-CU
           MOVE 0 TO WS-SUM-DIFF-QU
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > LNK-STAT-COUNT
               COMPUTE WS-DIFF = LNK-OBS-VAL(WS-I) - LNK-STAT-MEAN
               COMPUTE WS-DIFF-SQ ROUNDED = WS-DIFF * WS-DIFF
               COMPUTE WS-DIFF-CU ROUNDED = WS-DIFF-SQ * WS-DIFF
               COMPUTE WS-DIFF-QU ROUNDED = WS-DIFF-SQ * WS-DIFF-SQ
               ADD WS-DIFF-CU TO WS-SUM-DIFF-CU
               ADD WS-DIFF-QU TO WS-SUM-DIFF-QU
           END-PERFORM

           DIVIDE WS-SUM-DIFF-CU BY WS-COUNT-DEC GIVING WS-MOMENT-3 ROUNDED
           DIVIDE WS-SUM-DIFF-QU BY WS-COUNT-DEC GIVING WS-MOMENT-4 ROUNDED

           COMPUTE WS-STD-CUBE ROUNDED = WS-STDEV * WS-STDEV * WS-STDEV
           COMPUTE WS-STD-QUAD ROUNDED = WS-STDEV * WS-STDEV * 
                                         WS-STDEV * WS-STDEV

           IF WS-STD-CUBE > 0
               DIVIDE WS-MOMENT-3 BY WS-STD-CUBE 
                   GIVING LNK-STAT-SKEW ROUNDED
           ELSE
               MOVE 0 TO LNK-STAT-SKEW
           END-IF

           IF WS-STD-QUAD > 0
               COMPUTE LNK-STAT-KURT ROUNDED = 
                   (WS-MOMENT-4 / WS-STD-QUAD) - WS-THREE
           ELSE
               MOVE 0 TO LNK-STAT-KURT
           END-IF.

       4000-CORNISH-FISHER.
      *> Cornish-Fisher expansion adjusts normal quantile for skew and kurtosis
      *> z* = z + (S/6)*(z^2 - 1) + (K/24)*(z^3 - 3z) - (S^2/36)*(2z^3 - 5z)
           COMPUTE WS-CF-TERM-1 ROUNDED = 
               (LNK-STAT-SKEW / WS-SIX) * (WS-CF-Z-SQ - 1.00000000)

           COMPUTE WS-CF-TERM-2 ROUNDED = 
               (LNK-STAT-KURT / WS-TWENTY-FOUR) * 
               (WS-CF-Z-CU - (WS-THREE * WS-CF-Z99))

           COMPUTE WS-CF-TERM-3 ROUNDED = 
               ((LNK-STAT-SKEW * LNK-STAT-SKEW) / WS-THIRTY-SIX) * 
               ((2.00000000 * WS-CF-Z-CU) - (5.00000000 * WS-CF-Z99))

           COMPUTE WS-CF-Z-ADJUSTED ROUNDED = 
               WS-CF-Z99 + WS-CF-TERM-1 + WS-CF-TERM-2 - WS-CF-TERM-3

           MOVE WS-CF-Z-ADJUSTED TO LNK-STAT-CF-QUANTILE.
