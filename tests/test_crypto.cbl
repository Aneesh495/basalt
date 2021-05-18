       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-CRYPTO.
      *>================================================================*
      *> BASALT TEST SUITE - CRYPTOGRAPHIC INTEGRITY VERIFICATION       *
      *> NIST FIPS 180-4 test vectors for SHA-256 and RFC 6962 Merkle  *
      *> audit proof generation, verification, and tamper detection.   *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "merkle.cpy".

       01 WS-TEST-BUFFERS.
          05 WS-EMPTY-STR                PIC X(1)  VALUE LOW-VALUES.
          05 WS-ABC-STR                  PIC X(3)  VALUE "abc".
          05 WS-56BYTE-STR               PIC X(56) VALUE 
             "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq".
          05 WS-BIN-OUT                  PIC X(32) VALUE LOW-VALUES.
          05 WS-HEX-OUT                  PIC X(64) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-LEAF-COUNT               PIC 9(4)  VALUE 4.
          05 WS-ROOT-OUT                 PIC X(32) VALUE LOW-VALUES.
          05 WS-ROOT-HEX                 PIC X(64) VALUE SPACES.
          05 WS-VERIFY-RESULT            PIC 9(1)  VALUE 0.
          05 WS-TARGET-LEAF-IDX          PIC 9(4)  VALUE 2.

       01 WS-SAMPLE-LEAVES.
          05 WS-L1                       PIC X(64) VALUE "MEMBER_BNP_DEPOSIT".
          05 WS-L2                       PIC X(64) VALUE "MEMBER_DB_WITHDRAW".
          05 WS-L3                       PIC X(64) VALUE "SETTLEMENT_ORDER_1".
          05 WS-L4                       PIC X(64) VALUE "MARGIN_CALL_POSTED".

       01 WS-CORRUPT-LEAVES.
          05 WS-C1                       PIC X(64) VALUE "MEMBER_BNP_DEPOSIT".
          05 WS-C2                       PIC X(64) VALUE "MEMBER_DB_TAMPERED".
          05 WS-C3                       PIC X(64) VALUE "SETTLEMENT_ORDER_1".
          05 WS-C4                       PIC X(64) VALUE "MARGIN_CALL_POSTED".

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> TEST 1: NIST FIPS 180-4 Vector: Empty string
           CALL "BSLT-SHA256" USING WS-EMPTY-STR 0
                                    WS-BIN-OUT WS-HEX-OUT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND
              WS-HEX-OUT = 
              "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NIST SHA-256 Empty string mismatch: " WS-HEX-OUT
           END-IF

      *> TEST 2: NIST FIPS 180-4 Vector: "abc"
           CALL "BSLT-SHA256" USING WS-ABC-STR 3
                                    WS-BIN-OUT WS-HEX-OUT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND
              WS-HEX-OUT = 
              "ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad"
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NIST SHA-256 'abc' mismatch: " WS-HEX-OUT
           END-IF

      *> TEST 3: NIST FIPS 180-4 Vector: 56-byte string
           CALL "BSLT-SHA256" USING WS-56BYTE-STR 56
                                    WS-BIN-OUT WS-HEX-OUT WS-STATUS
           IF WS-STATUS = BS-RC-OK AND
              WS-HEX-OUT = 
              "248d6a61d20638b8e5c026930c3e6039a33ce45964ff2167f6ecedd419db06c1"
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: NIST SHA-256 56-byte mismatch: " WS-HEX-OUT
           END-IF

      *> TEST 4: Merkle Tree Construction
           CALL "BSLT-MERKLE" USING "BUILD   "
                                    WS-LEAF-COUNT
                                    WS-SAMPLE-LEAVES
                                    WS-ROOT-OUT
                                    WS-TARGET-LEAF-IDX
                                    BS-MERKLE-PROOF
                                    WS-VERIFY-RESULT
                                    WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-ROOT-OUT NOT = LOW-VALUES
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Merkle tree construction failed."
           END-IF

      *> TEST 5: Merkle Audit Proof Generation for Leaf 2
           CALL "BSLT-MERKLE" USING "PROOF   "
                                    WS-LEAF-COUNT
                                    WS-SAMPLE-LEAVES
                                    WS-ROOT-OUT
                                    WS-TARGET-LEAF-IDX
                                    BS-MERKLE-PROOF
                                    WS-VERIFY-RESULT
                                    WS-STATUS
           IF WS-STATUS = BS-RC-OK AND BS-PRF-DEPTH > 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Merkle proof generation failed."
           END-IF

      *> TEST 6: Merkle Proof Verification against Root
           CALL "BSLT-MERKLE" USING "VERIFY  "
                                    WS-LEAF-COUNT
                                    WS-SAMPLE-LEAVES
                                    WS-ROOT-OUT
                                    WS-TARGET-LEAF-IDX
                                    BS-MERKLE-PROOF
                                    WS-VERIFY-RESULT
                                    WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-VERIFY-RESULT = 1
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Merkle proof verification failed."
           END-IF

      *> TEST 7: Merkle Proof Tamper Detection
           CALL "BSLT-MERKLE" USING "VERIFY  "
                                    WS-LEAF-COUNT
                                    WS-CORRUPT-LEAVES
                                    WS-ROOT-OUT
                                    WS-TARGET-LEAF-IDX
                                    BS-MERKLE-PROOF
                                    WS-VERIFY-RESULT
                                    WS-STATUS
           IF WS-VERIFY-RESULT = 0
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Tampered Merkle proof was erroneously accepted."
           END-IF.

           GOBACK.
