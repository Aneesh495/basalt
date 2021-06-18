       IDENTIFICATION DIVISION.
       PROGRAM-ID. TEST-AUDIT.
      *>================================================================*
      *> BASALT TEST SUITE - TAMPER-EVIDENT AUDIT JOURNAL TESTS         *
      *> Chained SHA-256 block hashing, sequential integrity, and       *
      *> cryptographic non-repudiation verification.                    *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "merkle.cpy".

       01 WS-AUDIT-TEST-VARS.
          05 WS-TXN-ID                   PIC 9(18) VALUE 100001.
          05 WS-VAL-TIME                 PIC 9(14) VALUE 20261015120000.
          05 WS-SYS-TIME                 PIC 9(14) VALUE 20261015120001.
          05 WS-DEB-ACC                  PIC X(16) VALUE "ACC-CHAS-0001   ".
          05 WS-CRED-ACC                 PIC X(16) VALUE "ACC-CITI-0001   ".
          05 WS-AMT                      PIC S9(18)V9(8) COMP-3 VALUE 1000000.00000000.
          05 WS-CCY                      PIC X(3)  VALUE "USD".
          05 WS-HASH-1                   PIC X(64) VALUE SPACES.
          05 WS-HASH-2                   PIC X(64) VALUE SPACES.
          05 WS-BLOCK-NUM                PIC 9(10) VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-TESTS-PASSED               PIC 9(4).
       01 LNK-TESTS-FAILED               PIC 9(4).

       PROCEDURE DIVISION USING LNK-TESTS-PASSED LNK-TESTS-FAILED.
       0000-MAIN.
           MOVE 0 TO LNK-TESTS-PASSED
           MOVE 0 TO LNK-TESTS-FAILED

      *> Reset audit log state
           CALL "BSLT-AUDIT-LOG" USING "RESET   "
                                       WS-TXN-ID
                                       WS-VAL-TIME
                                       WS-SYS-TIME
                                       WS-DEB-ACC
                                       WS-CRED-ACC
                                       WS-AMT
                                       WS-CCY
                                       WS-HASH-1
                                       WS-BLOCK-NUM
                                       WS-STATUS

      *>----------------------------------------------------------------*
      *> TEST 1: Append Block 1 to empty chain
      *>----------------------------------------------------------------*
           CALL "BSLT-AUDIT-LOG" USING "APPEND  "
                                       WS-TXN-ID
                                       WS-VAL-TIME
                                       WS-SYS-TIME
                                       WS-DEB-ACC
                                       WS-CRED-ACC
                                       WS-AMT
                                       WS-CCY
                                       WS-HASH-1
                                       WS-BLOCK-NUM
                                       WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-BLOCK-NUM = 1 AND WS-HASH-1 NOT = SPACES
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Audit log block 1 append failed"
           END-IF

      *>----------------------------------------------------------------*
      *> TEST 2: Append Block 2, verify hash chaining differs from block 1
      *>----------------------------------------------------------------*
           ADD 1 TO WS-TXN-ID
           MOVE 2500000.00000000 TO WS-AMT
           CALL "BSLT-AUDIT-LOG" USING "APPEND  "
                                       WS-TXN-ID
                                       WS-VAL-TIME
                                       WS-SYS-TIME
                                       WS-DEB-ACC
                                       WS-CRED-ACC
                                       WS-AMT
                                       WS-CCY
                                       WS-HASH-2
                                       WS-BLOCK-NUM
                                       WS-STATUS
           IF WS-STATUS = BS-RC-OK AND WS-BLOCK-NUM = 2 
              AND WS-HASH-2 NOT = SPACES AND WS-HASH-2 NOT = WS-HASH-1
               ADD 1 TO LNK-TESTS-PASSED
           ELSE
               ADD 1 TO LNK-TESTS-FAILED
               DISPLAY "FAIL: Audit log block 2 chaining failed"
           END-IF

           GOBACK.
