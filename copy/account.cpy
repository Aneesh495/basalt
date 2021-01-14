      *================================================================*
      * BASALT CLEARINGHOUSE ENGINE - ACCOUNT SCHEMAS                  *
      * Bi-temporal account master records and in-memory tables        *
      *================================================================*
       01 BS-ACCOUNT-RECORD.
          05 BS-ACC-ID                   PIC X(16) VALUE SPACES.
          05 BS-ACC-OWNER-BIC            PIC X(11) VALUE SPACES.
          05 BS-ACC-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-ACC-TYPE                 PIC 9(2)  VALUE 1.
             88 BS-ACC-TYPE-SETTLEMENT   VALUE 1.
             88 BS-ACC-TYPE-CLEARING     VALUE 2.
             88 BS-ACC-TYPE-MARGIN       VALUE 3.
             88 BS-ACC-TYPE-COLLATERAL   VALUE 4.
             88 BS-ACC-TYPE-NOSTRO       VALUE 5.
             88 BS-ACC-TYPE-VOSTRO       VALUE 6.
          05 BS-ACC-STATUS               PIC X(1)  VALUE 'A'.
             88 BS-ACC-STAT-ACTIVE       VALUE 'A'.
             88 BS-ACC-STAT-SUSPENDED    VALUE 'S'.
             88 BS-ACC-STAT-FROZEN       VALUE 'F'.
             88 BS-ACC-STAT-CLOSED       VALUE 'C'.
          05 BS-ACC-SETTLED-BAL          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-PENDING-DEBIT        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-PENDING-CREDIT       PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-ENCUMBERED-MARGIN    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-AVAILABLE-BAL        PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-CREDIT-LIMIT         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ACC-VALID-FROM           PIC 9(14) VALUE 0.
          05 BS-ACC-VALID-TO             PIC 9(14) VALUE 99999999999999.
          05 BS-ACC-SYSTEM-FROM          PIC 9(14) VALUE 0.
          05 BS-ACC-SYSTEM-TO            PIC 9(14) VALUE 99999999999999.
          05 BS-ACC-LAST-LSN             PIC 9(18) VALUE 0.
          05 BS-ACC-ENTRY-COUNT          PIC 9(8)  VALUE 0.
          05 BS-ACC-STATE-HASH           PIC X(32) VALUE LOW-VALUES.

       01 BS-ACCOUNT-TABLE-STATE.
          05 BS-ACC-COUNT                PIC 9(6)  VALUE 0.
          05 BS-ACC-ENTRY OCCURS 10000 TIMES INDEXED BY BS-ACC-IDX.
             10 BS-TBL-ACC-ID            PIC X(16).
             10 BS-TBL-ACC-OWNER-BIC     PIC X(11).
             10 BS-TBL-ACC-CURRENCY      PIC X(3).
             10 BS-TBL-ACC-TYPE          PIC 9(2).
             10 BS-TBL-ACC-STATUS        PIC X(1).
             10 BS-TBL-ACC-SETTLED-BAL   PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-PENDING-DEB   PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-PENDING-CRE   PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-ENCUMBERED    PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-AVAILABLE     PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-CREDIT-LIMIT  PIC S9(18)V9(8) COMP-3.
             10 BS-TBL-ACC-VALID-FROM    PIC 9(14).
             10 BS-TBL-ACC-VALID-TO      PIC 9(14).
             10 BS-TBL-ACC-SYSTEM-FROM   PIC 9(14).
             10 BS-TBL-ACC-SYSTEM-TO     PIC 9(14).
             10 BS-TBL-ACC-LAST-LSN      PIC 9(18).
             10 BS-TBL-ACC-STATE-HASH    PIC X(32).
