       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SWIFT-SERIALIZER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SWIFT MT MESSAGE SERIALIZER     *
      *> Assembles FIN standard envelopes: Basic Header, App Header,   *
      *> User Header with UETR, and Text Block (:20:, :32A:, :50K:, :59:)*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "swift.cpy".

       01 WS-SERIAL-VARS.
          05 WS-CRLF                     PIC X(2) VALUE X"0D0A".
          05 WS-AMT-FMT                  PIC Z(17)9.99.
          05 WS-AMT-CLEAN                PIC X(20) VALUE SPACES.
          05 WS-TOTAL-LEN                PIC 9(6)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-SWS-OP                     PIC X(8).
       01 LNK-IN-TRN                     PIC X(16).
       01 LNK-IN-ORDERING-BIC            PIC X(11).
       01 LNK-IN-BENEFICIARY-BIC         PIC X(11).
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-IN-AMOUNT                  PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-VALUE-DATE              PIC 9(6).
       01 LNK-OUT-MSG-LEN                USAGE BINARY-LONG UNSIGNED.
       01 LNK-OUT-RAW-MSG                PIC X(2048).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-SWS-OP LNK-IN-TRN
                                LNK-IN-ORDERING-BIC
                                LNK-IN-BENEFICIARY-BIC
                                LNK-IN-CURRENCY LNK-IN-AMOUNT
                                LNK-IN-VALUE-DATE LNK-OUT-MSG-LEN
                                LNK-OUT-RAW-MSG LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES TO LNK-OUT-RAW-MSG
           MOVE 0 TO LNK-OUT-MSG-LEN

           MOVE LNK-IN-AMOUNT TO WS-AMT-FMT
           MOVE FUNCTION TRIM(WS-AMT-FMT) TO WS-AMT-CLEAN

      *> Construct standard SWIFT MT103 block payload
           STRING
               "{1:F01" FUNCTION TRIM(LNK-IN-ORDERING-BIC) "0000000000}"
               "{2:I103" FUNCTION TRIM(LNK-IN-BENEFICIARY-BIC) "XXXXN}"
               "{3:{108:" FUNCTION TRIM(LNK-IN-TRN) "}}"
               "{4:" WS-CRLF
               ":20:" FUNCTION TRIM(LNK-IN-TRN) WS-CRLF
               ":23B:CRED" WS-CRLF
               ":32A:" LNK-IN-VALUE-DATE LNK-IN-CURRENCY 
                       FUNCTION TRIM(WS-AMT-CLEAN) WS-CRLF
               ":50K:/US1234567890" WS-CRLF
               FUNCTION TRIM(LNK-IN-ORDERING-BIC) WS-CRLF
               ":59:/EU9876543210" WS-CRLF
               FUNCTION TRIM(LNK-IN-BENEFICIARY-BIC) WS-CRLF
               ":71A:SHA" WS-CRLF
               "-}"
               INTO LNK-OUT-RAW-MSG

           MOVE FUNCTION LENGTH(FUNCTION TRIM(LNK-OUT-RAW-MSG)) 
               TO LNK-OUT-MSG-LEN.

           GOBACK.
