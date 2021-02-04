      *================================================================*
      * BASALT CLEARINGHOUSE ENGINE - FIX PROTOCOL SCHEMAS             *
      * FIX 4.4 / 5.0 tag-value tokenizer, order messages, execution   *
      *================================================================*
       01 BS-FIX-HEADER.
          05 BS-FIX-BEGIN-STRING         PIC X(8)  VALUE "FIX.4.4".
          05 BS-FIX-BODY-LENGTH          PIC 9(6)  VALUE 0.
          05 BS-FIX-MSG-TYPE             PIC X(2)  VALUE "D ".
             88 BS-FIX-MSG-NEW-ORDER     VALUE "D ".
             88 BS-FIX-MSG-EXEC-REPORT   VALUE "8 ".
             88 BS-FIX-MSG-CANCEL-REQ    VALUE "F ".
             88 BS-FIX-MSG-MARGIN-INQ    VALUE "U1".
          05 BS-FIX-SENDER-COMP-ID       PIC X(16) VALUE SPACES.
          05 BS-FIX-TARGET-COMP-ID       PIC X(16) VALUE SPACES.
          05 BS-FIX-MSG-SEQ-NUM          PIC 9(9)  VALUE 0.
          05 BS-FIX-SENDING-TIME         PIC 9(14) VALUE 0.

       01 BS-FIX-BODY.
          05 BS-FIX-CLORD-ID             PIC X(32) VALUE SPACES.
          05 BS-FIX-ORDER-ID             PIC X(32) VALUE SPACES.
          05 BS-FIX-EXEC-ID              PIC X(32) VALUE SPACES.
          05 BS-FIX-SYMBOL               PIC X(16) VALUE SPACES.
          05 BS-FIX-SECURITY-ID          PIC X(12) VALUE SPACES.
          05 BS-FIX-SIDE                 PIC X(1)  VALUE '1'.
             88 BS-FIX-SIDE-BUY          VALUE '1'.
             88 BS-FIX-SIDE-SELL         VALUE '2'.
          05 BS-FIX-ORDER-QTY            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-FIX-PRICE                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-FIX-ORD-TYPE             PIC X(1)  VALUE '2'.
             88 BS-FIX-ORD-TYPE-MARKET   VALUE '1'.
             88 BS-FIX-ORD-TYPE-LIMIT    VALUE '2'.
          05 BS-FIX-TIME-IN-FORCE        PIC X(1)  VALUE '0'.
             88 BS-FIX-TIF-DAY           VALUE '0'.
             88 BS-FIX-TIF-GTC           VALUE '1'.
             88 BS-FIX-TIF-IOC           VALUE '3'.
          05 BS-FIX-ORD-STATUS           PIC X(1)  VALUE '0'.
             88 BS-FIX-STAT-NEW          VALUE '0'.
             88 BS-FIX-STAT-PARTIAL      VALUE '1'.
             88 BS-FIX-STAT-FILLED       VALUE '2'.
             88 BS-FIX-STAT-CANCELLED    VALUE '4'.
             88 BS-FIX-STAT-REJECTED     VALUE '8'.
          05 BS-FIX-CUM-QTY              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-FIX-LEAVES-QTY           PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-FIX-AVG-PX               PIC S9(18)V9(8) COMP-3 VALUE 0.

       01 BS-FIX-TRAILER.
          05 BS-FIX-CHECKSUM             PIC 9(3)  VALUE 0.
          05 BS-FIX-COMPUTED-CHECKSUM    PIC 9(3)  VALUE 0.

       01 BS-FIX-TAG-STORE.
          05 BS-FIX-TAG-COUNT            PIC 9(3)  VALUE 0.
          05 BS-FIX-TAG-ENTRY OCCURS 64 TIMES INDEXED BY BS-FIX-TIDX.
             10 BS-TAG-NUM               PIC 9(5).
             10 BS-TAG-VAL               PIC X(48).
