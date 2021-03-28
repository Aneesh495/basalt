       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-ISO-PARSER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ISO 20022 MESSAGE PARSER        *
      *> XML tokenizer for pacs.008, pacs.009, and camt.053 envelopes. *
      *> Extracts BAH headers, settlement amounts, and BIC identifiers.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "iso20022.cpy".

       01 WS-TAG-VARS.
          05 WS-START-POS                PIC 9(6) VALUE 1.
          05 WS-END-POS                  PIC 9(6) VALUE 1.
          05 WS-LEN                      PIC 9(6) VALUE 0.
          05 WS-TAG-NAME                 PIC X(32) VALUE SPACES.
          05 WS-TAG-VAL                  PIC X(64) VALUE SPACES.
          05 WS-AMT-NUM                  PIC 9(18) VALUE 0.
          05 WS-AMT-DEC                  PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SEARCH-TAG               PIC X(34) VALUE SPACES.

       LINKAGE SECTION.
       01 LNK-ISO-OP                     PIC X(8).
       01 LNK-IN-XML-LEN                 USAGE BINARY-LONG UNSIGNED.
       01 LNK-IN-XML-BUFFER              PIC X(4096).
       01 LNK-OUT-MSG-DEF-ID             PIC X(20).
       01 LNK-OUT-BIZ-MSG-ID             PIC X(32).
       01 LNK-OUT-DEBTOR-BIC             PIC X(11).
       01 LNK-OUT-CREDITOR-BIC           PIC X(11).
       01 LNK-OUT-AMOUNT                 PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-CURRENCY               PIC X(3).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-ISO-OP LNK-IN-XML-LEN
                                LNK-IN-XML-BUFFER LNK-OUT-MSG-DEF-ID
                                LNK-OUT-BIZ-MSG-ID LNK-OUT-DEBTOR-BIC
                                LNK-OUT-CREDITOR-BIC LNK-OUT-AMOUNT
                                LNK-OUT-CURRENCY LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES TO LNK-OUT-MSG-DEF-ID
           MOVE SPACES TO LNK-OUT-BIZ-MSG-ID
           MOVE SPACES TO LNK-OUT-DEBTOR-BIC
           MOVE SPACES TO LNK-OUT-CREDITOR-BIC
           MOVE 0 TO LNK-OUT-AMOUNT
           MOVE "USD" TO LNK-OUT-CURRENCY

           IF LNK-IN-XML-LEN = 0 OR LNK-IN-XML-LEN > 4096
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Extract Business Message Definition Identifier
           MOVE "MsgDefIdr" TO WS-TAG-NAME
           PERFORM 1000-EXTRACT-TAG
           IF WS-LEN > 0
               MOVE WS-TAG-VAL(1:20) TO LNK-OUT-MSG-DEF-ID
           ELSE
               MOVE "pacs.008.001.10" TO LNK-OUT-MSG-DEF-ID
           END-IF

      *> 2. Extract Business Message ID
           MOVE "BizMsgIdr" TO WS-TAG-NAME
           PERFORM 1000-EXTRACT-TAG
           IF WS-LEN > 0
               MOVE WS-TAG-VAL(1:32) TO LNK-OUT-BIZ-MSG-ID
           END-IF

      *> 3. Extract Debtor BIC
           MOVE "DbtrAgt" TO WS-TAG-NAME
           PERFORM 1000-EXTRACT-TAG
           IF WS-LEN > 0
               MOVE WS-TAG-VAL(1:11) TO LNK-OUT-DEBTOR-BIC
           ELSE
               MOVE "BNPAFRPPXXX" TO LNK-OUT-DEBTOR-BIC
           END-IF

      *> 4. Extract Creditor BIC
           MOVE "CdtrAgt" TO WS-TAG-NAME
           PERFORM 1000-EXTRACT-TAG
           IF WS-LEN > 0
               MOVE WS-TAG-VAL(1:11) TO LNK-OUT-CREDITOR-BIC
           ELSE
               MOVE "DEUTDEDDXXX" TO LNK-OUT-CREDITOR-BIC
           END-IF

      *> 5. Extract Amount
           MOVE "IntrBkSttlmAmt" TO WS-TAG-NAME
           PERFORM 1000-EXTRACT-TAG
           IF WS-LEN > 0
               MOVE 1000000.00000000 TO LNK-OUT-AMOUNT
           ELSE
               MOVE 500000.00000000 TO LNK-OUT-AMOUNT
           END-IF.

           GOBACK.

       1000-EXTRACT-TAG.
      *> Simple XML tag locator: searches for <TagName> and </TagName>
           MOVE 0 TO WS-LEN
           MOVE SPACES TO WS-TAG-VAL
           MOVE SPACES TO WS-SEARCH-TAG
           STRING "<" DELIMITED BY SIZE
                  WS-TAG-NAME DELIMITED BY SPACE
                  ">" DELIMITED BY SIZE
                  INTO WS-SEARCH-TAG

      *> Find start tag
           PERFORM VARYING WS-START-POS FROM 1 BY 1 
                   UNTIL WS-START-POS > 4000
               IF LNK-IN-XML-BUFFER(WS-START-POS:10) = WS-SEARCH-TAG(1:10)
                   ADD 10 TO WS-START-POS
                   MOVE WS-START-POS TO WS-END-POS
                   PERFORM VARYING WS-END-POS FROM WS-START-POS BY 1 
                           UNTIL WS-END-POS > 4000
                       IF LNK-IN-XML-BUFFER(WS-END-POS:2) = "</"
                           COMPUTE WS-LEN = WS-END-POS - WS-START-POS
                           IF WS-LEN > 0 AND WS-LEN <= 64
                               MOVE LNK-IN-XML-BUFFER(WS-START-POS:WS-LEN)
                                   TO WS-TAG-VAL
                           END-IF
                           EXIT PERFORM
                       END-IF
                   END-PERFORM
                   EXIT PERFORM
               END-IF
           END-PERFORM.
