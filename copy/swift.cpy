      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SWIFT MT MESSAGE SCHEMAS         *
      *> Legacy FIN message layouts: MT103, MT202, MT940, MT541, MT543 *
      *> Interbank settlement, statement, and securities instructions.  *
      *>================================================================*
       01 BS-SWIFT-MT103.
          05 BS-SW-BASIC-HEADER.
             10 BS-SW-APP-ID             PIC X(1)  VALUE "F".
             10 BS-SW-SERVICE-ID         PIC 9(2)  VALUE 01.
             10 BS-SW-LT-ADDRESS         PIC X(12) VALUE SPACES.
             10 BS-SW-SESSION-NUM        PIC 9(4)  VALUE 0.
             10 BS-SW-SEQ-NUM            PIC 9(6)  VALUE 0.
          05 BS-SW-APP-HEADER.
             10 BS-SW-IO-TYPE            PIC X(1)  VALUE "I".
             10 BS-SW-MSG-TYPE           PIC 9(3)  VALUE 103.
             10 BS-SW-DEST-BIC           PIC X(12) VALUE SPACES.
             10 BS-SW-PRIORITY           PIC X(1)  VALUE "N".
          05 BS-SW-USER-HEADER.
             10 BS-SW-BANKING-PRIORITY   PIC X(4)  VALUE SPACES.
             10 BS-SW-MSG-USER-REF       PIC X(16) VALUE SPACES.
             10 BS-SW-UETR               PIC X(36) VALUE SPACES.
          05 BS-SW-TEXT-BLOCK.
             10 BS-SW-TAG-20-TRN         PIC X(16) VALUE SPACES.
             10 BS-SW-TAG-23B-OP-CODE    PIC X(4)  VALUE "CRED".
             10 BS-SW-TAG-32A-VALUE-DATE PIC 9(6)  VALUE 0.
             10 BS-SW-TAG-32A-CURRENCY   PIC X(3)  VALUE "USD".
             10 BS-SW-TAG-32A-AMOUNT     PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-SW-TAG-33B-CCY        PIC X(3)  VALUE "USD".
             10 BS-SW-TAG-33B-AMOUNT     PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-SW-TAG-50K-ORDERING.
                15 BS-SW-50K-ACC         PIC X(34) VALUE SPACES.
                15 BS-SW-50K-NAME        PIC X(35) VALUE SPACES.
                15 BS-SW-50K-ADDR-1      PIC X(35) VALUE SPACES.
                15 BS-SW-50K-ADDR-2      PIC X(35) VALUE SPACES.
             10 BS-SW-TAG-52A-ORDER-INST PIC X(11) VALUE SPACES.
             10 BS-SW-TAG-53A-SENDER-COR PIC X(11) VALUE SPACES.
             10 BS-SW-TAG-54A-RCVR-COR   PIC X(11) VALUE SPACES.
             10 BS-SW-TAG-56A-INTERMED   PIC X(11) VALUE SPACES.
             10 BS-SW-TAG-57A-ACCT-INST  PIC X(11) VALUE SPACES.
             10 BS-SW-TAG-59-BENEFICIARY.
                15 BS-SW-59-ACC          PIC X(34) VALUE SPACES.
                15 BS-SW-59-NAME         PIC X(35) VALUE SPACES.
                15 BS-SW-59-ADDR-1       PIC X(35) VALUE SPACES.
                15 BS-SW-59-ADDR-2       PIC X(35) VALUE SPACES.
             10 BS-SW-TAG-70-REMITTANCE  PIC X(140) VALUE SPACES.
             10 BS-SW-TAG-71A-CHARGES    PIC X(3)  VALUE "SHA".
             10 BS-SW-TAG-71F-SNDR-CHG   PIC S9(18)V9(8) COMP-3 VALUE 0.
             10 BS-SW-TAG-72-SENDER-RCVR PIC X(210) VALUE SPACES.
          05 BS-SW-TRAILER-BLOCK.
             10 BS-SW-MAC                PIC X(8)  VALUE SPACES.
             10 BS-SW-CHK                PIC X(12) VALUE SPACES.

       01 BS-SWIFT-MT202.
          05 BS-202-TRN                  PIC X(16) VALUE SPACES.
          05 BS-202-RELATED-REF          PIC X(16) VALUE SPACES.
          05 BS-202-VALUE-DATE           PIC 9(6)  VALUE 0.
          05 BS-202-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-202-AMOUNT               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-202-ORDERING-INST        PIC X(11) VALUE SPACES.
          05 BS-202-SENDER-CORR          PIC X(11) VALUE SPACES.
          05 BS-202-RCVR-CORR            PIC X(11) VALUE SPACES.
          05 BS-202-INTERMEDIARY         PIC X(11) VALUE SPACES.
          05 BS-202-ACCT-WITH-INST       PIC X(11) VALUE SPACES.
          05 BS-202-BENEFICIARY-INST     PIC X(11) VALUE SPACES.

       01 BS-SWIFT-MT940-STATEMENT.
          05 BS-940-TRN                  PIC X(16) VALUE SPACES.
          05 BS-940-ACCOUNT-ID           PIC X(35) VALUE SPACES.
          05 BS-940-STATEMENT-NUM        PIC 9(5)  VALUE 0.
          05 BS-940-SEQUENCE-NUM         PIC 9(5)  VALUE 0.
          05 BS-940-OPENING-BAL-TYPE     PIC X(1)  VALUE "C".
          05 BS-940-OPENING-DATE         PIC 9(6)  VALUE 0.
          05 BS-940-OPENING-CCY          PIC X(3)  VALUE "USD".
          05 BS-940-OPENING-AMT          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-940-CLOSING-BAL-TYPE     PIC X(1)  VALUE "C".
          05 BS-940-CLOSING-DATE         PIC 9(6)  VALUE 0.
          05 BS-940-CLOSING-CCY          PIC X(3)  VALUE "USD".
          05 BS-940-CLOSING-AMT          PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-940-ENTRY-COUNT          PIC 9(4)  VALUE 0.
          05 BS-940-ENTRIES OCCURS 100 TIMES INDEXED BY BS-940-IDX.
             10 BS-940-E-VALUE-DATE      PIC 9(6).
             10 BS-940-E-ENTRY-DATE      PIC 9(4).
             10 BS-940-E-D-C-MARK        PIC X(2).
             10 BS-940-E-CURRENCY-CODE   PIC X(1).
             10 BS-940-E-AMOUNT          PIC S9(18)V9(8) COMP-3.
             10 BS-940-E-TX-TYPE-CODE    PIC X(4).
             10 BS-940-E-CUST-REFERENCE  PIC X(16).
             10 BS-940-E-BANK-REFERENCE  PIC X(16).
             10 BS-940-E-SUPPLEMENTARY   PIC X(34).

       01 BS-SWIFT-MT541-DVP-RECEIVE.
          05 BS-541-SEME-REF             PIC X(16) VALUE SPACES.
          05 BS-541-PREP-DATE-TIME       PIC 9(14) VALUE 0.
          05 BS-541-SETTLEMENT-DATE      PIC 9(8)  VALUE 0.
          05 BS-541-TRADE-DATE           PIC 9(8)  VALUE 0.
          05 BS-541-ISIN                 PIC X(12) VALUE SPACES.
          05 BS-541-SETTLEMENT-QTY       PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-541-SETTLEMENT-AMOUNT    PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-541-SETTLEMENT-CCY       PIC X(3)  VALUE "USD".
          05 BS-541-DELIVERER-BIC        PIC X(11) VALUE SPACES.
          05 BS-541-RECEIVER-BIC         PIC X(11) VALUE SPACES.
          05 BS-541-SAFEKEEPING-ACC      PIC X(35) VALUE SPACES.
