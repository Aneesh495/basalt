      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SETTLEMENT ORDER SCHEMAS         *
      *> Clearing obligations, trade orders, and settlement batches     *
      *>================================================================*
       01 BS-SETTLEMENT-ORDER.
          05 BS-ORD-ID                   PIC 9(12) VALUE 0.
          05 BS-ORD-CYCLE-ID             PIC 9(8)  VALUE 0.
          05 BS-ORD-DEBTOR-BIC           PIC X(11) VALUE SPACES.
          05 BS-ORD-CREDITOR-BIC         PIC X(11) VALUE SPACES.
          05 BS-ORD-DEBTOR-ACC           PIC X(16) VALUE SPACES.
          05 BS-ORD-CREDITOR-ACC         PIC X(16) VALUE SPACES.
          05 BS-ORD-ISIN                 PIC X(12) VALUE SPACES.
          05 BS-ORD-ASSET-TYPE           PIC 9(2)  VALUE 1.
             88 BS-ORD-ASSET-CASH        VALUE 1.
             88 BS-ORD-ASSET-GOVTBOND    VALUE 2.
             88 BS-ORD-ASSET-CORPBOND    VALUE 3.
             88 BS-ORD-ASSET-EQUITY      VALUE 4.
             88 BS-ORD-ASSET-DERIVATIVE  VALUE 5.
             88 BS-ORD-ASSET-FX          VALUE 6.
          05 BS-ORD-QUANTITY             PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ORD-UNIT-PRICE           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ORD-GROSS-AMOUNT         PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ORD-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-ORD-SETTLE-MODE          PIC 9(2)  VALUE 3.
             88 BS-ORD-MODE-RTGS         VALUE 1.
             88 BS-ORD-MODE-BILATERAL    VALUE 2.
             88 BS-ORD-MODE-MULTILATERAL VALUE 3.
             88 BS-ORD-MODE-DVP-1        VALUE 4.
             88 BS-ORD-MODE-DVP-2        VALUE 5.
          05 BS-ORD-PRIORITY             PIC 9(1)  VALUE 5.
          05 BS-ORD-STATUS               PIC X(1)  VALUE 'Q'.
             88 BS-ORD-STAT-QUEUED       VALUE 'Q'.
             88 BS-ORD-STAT-MATCHED      VALUE 'M'.
             88 BS-ORD-STAT-CLEARED      VALUE 'C'.
             88 BS-ORD-STAT-SETTLED      VALUE 'S'.
             88 BS-ORD-STAT-REJECTED     VALUE 'R'.
             88 BS-ORD-STAT-PARTIAL      VALUE 'P'.
          05 BS-ORD-ISD-DATE             PIC 9(8)  VALUE 0.
          05 BS-ORD-ASD-DATE             PIC 9(8)  VALUE 0.
          05 BS-ORD-EXTERNAL-REF         PIC X(32) VALUE SPACES.

       01 BS-ORDER-QUEUE-STATE.
          05 BS-ORD-QUEUE-COUNT          PIC 9(6)  VALUE 0.
          05 BS-ORD-QUEUE-CAPACITY       PIC 9(6)  VALUE 50000.
          05 BS-ORD-QUEUE-TOTAL-GROSS    PIC S9(18)V9(8) COMP-3 VALUE 0.
