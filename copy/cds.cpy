      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - CREDIT DEFAULT SWAP (CDS)       *
      *> ISDA standard credit derivative definitions, reference entities*
      *> credit events, and auction cash settlement payoff structures.  *
      *>================================================================*
       01 BS-CDS-CONTRACT.
          05 BS-CDS-ID                   PIC X(16) VALUE SPACES.
          05 BS-CDS-REF-ENTITY           PIC X(11) VALUE SPACES.
          05 BS-CDS-REF-OBLIGATION-ISIN  PIC X(12) VALUE SPACES.
          05 BS-CDS-BUYER-BIC            PIC X(11) VALUE SPACES.
          05 BS-CDS-SELLER-BIC           PIC X(11) VALUE SPACES.
          05 BS-CDS-NOTIONAL             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-CDS-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-CDS-COUPON-BPS           PIC 9(4)  VALUE 100.
             88 BS-CDS-SPREAD-100        VALUE 100.
             88 BS-CDS-SPREAD-500        VALUE 500.
          05 BS-CDS-SENIORITY            PIC X(6)  VALUE "SNRFOR".
             88 BS-CDS-SENIOR-UNSEC      VALUE "SNRFOR".
             88 BS-CDS-SUBORDINATED      VALUE "SUBLAC".
          05 BS-CDS-STD-RECOVERY-RATE    PIC S9(1)V9(4) COMP-3 VALUE 0.4000.
          05 BS-CDS-AUCTION-FINAL-PRICE  PIC S9(1)V9(4) COMP-3 VALUE 0.0000.
          05 BS-CDS-CREDIT-EVENT-TYPE    PIC 9(2)  VALUE 0.
             88 BS-CDS-EVENT-NONE        VALUE 0.
             88 BS-CDS-EVENT-BANKRUPTCY  VALUE 1.
             88 BS-CDS-EVENT-FAILURE-PAY VALUE 2.
             88 BS-CDS-EVENT-RESTRUCT    VALUE 3.
             88 BS-CDS-EVENT-ACCEL       VALUE 4.
          05 BS-CDS-EVENT-DATE           PIC 9(8)  VALUE 0.
          05 BS-CDS-SETTLEMENT-AMOUNT    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-CDS-ACCRUED-PREMIUM      PIC S9(18)V9(8) COMP-3 VALUE 0.
