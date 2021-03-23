       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-DAYCOUNT.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ISDA DAY-COUNT ALGEBRA          *
      *> 30E/360, 30/360 ISDA, ACT/360, ACT/365, and ACT/ACT ICMA     *
      *> Exact Julian Day Number date differences and leap-year rules.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "daycount.cpy".

       01 WS-CALC-VARS.
          05 WS-Y1                       PIC 9(4) VALUE 0.
          05 WS-M1                       PIC 9(2) VALUE 0.
          05 WS-D1                       PIC 9(2) VALUE 0.
          05 WS-Y2                       PIC 9(4) VALUE 0.
          05 WS-M2                       PIC 9(2) VALUE 0.
          05 WS-D2                       PIC 9(2) VALUE 0.
          05 WS-ADJ-D1                   PIC 9(2) VALUE 0.
          05 WS-ADJ-D2                   PIC 9(2) VALUE 0.
          05 WS-JDN-1                    PIC 9(10) VALUE 0.
          05 WS-JDN-2                    PIC 9(10) VALUE 0.
          05 WS-DIFF-DAYS                PIC 9(6)  VALUE 0.
          05 WS-DIFF-DEC                 PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-DIVISOR                  PIC S9(18)V9(8) COMP-3 VALUE 360.00000000.
          05 WS-YEAR-FRAC                PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 WS-IS-LEAP-1                PIC 9(1) VALUE 0.
          05 WS-IS-LEAP-2                PIC 9(1) VALUE 0.

       LINKAGE SECTION.
       01 LNK-DC-CONVENTION              PIC 9(2).
       01 LNK-IN-START-DATE              PIC 9(8).
       01 LNK-IN-END-DATE                PIC 9(8).
       01 LNK-OUT-DAYS                   PIC 9(6).
       01 LNK-OUT-YEAR-FRACTION          PIC S9(3)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-DC-CONVENTION LNK-IN-START-DATE
                                LNK-IN-END-DATE LNK-OUT-DAYS
                                LNK-OUT-YEAR-FRACTION LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-DAYS
           MOVE 0 TO LNK-OUT-YEAR-FRACTION

           IF LNK-IN-END-DATE < LNK-IN-START-DATE
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> Deconstruct YYYYMMDD
           MOVE LNK-IN-START-DATE(1:4) TO WS-Y1
           MOVE LNK-IN-START-DATE(5:2) TO WS-M1
           MOVE LNK-IN-START-DATE(7:2) TO WS-D1
           MOVE LNK-IN-END-DATE(1:4)   TO WS-Y2
           MOVE LNK-IN-END-DATE(5:2)   TO WS-M2
           MOVE LNK-IN-END-DATE(7:2)   TO WS-D2

           EVALUATE LNK-DC-CONVENTION
               WHEN 1
      *> 30E/360 (Eurobond basis)
                   PERFORM 1000-CALC-30E-360
               WHEN 2
      *> 30/360 ISDA
                   PERFORM 2000-CALC-30-360-ISDA
               WHEN 3
      *> ACT/360
                   PERFORM 3000-CALC-ACT-360
               WHEN 4
      *> ACT/365 Fixed
                   PERFORM 4000-CALC-ACT-365
               WHEN 5
      *> ACT/ACT ICMA
                   PERFORM 5000-CALC-ACT-ACT
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           MOVE WS-DIFF-DAYS TO LNK-OUT-DAYS
           MOVE WS-YEAR-FRAC TO LNK-OUT-YEAR-FRACTION

           GOBACK.

       1000-CALC-30E-360.
           MOVE WS-D1 TO WS-ADJ-D1
           MOVE WS-D2 TO WS-ADJ-D2
           IF WS-ADJ-D1 = 31 MOVE 30 TO WS-ADJ-D1 END-IF
           IF WS-ADJ-D2 = 31 MOVE 30 TO WS-ADJ-D2 END-IF

           COMPUTE WS-DIFF-DAYS = 
               (360 * (WS-Y2 - WS-Y1)) + 
               (30 * (WS-M2 - WS-M1)) + 
               (WS-ADJ-D2 - WS-ADJ-D1)

           MOVE WS-DIFF-DAYS TO WS-DIFF-DEC
           MOVE 360.00000000 TO WS-DIVISOR
           DIVIDE WS-DIFF-DEC BY WS-DIVISOR GIVING WS-YEAR-FRAC ROUNDED.

       2000-CALC-30-360-ISDA.
           MOVE WS-D1 TO WS-ADJ-D1
           MOVE WS-D2 TO WS-ADJ-D2
           IF WS-ADJ-D1 = 31 MOVE 30 TO WS-ADJ-D1 END-IF
           IF WS-ADJ-D2 = 31 AND WS-ADJ-D1 = 30 MOVE 30 TO WS-ADJ-D2 END-IF

           COMPUTE WS-DIFF-DAYS = 
               (360 * (WS-Y2 - WS-Y1)) + 
               (30 * (WS-M2 - WS-M1)) + 
               (WS-ADJ-D2 - WS-ADJ-D1)

           MOVE WS-DIFF-DAYS TO WS-DIFF-DEC
           MOVE 360.00000000 TO WS-DIVISOR
           DIVIDE WS-DIFF-DEC BY WS-DIVISOR GIVING WS-YEAR-FRAC ROUNDED.

       3000-CALC-ACT-360.
           PERFORM 6000-COMPUTE-JDN
           COMPUTE WS-DIFF-DAYS = WS-JDN-2 - WS-JDN-1
           MOVE WS-DIFF-DAYS TO WS-DIFF-DEC
           MOVE 360.00000000 TO WS-DIVISOR
           DIVIDE WS-DIFF-DEC BY WS-DIVISOR GIVING WS-YEAR-FRAC ROUNDED.

       4000-CALC-ACT-365.
           PERFORM 6000-COMPUTE-JDN
           COMPUTE WS-DIFF-DAYS = WS-JDN-2 - WS-JDN-1
           MOVE WS-DIFF-DAYS TO WS-DIFF-DEC
           MOVE 365.00000000 TO WS-DIVISOR
           DIVIDE WS-DIFF-DEC BY WS-DIVISOR GIVING WS-YEAR-FRAC ROUNDED.

       5000-CALC-ACT-ACT.
           PERFORM 6000-COMPUTE-JDN
           COMPUTE WS-DIFF-DAYS = WS-JDN-2 - WS-JDN-1
           MOVE WS-DIFF-DAYS TO WS-DIFF-DEC

      *> Leap year check on start year: divisible by 4 and not 100, or 400
           IF (FUNCTION MOD(WS-Y1, 4) = 0 AND FUNCTION MOD(WS-Y1, 100) NOT = 0)
              OR FUNCTION MOD(WS-Y1, 400) = 0
               MOVE 366.00000000 TO WS-DIVISOR
           ELSE
               MOVE 365.00000000 TO WS-DIVISOR
           END-IF

           DIVIDE WS-DIFF-DEC BY WS-DIVISOR GIVING WS-YEAR-FRAC ROUNDED.

       6000-COMPUTE-JDN.
      *> Fliegel-Van Flandern Julian Day Number algorithm
           COMPUTE WS-JDN-1 = 
               (1461 * (WS-Y1 + 4800 + ((WS-M1 - 14) / 12))) / 4 + 
               (367 * (WS-M1 - 2 - 12 * ((WS-M1 - 14) / 12))) / 12 - 
               (3 * ((WS-Y1 + 4900 + ((WS-M1 - 14) / 12)) / 100)) / 4 + 
               WS-D1 - 32075

           COMPUTE WS-JDN-2 = 
               (1461 * (WS-Y2 + 4800 + ((WS-M2 - 14) / 12))) / 4 + 
               (367 * (WS-M2 - 2 - 12 * ((WS-M2 - 14) / 12))) / 12 - 
               (3 * ((WS-Y2 + 4900 + ((WS-M2 - 14) / 12)) / 100)) / 4 + 
               WS-D2 - 32075.
