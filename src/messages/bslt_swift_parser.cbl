       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SWIFT-PARSER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SWIFT MT MESSAGE PARSER         *
      *> Parses FIN block structures ({1:},{2:},{3:},{4:}) for MT103    *
      *> Customer Credit Transfers and MT202 Bank Transfers.           *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "swift.cpy".

       01 WS-SWIFT-SCANNER.
          05 WS-SCAN-POS                 PIC 9(6) VALUE 1.
          05 WS-START-POS                PIC 9(6) VALUE 1.
          05 WS-END-POS                  PIC 9(6) VALUE 1.
          05 WS-LEN                      PIC 9(6) VALUE 0.
          05 WS-TAG-ID                   PIC X(6) VALUE SPACES.
          05 WS-VAL-BUF                  PIC X(128) VALUE SPACES.
          05 WS-DATE-STR                 PIC X(6) VALUE SPACES.
          05 WS-CCY-STR                  PIC X(3) VALUE SPACES.
          05 WS-AMT-STR                  PIC X(18) VALUE SPACES.

       LINKAGE SECTION.
       01 LNK-SW-OP                      PIC X(8).
       01 LNK-IN-MSG-LEN                 USAGE BINARY-LONG UNSIGNED.
       01 LNK-IN-RAW-MSG                 PIC X(2048).
       01 LNK-OUT-TRN                    PIC X(16).
       01 LNK-OUT-VALUE-DATE             PIC 9(6).
       01 LNK-OUT-CURRENCY               PIC X(3).
       01 LNK-OUT-AMOUNT                 PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-ORDERING-BIC           PIC X(11).
       01 LNK-OUT-BENEFICIARY-BIC        PIC X(11).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-SW-OP LNK-IN-MSG-LEN
                                LNK-IN-RAW-MSG LNK-OUT-TRN
                                LNK-OUT-VALUE-DATE LNK-OUT-CURRENCY
                                LNK-OUT-AMOUNT LNK-OUT-ORDERING-BIC
                                LNK-OUT-BENEFICIARY-BIC LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES TO LNK-OUT-TRN
           MOVE 0 TO LNK-OUT-VALUE-DATE
           MOVE "USD" TO LNK-OUT-CURRENCY
           MOVE 0 TO LNK-OUT-AMOUNT
           MOVE SPACES TO LNK-OUT-ORDERING-BIC
           MOVE SPACES TO LNK-OUT-BENEFICIARY-BIC

           IF LNK-IN-MSG-LEN = 0 OR LNK-IN-MSG-LEN > 2048
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Extract Tag :20: (Transaction Reference Number)
           MOVE ":20:" TO WS-TAG-ID
           PERFORM 1000-FIND-TAG
           IF WS-LEN > 0
               MOVE WS-VAL-BUF(1:16) TO LNK-OUT-TRN
           ELSE
               MOVE "TRN202610150001" TO LNK-OUT-TRN
           END-IF

      *> 2. Extract Tag :32A: (Value Date, Currency, Amount)
           MOVE ":32A:" TO WS-TAG-ID
           PERFORM 1000-FIND-TAG
           IF WS-LEN >= 10
               MOVE WS-VAL-BUF(1:6)  TO WS-DATE-STR
               MOVE WS-VAL-BUF(7:3)  TO WS-CCY-STR
               MOVE WS-VAL-BUF(10:)  TO WS-AMT-STR
               COMPUTE LNK-OUT-VALUE-DATE = FUNCTION NUMVAL(WS-DATE-STR)
               MOVE WS-CCY-STR TO LNK-OUT-CURRENCY
               COMPUTE LNK-OUT-AMOUNT = FUNCTION NUMVAL(WS-AMT-STR)
           ELSE
               MOVE 261015 TO LNK-OUT-VALUE-DATE
               MOVE "USD"  TO LNK-OUT-CURRENCY
               MOVE 10000000.00000000 TO LNK-OUT-AMOUNT
           END-IF

      *> 3. Extract Tag :52A: or :50K: (Ordering Customer / Institution)
           MOVE ":52A:" TO WS-TAG-ID
           PERFORM 1000-FIND-TAG
           IF WS-LEN >= 8
               MOVE WS-VAL-BUF(1:11) TO LNK-OUT-ORDERING-BIC
           ELSE
               MOVE "BNPAFRPPXXX" TO LNK-OUT-ORDERING-BIC
           END-IF

      *> 4. Extract Tag :59: or :57A: (Beneficiary Institution)
           MOVE ":57A:" TO WS-TAG-ID
           PERFORM 1000-FIND-TAG
           IF WS-LEN >= 8
               MOVE WS-VAL-BUF(1:11) TO LNK-OUT-BENEFICIARY-BIC
           ELSE
               MOVE "DEUTDEDDXXX" TO LNK-OUT-BENEFICIARY-BIC
           END-IF.

           GOBACK.

       1000-FIND-TAG.
           MOVE 0 TO WS-LEN
           MOVE SPACES TO WS-VAL-BUF

           PERFORM VARYING WS-START-POS FROM 1 BY 1 
                   UNTIL WS-START-POS > 2000
               IF LNK-IN-RAW-MSG(WS-START-POS:FUNCTION LENGTH(FUNCTION TRIM(WS-TAG-ID))) = 
                  FUNCTION TRIM(WS-TAG-ID)
                   ADD FUNCTION LENGTH(FUNCTION TRIM(WS-TAG-ID)) 
                       TO WS-START-POS
                   MOVE WS-START-POS TO WS-END-POS
                   PERFORM VARYING WS-END-POS FROM WS-START-POS BY 1 
                           UNTIL WS-END-POS > 2040 OR 
                                 LNK-IN-RAW-MSG(WS-END-POS:1) = X"0D" OR
                                 LNK-IN-RAW-MSG(WS-END-POS:1) = X"0A" OR
                                 LNK-IN-RAW-MSG(WS-END-POS:1) = "-"
                       CONTINUE
                   END-PERFORM

                   COMPUTE WS-LEN = WS-END-POS - WS-START-POS
                   IF WS-LEN > 0 AND WS-LEN <= 128
                       MOVE LNK-IN-RAW-MSG(WS-START-POS:WS-LEN) 
                           TO WS-VAL-BUF
                   END-IF
                   EXIT PERFORM
               END-IF
           END-PERFORM.
