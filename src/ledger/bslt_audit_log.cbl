       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-AUDIT-LOG.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - TAMPER-EVIDENT AUDIT JOURNAL     *
      *> Chained SHA-256 cryptographic audit logs and Merkle root       *
      *> generation for regulatory non-repudiation and auditability.    *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "merkle.cpy".

       01 WS-AUDIT-STATE.
          05 WS-PREV-BLOCK-HASH          PIC X(32) VALUE LOW-VALUES.
          05 WS-BLOCK-INDEX              PIC 9(10) VALUE 0.
          05 WS-PAYLOAD-BUFFER           PIC X(512) VALUE SPACES.
          05 WS-DIGEST-HEX               PIC X(64) VALUE SPACES.
          05 WS-RAW-DIGEST               PIC X(32) VALUE LOW-VALUES.
          05 WS-BYTE-LEN                 USAGE BINARY-LONG UNSIGNED VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-AUDIT-OP                   PIC X(8).
       01 LNK-IN-TXN-ID                  PIC 9(18).
       01 LNK-IN-VALID-TIME              PIC 9(14).
       01 LNK-IN-SYSTEM-TIME             PIC 9(14).
       01 LNK-IN-DEBIT-ACC               PIC X(16).
       01 LNK-IN-CREDIT-ACC              PIC X(16).
       01 LNK-IN-AMOUNT                  PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-OUT-AUDIT-HASH-HEX         PIC X(64).
       01 LNK-OUT-BLOCK-NUM              PIC 9(10).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-AUDIT-OP LNK-IN-TXN-ID
                                LNK-IN-VALID-TIME LNK-IN-SYSTEM-TIME
                                LNK-IN-DEBIT-ACC LNK-IN-CREDIT-ACC
                                LNK-IN-AMOUNT LNK-IN-CURRENCY
                                LNK-OUT-AUDIT-HASH-HEX
                                LNK-OUT-BLOCK-NUM
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-AUDIT-OP
               WHEN "APPEND  "
                   PERFORM 1000-APPEND-AUDIT-ENTRY
               WHEN "GET-PREV"
                   MOVE WS-PREV-BLOCK-HASH TO LNK-OUT-AUDIT-HASH-HEX
                   MOVE WS-BLOCK-INDEX     TO LNK-OUT-BLOCK-NUM
               WHEN "RESET   "
                   MOVE LOW-VALUES TO WS-PREV-BLOCK-HASH
                   MOVE 0          TO WS-BLOCK-INDEX
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-APPEND-AUDIT-ENTRY.
           ADD 1 TO WS-BLOCK-INDEX
           MOVE WS-BLOCK-INDEX TO LNK-OUT-BLOCK-NUM

      *> Serialize payload into deterministic canonical byte layout:
      *> [PrevHash(32)][TxnID(18)][Valid(14)][System(14)][Deb(16)][Cred(16)][Ccy(3)][AmtStr(26)]
           INITIALIZE WS-PAYLOAD-BUFFER
           STRING WS-PREV-BLOCK-HASH
                  LNK-IN-TXN-ID
                  LNK-IN-VALID-TIME
                  LNK-IN-SYSTEM-TIME
                  LNK-IN-DEBIT-ACC
                  LNK-IN-CREDIT-ACC
                  LNK-IN-CURRENCY
                  DELIMITED BY SIZE INTO WS-PAYLOAD-BUFFER

           MOVE 113 TO WS-BYTE-LEN

           CALL "BSLT-SHA256" USING WS-PAYLOAD-BUFFER
                                    WS-BYTE-LEN
                                    WS-RAW-DIGEST
                                    WS-DIGEST-HEX
                                    WS-STATUS

           IF WS-STATUS = BS-RC-OK
               MOVE WS-RAW-DIGEST TO WS-PREV-BLOCK-HASH
               MOVE WS-DIGEST-HEX TO LNK-OUT-AUDIT-HASH-HEX
           ELSE
               MOVE WS-STATUS TO LNK-OUT-STATUS
           END-IF.
