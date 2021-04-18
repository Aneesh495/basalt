      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - INTERBANK HOLIDAY CALENDARS     *
      *> Multi-center settlement calendars: TARGET2, USNY, GBLO, JPTO  *
      *> Business day roll rules and Meeus Easter calculation tables.  *
      *>================================================================*
       01 BS-CALENDAR-CONFIG.
          05 BS-CAL-CENTER-COUNT         PIC 9(2) VALUE 8.
          05 BS-CAL-CENTERS OCCURS 8 TIMES INDEXED BY BS-CENT-IDX.
             10 BS-CENT-CODE             PIC X(4).
             10 BS-CENT-NAME             PIC X(24).
             10 BS-CENT-TIMEZONE-OFFSET  PIC S9(2).
             10 BS-CENT-WEEKEND-MASK     PIC X(7).
             10 BS-CENT-HOLIDAY-COUNT    PIC 9(3).
             10 BS-CENT-HOLIDAYS OCCURS 30 TIMES INDEXED BY BS-HOL-IDX.
                15 BS-HOL-DATE           PIC 9(8).
                15 BS-HOL-NAME           PIC X(20).

       01 BS-ROLL-CONVENTIONS.
          05 BS-ROLL-FOLLOWING           PIC 9(1) VALUE 1.
          05 BS-ROLL-MOD-FOLLOWING       PIC 9(1) VALUE 2.
          05 BS-ROLL-PRECEDING           PIC 9(1) VALUE 3.
          05 BS-ROLL-MOD-PRECEDING       PIC 9(1) VALUE 4.
          05 BS-ROLL-UNADJUSTED          PIC 9(1) VALUE 5.

       01 BS-CALENDAR-WORKING.
          05 BS-CAL-TEST-DATE            PIC 9(8) VALUE 0.
          05 BS-CAL-IS-HOLIDAY           PIC 9(1) VALUE 0.
          05 BS-CAL-IS-WEEKEND           PIC 9(1) VALUE 0.
          05 BS-CAL-ADJUSTED-DATE        PIC 9(8) VALUE 0.
