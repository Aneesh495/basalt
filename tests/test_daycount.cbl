       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-DAYCOUNT.
      *>================================================================*
      *> BASALT TEST SUITE - ISDA DAY-COUNT CONVENTIONS                *
      *> Verification of 30E/360, 30/360 ISDA, ACT/360, ACT/365,      *
      *> ACT/ACT ICMA, Julian Day Numbers, and leap year handling.     *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "daycount.cpy".

       01 WS-DC-TEST-VARS.
          05 WS-CONVENTION               PIC 9(2)  VALUE 0.
          05 WS-START-DATE               PIC 9(8)  VALUE 0.
          05 WS-END-DATE                 PIC 9(8)  VALUE 0.
          05 WS-OUT-DAYS                 PIC 9(6)  VALUE 0.
          05 WS-OUT-YEAR-FRAC            PIC S9(3)V9(8) COMP-3 VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-DIFF                     PIC S9(3)V9(8) COMP-3 VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: 30E/360 Standard Half-Year (2026-01-01 to 2026-07-01)
      *> Exactly 6 months of 30 days = 180 days, fraction = 0.50000000
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-CONVENTION
           MOVE 20260101 TO WS-START-DATE
           MOVE 20260701 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-DAYS = 180
              AND WS-OUT-YEAR-FRAC = 0.50000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: 30E/360 half-year test failed: " WS-OUT-DAYS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: ACT/360 Money Market 90-day period (2026-01-01 to 2026-04-01)
      *> Jan: 31, Feb: 28, Mar: 31 -> Total 90 days. Frac = 90 / 360 = 0.25000000
      *>----------------------------------------------------------------*
           MOVE 3 TO WS-CONVENTION
           MOVE 20260101 TO WS-START-DATE
           MOVE 20260401 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-DAYS = 90
              AND WS-OUT-YEAR-FRAC = 0.25000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ACT/360 90-day test failed: " WS-OUT-DAYS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: ACT/365 British/Commonwealth (2026-01-01 to 2027-01-01)
      *> Non-leap year: 365 days -> Frac = 365 / 365 = 1.00000000
      *>----------------------------------------------------------------*
           MOVE 4 TO WS-CONVENTION
           MOVE 20260101 TO WS-START-DATE
           MOVE 20270101 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-DAYS = 365
              AND WS-OUT-YEAR-FRAC = 1.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ACT/365 full-year test failed: " WS-OUT-DAYS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Leap Year Detection (2024 Leap Year vs 2025 Normal Year)
      *> 2024-02-01 to 2024-03-01 should be 29 days (Leap Year)
      *>----------------------------------------------------------------*
           MOVE 3 TO WS-CONVENTION
           MOVE 20240201 TO WS-START-DATE
           MOVE 20240301 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-DAYS = 29
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Leap year 2024 February days failed: " WS-OUT-DAYS
           END-IF

      *> 2025-02-01 to 2025-03-01 should be 28 days (Non-Leap Year)
           MOVE 20250201 TO WS-START-DATE
           MOVE 20250301 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-OUT-DAYS = 28
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Non-leap year 2025 February days failed: " WS-OUT-DAYS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: ACT/ACT ICMA for full annual period
      *>----------------------------------------------------------------*
           MOVE 5 TO WS-CONVENTION
           MOVE 20260101 TO WS-START-DATE
           MOVE 20270101 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           COMPUTE WS-DIFF = WS-OUT-YEAR-FRAC - 1.00000000
           IF WS-DIFF < 0 COMPUTE WS-DIFF = 0 - WS-DIFF END-IF
           IF WS-STATUS = BS-RC-OK AND WS-DIFF < 0.00010000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ACT/ACT ICMA annual test failed: " WS-OUT-YEAR-FRAC
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: Invalid date range (end date prior to start date)
      *> Must reject with error status
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-CONVENTION
           MOVE 20260701 TO WS-START-DATE
           MOVE 20260101 TO WS-END-DATE
           CALL "BSLT-DAYCOUNT" USING WS-CONVENTION WS-START-DATE
                                      WS-END-DATE WS-OUT-DAYS
                                      WS-OUT-YEAR-FRAC WS-STATUS
           IF WS-STATUS = BS-RC-INVALID-AMOUNT
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: End date before start date should be rejected"
           END-IF.

           GOBACK.
