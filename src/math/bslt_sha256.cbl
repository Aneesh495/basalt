       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SHA256.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SHA-256 CRYPTOGRAPHIC HASHER    *
      *> FIPS 180-4 conformant state machine, message padding, and     *
      *> 256-bit binary to 64-character hexadecimal digest encoding.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "merkle.cpy".

       01 WS-HEX-TABLE                   PIC X(16) VALUE "0123456789abcdef".
       01 WS-BYTE-IDX                    PIC 9(4)  VALUE 1.
       01 WS-HEX-IDX                     PIC 9(4)  VALUE 1.
       01 WS-BYTE-VAL                    PIC 9(4)  USAGE BINARY.
       01 WS-HI-NIBBLE                   PIC 9(4)  USAGE BINARY.
       01 WS-LO-NIBBLE                   PIC 9(4)  USAGE BINARY.
       01 WS-HI-CHAR                     PIC X(1).
       01 WS-LO-CHAR                     PIC X(1).

       LINKAGE SECTION.
       01 LNK-SHA-MSG                    PIC X(4096).
       01 LNK-SHA-LEN                    USAGE BINARY-LONG UNSIGNED.
       01 LNK-SHA-BIN-OUT                PIC X(32).
       01 LNK-SHA-HEX-OUT                PIC X(64).
       01 LNK-SHA-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-SHA-MSG LNK-SHA-LEN
                                LNK-SHA-BIN-OUT LNK-SHA-HEX-OUT
                                LNK-SHA-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-SHA-STATUS
           MOVE LOW-VALUES TO LNK-SHA-BIN-OUT
           MOVE SPACES TO LNK-SHA-HEX-OUT

           IF LNK-SHA-LEN > 4096
               MOVE BS-RC-BUFFER-OVERFLOW TO LNK-SHA-STATUS
               GOBACK
           END-IF

      *> Invoke high-performance cryptographic transform
           CALL "bslt_sha256_full" USING BY REFERENCE LNK-SHA-MSG
                                         BY VALUE     LNK-SHA-LEN
                                         BY REFERENCE LNK-SHA-BIN-OUT

      *> Encode 32-byte binary digest into 64-character hexadecimal
           MOVE 1 TO WS-HEX-IDX
           PERFORM VARYING WS-BYTE-IDX FROM 1 BY 1 UNTIL WS-BYTE-IDX > 32
               MOVE FUNCTION ORD(LNK-SHA-BIN-OUT(WS-BYTE-IDX:1)) 
                   TO WS-BYTE-VAL
      *> ORD returns 1-based ASCII ordinal (1 to 256), subtract 1 for byte value
               SUBTRACT 1 FROM WS-BYTE-VAL
               DIVIDE WS-BYTE-VAL BY 16 GIVING WS-HI-NIBBLE 
                   REMAINDER WS-LO-NIBBLE

      *> Map 0..15 to 1..16 for 1-based indexing into table
               ADD 1 TO WS-HI-NIBBLE
               ADD 1 TO WS-LO-NIBBLE
               MOVE WS-HEX-TABLE(WS-HI-NIBBLE:1) TO WS-HI-CHAR
               MOVE WS-HEX-TABLE(WS-LO-NIBBLE:1) TO WS-LO-CHAR

               MOVE WS-HI-CHAR TO LNK-SHA-HEX-OUT(WS-HEX-IDX:1)
               ADD 1 TO WS-HEX-IDX
               MOVE WS-LO-CHAR TO LNK-SHA-HEX-OUT(WS-HEX-IDX:1)
               ADD 1 TO WS-HEX-IDX
           END-PERFORM

           GOBACK.
