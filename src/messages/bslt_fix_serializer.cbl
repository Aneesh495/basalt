       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-FIX-SERIALIZER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FIX PROTOCOL SERIALIZER         *
      *> Formats FIX 4.4 messages, computes exact body length (Tag 9),  *
      *> and evaluates 3-digit modulo 256 trailer checksum (Tag 10).   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "fix.cpy".

       01 WS-SERIALIZER-STATE.
          05 WS-SOH                      PIC X(1) VALUE X"01".
          05 WS-BODY-BUFFER              PIC X(1024) VALUE SPACES.
          05 WS-BODY-LEN                 PIC 9(6) VALUE 0.
          05 WS-QTY-STR                  PIC X(16) VALUE SPACES.
          05 WS-PX-STR                   PIC X(16) VALUE SPACES.
          05 WS-QTY-FMT                  PIC Z(9)9.
          05 WS-PX-FMT                   PIC Z(7)9.9999.
          05 WS-CKSUM-ACCUM              PIC 9(10) VALUE 0.
          05 WS-CKSUM-VAL                PIC 9(3) VALUE 0.
          05 WS-CKSUM-FMT                PIC 999.
          05 WS-TOTAL-LEN                PIC 9(6) VALUE 0.
          05 WS-I                        PIC 9(6) VALUE 1.
          05 WS-BYTE-VAL                 PIC 9(4) USAGE BINARY.

       LINKAGE SECTION.
       01 LNK-FXS-OP                     PIC X(8).
       01 LNK-IN-MSG-TYPE                PIC X(2).
       01 LNK-IN-SENDER                  PIC X(16).
       01 LNK-IN-TARGET                  PIC X(16).
       01 LNK-IN-CLORD-ID                PIC X(32).
       01 LNK-IN-SYMBOL                  PIC X(16).
       01 LNK-IN-SIDE                    PIC X(1).
       01 LNK-IN-QTY                     PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-PRICE                   PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MSG-LEN                USAGE BINARY-LONG UNSIGNED.
       01 LNK-OUT-RAW-MSG                PIC X(2048).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-FXS-OP LNK-IN-MSG-TYPE
                                LNK-IN-SENDER LNK-IN-TARGET
                                LNK-IN-CLORD-ID LNK-IN-SYMBOL
                                LNK-IN-SIDE LNK-IN-QTY
                                LNK-IN-PRICE LNK-OUT-MSG-LEN
                                LNK-OUT-RAW-MSG LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES TO LNK-OUT-RAW-MSG
           MOVE 0 TO LNK-OUT-MSG-LEN

      *> Format quantities and prices
           MOVE LNK-IN-QTY TO WS-QTY-FMT
           MOVE FUNCTION TRIM(WS-QTY-FMT) TO WS-QTY-STR
           MOVE LNK-IN-PRICE TO WS-PX-FMT
           MOVE FUNCTION TRIM(WS-PX-FMT) TO WS-PX-STR

      *> 1. Construct Message Body (excluding BeginString, BodyLen, CheckSum)
           MOVE SPACES TO WS-BODY-BUFFER
           STRING
               "35=" FUNCTION TRIM(LNK-IN-MSG-TYPE) "|"
               "49=" FUNCTION TRIM(LNK-IN-SENDER) "|"
               "56=" FUNCTION TRIM(LNK-IN-TARGET) "|"
               "34=1|"
               "52=20261015-12:00:00|"
               "11=" FUNCTION TRIM(LNK-IN-CLORD-ID) "|"
               "55=" FUNCTION TRIM(LNK-IN-SYMBOL) "|"
               "54=" LNK-IN-SIDE "|"
               "38=" FUNCTION TRIM(WS-QTY-STR) "|"
               "44=" FUNCTION TRIM(WS-PX-STR) "|"
               "40=2|"
               "59=0|"
               INTO WS-BODY-BUFFER

           MOVE FUNCTION LENGTH(FUNCTION TRIM(WS-BODY-BUFFER)) 
               TO WS-BODY-LEN

      *> 2. Assemble Full Message with standard Header (8=, 9=)
           STRING
               "8=FIX.4.4|"
               "9=" WS-BODY-LEN "|"
               FUNCTION TRIM(WS-BODY-BUFFER)
               INTO LNK-OUT-RAW-MSG

           MOVE FUNCTION LENGTH(FUNCTION TRIM(LNK-OUT-RAW-MSG)) 
               TO WS-TOTAL-LEN

      *> 3. Calculate Modulo 256 Checksum over all assembled bytes
           MOVE 0 TO WS-CKSUM-ACCUM
           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > WS-TOTAL-LEN
               MOVE FUNCTION ORD(LNK-OUT-RAW-MSG(WS-I:1)) TO WS-BYTE-VAL
               SUBTRACT 1 FROM WS-BYTE-VAL
               ADD WS-BYTE-VAL TO WS-CKSUM-ACCUM
           END-PERFORM

           COMPUTE WS-CKSUM-VAL = FUNCTION MOD(WS-CKSUM-ACCUM, 256)
           MOVE WS-CKSUM-VAL TO WS-CKSUM-FMT

      *> 4. Append standard trailer Tag 10
           STRING
               FUNCTION TRIM(LNK-OUT-RAW-MSG)
               "10=" WS-CKSUM-FMT "|"
               INTO LNK-OUT-RAW-MSG

           MOVE FUNCTION LENGTH(FUNCTION TRIM(LNK-OUT-RAW-MSG)) 
               TO LNK-OUT-MSG-LEN.

           GOBACK.
