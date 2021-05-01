      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ISO 20022 MESSAGE SCHEMAS        *
      *> pacs.008, pacs.009, camt.053, camt.054, pain.001 structures   *
      *>================================================================*
       01 BS-ISO-BAH-HEADER.
          05 BS-BAH-FROM-BIC             PIC X(11) VALUE SPACES.
          05 BS-BAH-TO-BIC               PIC X(11) VALUE SPACES.
          05 BS-BAH-BIZ-MSG-ID           PIC X(32) VALUE SPACES.
          05 BS-BAH-MSG-DEF-ID           PIC X(20) VALUE SPACES.
             88 BS-BAH-PACS-008          VALUE "pacs.008.001.10".
             88 BS-BAH-PACS-009          VALUE "pacs.009.001.10".
             88 BS-BAH-CAMT-053          VALUE "camt.053.001.10".
             88 BS-BAH-CAMT-054          VALUE "camt.054.001.10".
             88 BS-BAH-PAIN-001          VALUE "pain.001.001.11".
          05 BS-BAH-CREATION-TIME        PIC 9(14) VALUE 0.

       01 BS-ISO-CREDIT-TRANSFER.
          05 BS-ISO-MSG-ID               PIC X(32) VALUE SPACES.
          05 BS-ISO-UETR                 PIC X(36) VALUE SPACES.
          05 BS-ISO-END-TO-END-ID        PIC X(32) VALUE SPACES.
          05 BS-ISO-INTRBK-STTLM-AMT     PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-ISO-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-ISO-STTLM-DATE           PIC 9(8)  VALUE 0.
          05 BS-ISO-DEBTOR-BIC           PIC X(11) VALUE SPACES.
          05 BS-ISO-DEBTOR-IBAN          PIC X(34) VALUE SPACES.
          05 BS-ISO-CREDITOR-BIC         PIC X(11) VALUE SPACES.
          05 BS-ISO-CREDITOR-IBAN        PIC X(34) VALUE SPACES.
          05 BS-ISO-CHARGE-BEARER        PIC X(4)  VALUE "SHAR".
             88 BS-ISO-CHARGE-DEBT       VALUE "DEBT".
             88 BS-ISO-CHARGE-CRED       VALUE "CRED".
             88 BS-ISO-CHARGE-SHAR       VALUE "SHAR".
          05 BS-ISO-REMITTANCE-INFO      PIC X(64) VALUE SPACES.

       01 BS-ISO-PARSER-STATE.
          05 BS-ISO-BUFFER-LEN           PIC 9(6)  VALUE 0.
          05 BS-ISO-BUFFER               PIC X(4096) VALUE SPACES.
          05 BS-ISO-SCAN-POS             PIC 9(6)  VALUE 1.
          05 BS-ISO-PARSE-STATUS         PIC 9(4)  VALUE 0.
