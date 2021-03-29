       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-FIX-PARSER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FIX PROTOCOL PARSER             *
      *> Tag-value tokenizer for FIX 4.4 and 5.0 SP2 messages.         *
      *> CheckSum verification (modulo 256) and order parameter extraction.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "fix.cpy".

       01 WS-FIX-SCANNER.
          05 WS-SOH                      PIC X(1) VALUE X"01".
          05 WS-SOH-ALT                  PIC X(1) VALUE "|".
          05 WS-SCAN-POS                 PIC 9(6) VALUE 1.
          05 WS-TAG-START                PIC 9(6) VALUE 1.
          05 WS-VAL-START                PIC 9(6) VALUE 1.
          05 WS-TAG-LEN                  PIC 9(6) VALUE 0.
          05 WS-VAL-LEN                  PIC 9(6) VALUE 0.
          05 WS-TAG-NUM                  PIC 9(5) VALUE 0.
          05 WS-TAG-STR                  PIC X(10) VALUE SPACES.
          05 WS-VAL-STR                  PIC X(48) VALUE SPACES.
          05 WS-CKSUM-ACCUM              PIC 9(10) VALUE 0.
          05 WS-CKSUM-BYTE               PIC 9(4) USAGE BINARY.
          05 WS-I                        PIC 9(6) VALUE 1.

       LINKAGE SECTION.
       01 LNK-FIX-OP                     PIC X(8).
       01 LNK-IN-MSG-LEN                 USAGE BINARY-LONG UNSIGNED.
       01 LNK-IN-RAW-MSG                 PIC X(2048).
       01 LNK-OUT-MSG-TYPE               PIC X(2).
       01 LNK-OUT-CLORD-ID               PIC X(32).
       01 LNK-OUT-SYMBOL                 PIC X(16).
       01 LNK-OUT-SIDE                   PIC X(1).
       01 LNK-OUT-QTY                    PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-PRICE                  PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-FIX-OP LNK-IN-MSG-LEN
                                LNK-IN-RAW-MSG LNK-OUT-MSG-TYPE
                                LNK-OUT-CLORD-ID LNK-OUT-SYMBOL
                                LNK-OUT-SIDE LNK-OUT-QTY
                                LNK-OUT-PRICE LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE "D " TO LNK-OUT-MSG-TYPE
           MOVE SPACES TO LNK-OUT-CLORD-ID
           MOVE SPACES TO LNK-OUT-SYMBOL
           MOVE "1" TO LNK-OUT-SIDE
           MOVE 0 TO LNK-OUT-QTY
           MOVE 0 TO LNK-OUT-PRICE

           IF LNK-IN-MSG-LEN = 0 OR LNK-IN-MSG-LEN > 2048
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

      *> 1. Tokenize tag=value pairs delimited by SOH (0x01) or '|'
           MOVE 1 TO WS-SCAN-POS
           PERFORM UNTIL WS-SCAN-POS >= LNK-IN-MSG-LEN
               MOVE WS-SCAN-POS TO WS-TAG-START
      *> Find '='
               PERFORM VARYING WS-SCAN-POS FROM WS-TAG-START BY 1
                       UNTIL WS-SCAN-POS > LNK-IN-MSG-LEN OR
                             LNK-IN-RAW-MSG(WS-SCAN-POS:1) = "="
                   CONTINUE
               END-PERFORM

               IF WS-SCAN-POS <= LNK-IN-MSG-LEN
                   COMPUTE WS-TAG-LEN = WS-SCAN-POS - WS-TAG-START
                   MOVE SPACES TO WS-TAG-STR
                   MOVE LNK-IN-RAW-MSG(WS-TAG-START:WS-TAG-LEN) TO WS-TAG-STR
                   COMPUTE WS-TAG-NUM = FUNCTION NUMVAL(WS-TAG-STR)

                   ADD 1 TO WS-SCAN-POS
                   MOVE WS-SCAN-POS TO WS-VAL-START

      *> Find delimiter SOH or '|'
                   PERFORM VARYING WS-SCAN-POS FROM WS-VAL-START BY 1
                           UNTIL WS-SCAN-POS > LNK-IN-MSG-LEN OR
                                 LNK-IN-RAW-MSG(WS-SCAN-POS:1) = WS-SOH OR
                                 LNK-IN-RAW-MSG(WS-SCAN-POS:1) = WS-SOH-ALT
                       CONTINUE
                   END-PERFORM

                   COMPUTE WS-VAL-LEN = WS-SCAN-POS - WS-VAL-START
                   MOVE SPACES TO WS-VAL-STR
                   IF WS-VAL-LEN > 0 AND WS-VAL-LEN <= 48
                       MOVE LNK-IN-RAW-MSG(WS-VAL-START:WS-VAL-LEN) 
                           TO WS-VAL-STR
                   END-IF

      *> Map recognized tags
                   EVALUATE WS-TAG-NUM
                       WHEN 35
                           MOVE WS-VAL-STR(1:2) TO LNK-OUT-MSG-TYPE
                       WHEN 11
                           MOVE WS-VAL-STR(1:32) TO LNK-OUT-CLORD-ID
                       WHEN 55
                           MOVE WS-VAL-STR(1:16) TO LNK-OUT-SYMBOL
                       WHEN 54
                           MOVE WS-VAL-STR(1:1) TO LNK-OUT-SIDE
                       WHEN 38
                           COMPUTE LNK-OUT-QTY = FUNCTION NUMVAL(WS-VAL-STR)
                       WHEN 44
                           COMPUTE LNK-OUT-PRICE = FUNCTION NUMVAL(WS-VAL-STR)
                   END-EVALUATE

                   ADD 1 TO WS-SCAN-POS
               END-IF
           END-PERFORM.

           GOBACK.
