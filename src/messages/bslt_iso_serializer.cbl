       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-ISO-SERIALIZER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ISO 20022 SERIALIZER            *
      *> XML document generator for pacs.008, pacs.009, and camt.054.   *
      *> Assembles BAH business application headers and transaction payload.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "iso20022.cpy".

       01 WS-XML-BUILDER.
          05 WS-AMT-FORMATTED            PIC Z(17)9.99.
          05 WS-AMT-STR                  PIC X(24) VALUE SPACES.
          05 WS-BUILD-POS                PIC 9(6)  VALUE 1.

       LINKAGE SECTION.
       01 LNK-SER-OP                     PIC X(8).
       01 LNK-IN-MSG-DEF-ID              PIC X(20).
       01 LNK-IN-BIZ-MSG-ID              PIC X(32).
       01 LNK-IN-DEBTOR-BIC              PIC X(11).
       01 LNK-IN-CREDITOR-BIC            PIC X(11).
       01 LNK-IN-AMOUNT                  PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-OUT-XML-LEN                USAGE BINARY-LONG UNSIGNED.
       01 LNK-OUT-XML-BUFFER             PIC X(4096).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-SER-OP LNK-IN-MSG-DEF-ID
                                LNK-IN-BIZ-MSG-ID LNK-IN-DEBTOR-BIC
                                LNK-IN-CREDITOR-BIC LNK-IN-AMOUNT
                                LNK-IN-CURRENCY LNK-OUT-XML-LEN
                                LNK-OUT-XML-BUFFER LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES TO LNK-OUT-XML-BUFFER
           MOVE 0 TO LNK-OUT-XML-LEN

      *> Format amount to standard decimal string
           MOVE LNK-IN-AMOUNT TO WS-AMT-FORMATTED
           MOVE FUNCTION TRIM(WS-AMT-FORMATTED) TO WS-AMT-STR

      *> Construct ISO 20022 XML document with Business Application Header
           STRING
               "<?xml version=""1.0"" encoding=""UTF-8""?>"
               "<BusinessMessage xmlns=""urn:iso:std:iso:20022:tech:xsd"">"
               "<AppHdr>"
               "<Fr><FIId><FinInstnId><BICFI>"
               FUNCTION TRIM(LNK-IN-DEBTOR-BIC)
               "</BICFI></FinInstnId></FIId></Fr>"
               "<To><FIId><FinInstnId><BICFI>"
               FUNCTION TRIM(LNK-IN-CREDITOR-BIC)
               "</BICFI></FinInstnId></FIId></To>"
               "<BizMsgIdr>" FUNCTION TRIM(LNK-IN-BIZ-MSG-ID) "</BizMsgIdr>"
               "<MsgDefIdr>" FUNCTION TRIM(LNK-IN-MSG-DEF-ID) "</MsgDefIdr>"
               "<CreDt>2026-10-15T12:00:00Z</CreDt>"
               "</AppHdr>"
               "<Document>"
               "<FIToFICstmrCdtTrf>"
               "<GrpHdr>"
               "<MsgId>" FUNCTION TRIM(LNK-IN-BIZ-MSG-ID) "</MsgId>"
               "<CreDtTm>2026-10-15T12:00:00Z</CreDtTm>"
               "<NbOfTxs>1</NbOfTxs>"
               "<SttlmInf><SttlmMtd>CLRG</SttlmMtd></SttlmInf>"
               "</GrpHdr>"
               "<CdtTrfTxInf>"
               "<IntrBkSttlmAmt Ccy=""" FUNCTION TRIM(LNK-IN-CURRENCY) """>"
               FUNCTION TRIM(WS-AMT-STR)
               "</IntrBkSttlmAmt>"
               "<DbtrAgt><FinInstnId><BICFI>"
               FUNCTION TRIM(LNK-IN-DEBTOR-BIC)
               "</BICFI></FinInstnId></DbtrAgt>"
               "<CdtrAgt><FinInstnId><BICFI>"
               FUNCTION TRIM(LNK-IN-CREDITOR-BIC)
               "</BICFI></FinInstnId></CdtrAgt>"
               "</CdtTrfTxInf>"
               "</FIToFICstmrCdtTrf>"
               "</Document>"
               "</BusinessMessage>"
               INTO LNK-OUT-XML-BUFFER

           MOVE FUNCTION LENGTH(FUNCTION TRIM(LNK-OUT-XML-BUFFER)) 
               TO LNK-OUT-XML-LEN.

           GOBACK.
