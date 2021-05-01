      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - DAY-COUNT CONVENTIONS            *
      *> 30E/360, 30/360 ISDA, ACT/360, ACT/365, ACT/ACT formulas     *
      *>================================================================*
       01 BS-DAYCOUNT-INPUT.
          05 BS-DC-CONVENTION            PIC 9(2)  VALUE 1.
             88 BS-DC-30E-360            VALUE 1.
             88 BS-DC-30-360-ISDA        VALUE 2.
             88 BS-DC-ACT-360            VALUE 3.
             88 BS-DC-ACT-365            VALUE 4.
             88 BS-DC-ACT-ACT            VALUE 5.
          05 BS-DC-START-DATE.
             10 BS-DC-START-YYYY         PIC 9(4)  VALUE 2026.
             10 BS-DC-START-MM           PIC 9(2)  VALUE 1.
             10 BS-DC-START-DD           PIC 9(2)  VALUE 1.
          05 BS-DC-END-DATE.
             10 BS-DC-END-YYYY           PIC 9(4)  VALUE 2026.
             10 BS-DC-END-MM             PIC 9(2)  VALUE 7.
             10 BS-DC-END-DD             PIC 9(2)  VALUE 1.
          05 BS-DC-COUPON-FREQ           PIC 9(2)  VALUE 2.

       01 BS-DAYCOUNT-OUTPUT.
          05 BS-DC-DAYS-BETWEEN          PIC 9(6)  VALUE 0.
          05 BS-DC-YEAR-FRACTION         PIC S9(3)V9(8) COMP-3 VALUE 0.
          05 BS-DC-IS-LEAP-YEAR-START    PIC 9(1)  VALUE 0.
          05 BS-DC-IS-LEAP-YEAR-END      PIC 9(1)  VALUE 0.
