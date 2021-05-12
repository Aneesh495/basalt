       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-CONTRACTS.
      *>================================================================*
      *> BASALT TEST SUITE - FINANCIAL CONTRACTS AND LIFECYCLES         *
      *> Verification of ACTUS contract types: Principal at Maturity    *
      *> (PAM bonds), Annuity (ANN loans), Interest Rate Swaps (IRS),   *
      *> FX Forwards (covered interest parity), and Credit Default Swaps*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "contract.cpy".
       COPY "cds.cpy".

      *> PAM working vars
       01 WS-PAM-VARS.
          05 WS-PAM-CID                  PIC X(16) VALUE "BOND-US-TREAS-01".
          05 WS-PAM-PRINCIPAL            PIC S9(18)V9(8) COMP-3 VALUE 1000000.00000000.
          05 WS-PAM-RATE                 PIC S9(3)V9(8)  COMP-3 VALUE 0.05000000.
          05 WS-PAM-DAYCOUNT             PIC 9(2)  VALUE 1.
          05 WS-PAM-FREQ                 PIC 9(2)  VALUE 6.
          05 WS-PAM-IED                  PIC 9(8)  VALUE 20260101.
          05 WS-PAM-MD                   PIC 9(8)  VALUE 20280101.
          05 WS-PAM-TOTAL-FLOWS          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-PAM-SCHED-COUNT          PIC 9(4)  VALUE 0.
          05 WS-PAM-STATUS               PIC 9(4)  VALUE 0.

      *> ANN working vars
       01 WS-ANN-VARS.
          05 WS-ANN-PRINCIPAL            PIC S9(18)V9(8) COMP-3 VALUE 120000.00000000.
          05 WS-ANN-RATE                 PIC S9(3)V9(8)  COMP-3 VALUE 0.06000000.
          05 WS-ANN-PERIODS              PIC 9(4)  VALUE 12.
          05 WS-ANN-START                PIC 9(8)  VALUE 20260101.
          05 WS-ANN-PERIODIC-PMT         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ANN-TOTAL-INT            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ANN-STATUS               PIC 9(4)  VALUE 0.

      *> IRS working vars
       01 WS-IRS-VARS.
          05 WS-IRS-NOTIONAL             PIC S9(18)V9(8) COMP-3 VALUE 10000000.00000000.
          05 WS-IRS-FIXED-RATE           PIC S9(3)V9(8)  COMP-3 VALUE 0.04000000.
          05 WS-IRS-FLOAT-INDEX          PIC S9(3)V9(8)  COMP-3 VALUE 0.03500000.
          05 WS-IRS-SPREAD               PIC S9(3)V9(8)  COMP-3 VALUE 0.00000000.
          05 WS-IRS-YEAR-FRAC            PIC S9(3)V9(8)  COMP-3 VALUE 0.50000000.
          05 WS-IRS-FIXED-LEG            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-IRS-FLOAT-LEG            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-IRS-NET-SETTLE           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-IRS-PAYER-DIR            PIC X(1)  VALUE SPACES.
          05 WS-IRS-STATUS               PIC 9(4)  VALUE 0.

      *> FX Forward working vars
       01 WS-FX-VARS.
          05 WS-FX-NOTIONAL              PIC S9(18)V9(8) COMP-3 VALUE 1000000.00000000.
          05 WS-FX-AGREED-RATE           PIC S9(5)V9(8)  COMP-3 VALUE 1.08000000.
          05 WS-FX-SPOT-RATE             PIC S9(5)V9(8)  COMP-3 VALUE 1.08500000.
          05 WS-FX-BASE-RATE             PIC S9(3)V9(8)  COMP-3 VALUE 0.03500000.
          05 WS-FX-QUOTE-RATE            PIC S9(3)V9(8)  COMP-3 VALUE 0.05000000.
          05 WS-FX-TIME-FRAC             PIC S9(3)V9(8)  COMP-3 VALUE 0.50000000.
          05 WS-FX-QUOTE-OBLIG           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FX-THEO-FWD              PIC S9(5)V9(8)  COMP-3 VALUE 0.
          05 WS-FX-MTM-VAL               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FX-STATUS                PIC 9(4)  VALUE 0.

      *> CDS working vars
       01 WS-CDS-TEST-VARS.
          05 WS-CDS-NOTIONAL             PIC S9(18)V9(8) COMP-3 VALUE 5000000.00000000.
          05 WS-CDS-COUPON-BPS           PIC 9(4)  VALUE 100.
          05 WS-CDS-YEAR-FRAC            PIC S9(3)V9(8)  COMP-3 VALUE 0.25000000.
          05 WS-CDS-EVENT                PIC 9(2)  VALUE 0.
          05 WS-CDS-AUCTION-PRICE        PIC S9(1)V9(4)  COMP-3 VALUE 0.
          05 WS-CDS-PREMIUM              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CDS-PAYOUT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CDS-NET                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-CDS-STATUS               PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: PAM Fixed Bond Schedule (2 years, semi-annual coupons)
      *> Principal: 1,000,000, Rate: 5%, 4 periods of 25,000 = 100,000 interest
      *> Total cashflow expected = 1,100,000
      *>----------------------------------------------------------------*
           CALL "BSLT-CONTRACT-PAM" USING "SCHEDULE" WS-PAM-CID
                                          WS-PAM-PRINCIPAL WS-PAM-RATE
                                          WS-PAM-DAYCOUNT WS-PAM-FREQ
                                          WS-PAM-IED WS-PAM-MD
                                          WS-PAM-TOTAL-FLOWS
                                          WS-PAM-SCHED-COUNT
                                          WS-PAM-STATUS
           IF WS-PAM-STATUS = BS-RC-OK AND WS-PAM-SCHED-COUNT = 4
              AND WS-PAM-TOTAL-FLOWS = 1100000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: PAM bond schedule test failed: " WS-PAM-TOTAL-FLOWS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: ANN Annuity loan level payments (120,000 over 12 periods)
      *>----------------------------------------------------------------*
           CALL "BSLT-CONTRACT-ANN" USING "SCHEDULE" WS-ANN-PRINCIPAL
                                          WS-ANN-RATE WS-ANN-PERIODS
                                          WS-ANN-START WS-ANN-PERIODIC-PMT
                                          WS-ANN-TOTAL-INT WS-ANN-STATUS
           IF WS-ANN-STATUS = BS-RC-OK AND WS-ANN-PERIODIC-PMT > 10000.00000000
              AND WS-ANN-TOTAL-INT > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ANN loan schedule test failed: " WS-ANN-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: IRS Fixed vs Float net settlement
      *> Notional: 10,000,000. Fixed: 4%, Float: 3.5%, Half-year (0.5)
      *> Fixed leg: 200,000. Float leg: 175,000. Net settlement: 25,000.
      *>----------------------------------------------------------------*
           CALL "BSLT-CONTRACT-IRS" USING "VALUATE " WS-IRS-NOTIONAL
                                          WS-IRS-FIXED-RATE WS-IRS-FLOAT-INDEX
                                          WS-IRS-SPREAD WS-IRS-YEAR-FRAC
                                          WS-IRS-FIXED-LEG WS-IRS-FLOAT-LEG
                                          WS-IRS-NET-SETTLE
                                          WS-IRS-PAYER-DIR WS-IRS-STATUS
           IF WS-IRS-STATUS = BS-RC-OK AND WS-IRS-FIXED-LEG = 200000.00000000
              AND WS-IRS-FLOAT-LEG = 175000.00000000
              AND WS-IRS-NET-SETTLE = 25000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: IRS valuation test failed: " WS-IRS-NET-SETTLE
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: FX Forward Valuation and Covered Interest Parity
      *> Notional: 1,000,000 EUR @ agreed 1.0800 -> 1,080,000 USD obligation
      *>----------------------------------------------------------------*
           CALL "BSLT-CONTRACT-FXFRWD" USING "VALUATE " WS-FX-NOTIONAL
                                             WS-FX-AGREED-RATE WS-FX-SPOT-RATE
                                             WS-FX-BASE-RATE WS-FX-QUOTE-RATE
                                             WS-FX-TIME-FRAC
                                             WS-FX-QUOTE-OBLIG
                                             WS-FX-THEO-FWD
                                             WS-FX-MTM-VAL WS-FX-STATUS
           IF WS-FX-STATUS = BS-RC-OK AND WS-FX-QUOTE-OBLIG = 1080000.00000000
              AND WS-FX-THEO-FWD > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: FX Forward valuation test failed: " WS-FX-QUOTE-OBLIG
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: CDS Standard Premium Accrual (No credit event)
      *> Notional: 5,000,000, Coupon: 100 bps (0.01), Quarter (0.25)
      *> Premium = 5,000,000 * 0.01 * 0.25 = 12,500. Payout = 0.
      *>----------------------------------------------------------------*
           MOVE 0 TO WS-CDS-EVENT WS-CDS-AUCTION-PRICE
           CALL "BSLT-CONTRACT-CDS" USING "SETTLE  " WS-CDS-NOTIONAL
                                          WS-CDS-COUPON-BPS WS-CDS-YEAR-FRAC
                                          WS-CDS-EVENT WS-CDS-AUCTION-PRICE
                                          WS-CDS-PREMIUM WS-CDS-PAYOUT
                                          WS-CDS-NET WS-CDS-STATUS
           IF WS-CDS-STATUS = BS-RC-OK AND WS-CDS-PREMIUM = 12500.00000000
              AND WS-CDS-PAYOUT = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: CDS premium accrual test failed: " WS-CDS-PREMIUM
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 6: CDS Credit Default Event and Auction Settlement
      *> Credit Event 1 (Bankruptcy), Final Auction Price = 0.40 (40%)
      *> Protection payout = 5,000,000 * (1 - 0.40) = 3,000,000.
      *>----------------------------------------------------------------*
           MOVE 1 TO WS-CDS-EVENT
           MOVE 0.4000 TO WS-CDS-AUCTION-PRICE
           CALL "BSLT-CONTRACT-CDS" USING "SETTLE  " WS-CDS-NOTIONAL
                                          WS-CDS-COUPON-BPS WS-CDS-YEAR-FRAC
                                          WS-CDS-EVENT WS-CDS-AUCTION-PRICE
                                          WS-CDS-PREMIUM WS-CDS-PAYOUT
                                          WS-CDS-NET WS-CDS-STATUS
           IF WS-CDS-STATUS = BS-RC-OK AND WS-CDS-PAYOUT = 3000000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: CDS credit event auction test failed: " WS-CDS-PAYOUT
           END-IF.

           GOBACK.
