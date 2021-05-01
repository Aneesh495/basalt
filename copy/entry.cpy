      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - JOURNAL ENTRY SCHEMAS            *
      *> Bi-temporal double-entry ledger records and query parameters   *
      *>================================================================*
       01 BS-JOURNAL-ENTRY.
          05 BS-ENT-ID                   PIC 9(12) VALUE 0.
          05 BS-ENT-BATCH-ID             PIC 9(12) VALUE 0.
          05 BS-ENT-TX-ID                PIC 9(12) VALUE 0.
          05 BS-ENT-ACCOUNT-ID           PIC X(16) VALUE SPACES.
          05 BS-ENT-COUNTERPARTY-ID      PIC X(16) VALUE SPACES.
          05 BS-ENT-DIRECTION            PIC X(1)  VALUE 'D'.
             88 BS-ENT-DIR-DEBIT         VALUE 'D'.
             88 BS-ENT-DIR-CREDIT        VALUE 'C'.
          05 BS-ENT-AMOUNT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ENT-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-ENT-TYPE                 PIC 9(2)  VALUE 1.
             88 BS-ENT-TYPE-SETTLEMENT   VALUE 1.
             88 BS-ENT-TYPE-FEE          VALUE 2.
             88 BS-ENT-TYPE-MARGIN       VALUE 3.
             88 BS-ENT-TYPE-ADJUSTMENT   VALUE 4.
             88 BS-ENT-TYPE-REVERSAL     VALUE 5.
             88 BS-ENT-TYPE-COUPON       VALUE 6.
          05 BS-ENT-VALID-FROM           PIC 9(14) VALUE 0.
          05 BS-ENT-VALID-TO             PIC 9(14) VALUE 99999999999999.
          05 BS-ENT-SYSTEM-FROM          PIC 9(14) VALUE 0.
          05 BS-ENT-SYSTEM-TO            PIC 9(14) VALUE 99999999999999.
          05 BS-ENT-PARENT-ID            PIC 9(12) VALUE 0.
          05 BS-ENT-LSN                  PIC 9(18) VALUE 0.
          05 BS-ENT-NARRATIVE            PIC X(48) VALUE SPACES.

       01 BS-JOURNAL-BATCH-HEADER.
          05 BS-BAT-ID                   PIC 9(12) VALUE 0.
          05 BS-BAT-CYCLE-ID             PIC 9(8)  VALUE 0.
          05 BS-BAT-ENTRY-COUNT          PIC 9(6)  VALUE 0.
          05 BS-BAT-TOTAL-DEBITS         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-BAT-TOTAL-CREDITS        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-BAT-NET-IMBALANCE        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-BAT-IS-BALANCED          PIC 9(1)  VALUE 0.

       01 BS-BITEMPORAL-QUERY-REQ.
          05 BS-QRY-ACCOUNT-ID           PIC X(16) VALUE SPACES.
          05 BS-QRY-AS-OF-VALID-TIME     PIC 9(14) VALUE 0.
          05 BS-QRY-AS-AT-SYSTEM-TIME    PIC 9(14) VALUE 0.
          05 BS-QRY-CURRENCY             PIC X(3)  VALUE "USD".

       01 BS-BITEMPORAL-QUERY-RESP.
          05 BS-QRY-RECONSTRUCTED-BAL    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-QRY-MATCHED-ENTRIES      PIC 9(6)  VALUE 0.
          05 BS-QRY-STATUS               PIC 9(4)  VALUE 0.
