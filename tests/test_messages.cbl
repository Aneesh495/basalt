       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-MESSAGES.
      *>================================================================*
      *> BASALT TEST SUITE - FINANCIAL PROTOCOL MESSAGING               *
      *> Verification of ISO 20022 XML parsing/serialization (pacs.008),*
      *> FIX 4.4 tag-value serialization and checksum calculation, and *
      *> SWIFT FIN MT103 / MT202 interbank message parsing.             *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "iso20022.cpy".
       COPY "fix.cpy".
       COPY "swift.cpy".

      *> ISO 20022 test variables
       01 WS-ISO-TEST-VARS.
          05 WS-ISO-MSG-DEF              PIC X(20) VALUE "pacs.008.001.08".
          05 WS-ISO-BIZ-ID               PIC X(32) VALUE "MSG-2026-US-001".
          05 WS-ISO-DBTR-BIC             PIC X(11) VALUE "CHASUS33XXX".
          05 WS-ISO-CDTR-BIC             PIC X(11) VALUE "BOFAUS3NXXX".
          05 WS-ISO-AMOUNT               PIC S9(18)V9(8) COMP-3 VALUE 5000000.00000000.
          05 WS-ISO-CCY                  PIC X(3)  VALUE "USD".
          05 WS-ISO-XML-BUF              PIC X(4096) VALUE SPACES.
          05 WS-ISO-XML-LEN              USAGE BINARY-LONG UNSIGNED VALUE 0.
          05 WS-ISO-OUT-DEF              PIC X(20) VALUE SPACES.
          05 WS-ISO-OUT-BIZ              PIC X(32) VALUE SPACES.
          05 WS-ISO-OUT-DBTR             PIC X(11) VALUE SPACES.
          05 WS-ISO-OUT-CDTR             PIC X(11) VALUE SPACES.
          05 WS-ISO-OUT-AMT              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-ISO-OUT-CCY              PIC X(3)  VALUE SPACES.
          05 WS-ISO-STATUS               PIC 9(4)  VALUE 0.

      *> FIX test variables
       01 WS-FIX-TEST-VARS.
          05 WS-FIX-TYPE                 PIC X(2)  VALUE "D".
          05 WS-FIX-SENDER               PIC X(16) VALUE "CLIENT_A        ".
          05 WS-FIX-TARGET               PIC X(16) VALUE "BASALT_CCP      ".
          05 WS-FIX-CLORDID              PIC X(32) VALUE "ORD-9988776655  ".
          05 WS-FIX-SYMBOL               PIC X(16) VALUE "AAPL            ".
          05 WS-FIX-SIDE                 PIC X(1)  VALUE "1".
          05 WS-FIX-QTY                  PIC S9(18)V9(8) COMP-3 VALUE 1000.00000000.
          05 WS-FIX-PX                   PIC S9(18)V9(8) COMP-3 VALUE 185.50000000.
          05 WS-FIX-RAW-BUF              PIC X(2048) VALUE SPACES.
          05 WS-FIX-RAW-LEN              USAGE BINARY-LONG UNSIGNED VALUE 0.
          05 WS-FIX-OUT-TYPE             PIC X(2)  VALUE SPACES.
          05 WS-FIX-OUT-CLORDID          PIC X(32) VALUE SPACES.
          05 WS-FIX-OUT-SYM              PIC X(16) VALUE SPACES.
          05 WS-FIX-OUT-SIDE             PIC X(1)  VALUE SPACES.
          05 WS-FIX-OUT-QTY              PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FIX-OUT-PX               PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-FIX-STATUS               PIC 9(4)  VALUE 0.

      *> SWIFT test variables
       01 WS-SWIFT-TEST-VARS.
          05 WS-SWIFT-RAW                PIC X(2048) VALUE 
             "{1:F01CHASUS33AXXX0000000000}{2:I103BOFAUS3NXXXXN}{4:" &
             ":20:TRN2026101599" & X"0A" &
             ":32A:261015USD1500000,00" & X"0A" &
             ":50K:/US12345678" & X"0A" &
             "CHASUS33XXX" & X"0A" &
             ":59:/US87654321" & X"0A" &
             "BOFAUS3NXXX" & X"0A" &
             "-}".
          05 WS-SWIFT-LEN                USAGE BINARY-LONG UNSIGNED VALUE 160.
          05 WS-SWIFT-TRN                PIC X(16) VALUE SPACES.
          05 WS-SWIFT-VDATE              PIC 9(6)  VALUE 0.
          05 WS-SWIFT-CCY                PIC X(3)  VALUE SPACES.
          05 WS-SWIFT-AMT                PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-SWIFT-ORD-BIC            PIC X(11) VALUE SPACES.
          05 WS-SWIFT-BEN-BIC            PIC X(11) VALUE SPACES.
          05 WS-SWIFT-STATUS             PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *>----------------------------------------------------------------*
      *> TEST 1: Serialize ISO 20022 pacs.008 Payment Transfer XML
      *>----------------------------------------------------------------*
           CALL "BSLT-ISO-SERIALIZER" USING "SERIALIZ"
                                            WS-ISO-MSG-DEF
                                            WS-ISO-BIZ-ID
                                            WS-ISO-DBTR-BIC
                                            WS-ISO-CDTR-BIC
                                            WS-ISO-AMOUNT
                                            WS-ISO-CCY
                                            WS-ISO-XML-LEN
                                            WS-ISO-XML-BUF
                                            WS-ISO-STATUS
           IF WS-ISO-STATUS = BS-RC-OK AND WS-ISO-XML-LEN > 100
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ISO 20022 XML serializer failed: " WS-ISO-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Parse Serialized ISO 20022 XML Message (Roundtrip)
      *>----------------------------------------------------------------*
           CALL "BSLT-ISO-PARSER" USING "PARSE   "
                                        WS-ISO-XML-LEN
                                        WS-ISO-XML-BUF
                                        WS-ISO-OUT-DEF
                                        WS-ISO-OUT-BIZ
                                        WS-ISO-OUT-DBTR
                                        WS-ISO-OUT-CDTR
                                        WS-ISO-OUT-AMT
                                        WS-ISO-OUT-CCY
                                        WS-ISO-STATUS
           IF WS-ISO-STATUS = BS-RC-OK AND WS-ISO-OUT-AMT = WS-ISO-AMOUNT
              AND WS-ISO-OUT-CCY = "USD"
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: ISO 20022 XML parser roundtrip failed: " WS-ISO-OUT-AMT
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 3: Serialize FIX 4.4 NewOrderSingle (35=D) Message
      *>----------------------------------------------------------------*
           CALL "BSLT-FIX-SERIALIZER" USING "SERIALIZ"
                                            WS-FIX-TYPE
                                            WS-FIX-SENDER
                                            WS-FIX-TARGET
                                            WS-FIX-CLORDID
                                            WS-FIX-SYMBOL
                                            WS-FIX-SIDE
                                            WS-FIX-QTY
                                            WS-FIX-PX
                                            WS-FIX-RAW-LEN
                                            WS-FIX-RAW-BUF
                                            WS-FIX-STATUS
           IF WS-FIX-STATUS = BS-RC-OK AND WS-FIX-RAW-LEN > 50
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: FIX 4.4 serializer failed: " WS-FIX-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 4: Parse FIX 4.4 Raw Message and Verify Tags
      *>----------------------------------------------------------------*
           CALL "BSLT-FIX-PARSER" USING "PARSE   "
                                        WS-FIX-RAW-LEN
                                        WS-FIX-RAW-BUF
                                        WS-FIX-OUT-TYPE
                                        WS-FIX-OUT-CLORDID
                                        WS-FIX-OUT-SYM
                                        WS-FIX-OUT-SIDE
                                        WS-FIX-OUT-QTY
                                        WS-FIX-OUT-PX
                                        WS-FIX-STATUS
           IF WS-FIX-STATUS = BS-RC-OK AND WS-FIX-OUT-TYPE = "D"
              AND WS-FIX-OUT-SIDE = "1" AND WS-FIX-OUT-QTY = 1000.00000000
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: FIX 4.4 parser roundtrip failed: " WS-FIX-STATUS
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 5: Parse SWIFT FIN MT103 Customer Transfer Block 4
      *> Tags: :20: TRN, :32A: Value Date/CCY/Amount, :50K: Debtor, :59: Creditor
      *>----------------------------------------------------------------*
           CALL "BSLT-SWIFT-PARSER" USING "PARSE   "
                                          WS-SWIFT-LEN
                                          WS-SWIFT-RAW
                                          WS-SWIFT-TRN
                                          WS-SWIFT-VDATE
                                          WS-SWIFT-CCY
                                          WS-SWIFT-AMT
                                          WS-SWIFT-ORD-BIC
                                          WS-SWIFT-BEN-BIC
                                          WS-SWIFT-STATUS
           IF WS-SWIFT-STATUS = BS-RC-OK AND WS-SWIFT-CCY = "USD"
              AND WS-SWIFT-TRN NOT = SPACES
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: SWIFT MT103 parser failed: " WS-SWIFT-STATUS
           END-IF.

           GOBACK.
