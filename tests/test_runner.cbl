       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-TEST-RUNNER.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - UNIFIED TEST SUITE RUNNER       *
      *> Automated verification framework: runs mathematical, ledger,  *
      *> netting, risk, ARIES recovery, and protocol message test suites.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".

       01 WS-RUNNER-STATE.
          05 WS-TOTAL-RUN                PIC 9(4)  VALUE 0.
          05 WS-TOTAL-PASSED             PIC 9(4)  VALUE 0.
          05 WS-TOTAL-FAILED             PIC 9(4)  VALUE 0.
          05 WS-SUB-PASSED               PIC 9(4)  VALUE 0.
          05 WS-SUB-FAILED               PIC 9(4)  VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY " "
           DISPLAY "+========================================================+"
           DISPLAY "|          BASALT CLEARINGHOUSE VERIFICATION SUITE       |"
           DISPLAY "|  Automated Subsystem Validation and Property Testing   |"
           DISPLAY "+========================================================+"
           DISPLAY " "

      *> 1. Fixed Math Test Suite
           DISPLAY "--> Running [1/14] 128-bit Fixed Decimal Math Verification..."
           CALL "TEST-FIXED-MATH" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 2. SHA-256 and Merkle Test Suite
           DISPLAY "--> Running [2/14] SHA-256 and Merkle Audit Tree Tests..."
           CALL "TEST-CRYPTO" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 3. Bi-Temporal Ledger Test Suite
           DISPLAY "--> Running [3/14] Bi-Temporal Double-Entry Ledger Tests..."
           CALL "TEST-LEDGER" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 4. Multilateral Netting Test Suite
           DISPLAY "--> Running [4/14] Directed Cycle Netting and Gridlock Tests..."
           CALL "TEST-NETTING" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 5. Portfolio Risk and VaR Test Suite
           DISPLAY "--> Running [5/14] SPAN Margining, VaR, and CVaR Tests..."
           CALL "TEST-RISK" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 6. Buffer Pool and Storage Test Suite
           DISPLAY "--> Running [6/14] Buffer Pool and Slotted Page Tests..."
           CALL "TEST-STORAGE" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 7. B+Tree Index Test Suite
           DISPLAY "--> Running [7/14] B+Tree Slotted Index and Split Tests..."
           CALL "TEST-BTREE" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 8. ARIES Crash Recovery Test Suite
           DISPLAY "--> Running [8/14] ARIES Three-Pass Crash Recovery Tests..."
           CALL "TEST-RECOVERY" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 9. Day-Count Conventions Test Suite
           DISPLAY "--> Running [9/14] ISDA Day-Count Algebra Tests..."
           CALL "TEST-DAYCOUNT" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 10. Financial Contracts Test Suite
           DISPLAY "--> Running [10/14] ACTUS Bond, Swap, and CDS Contract Tests..."
           CALL "TEST-CONTRACTS" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 11. Financial Messaging Test Suite
           DISPLAY "--> Running [11/14] ISO 20022, FIX, and SWIFT Protocol Tests..."
           CALL "TEST-MESSAGES" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 12. Fuzzing and Invariant Conservation Test Suite
           DISPLAY "--> Running [12/14] High-Volume Fuzzing and Double-Entry Invariants..."
           CALL "TEST-FUZZ" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 13. CPMI-IOSCO Default Waterfall and Margining Test Suite
           DISPLAY "--> Running [13/14] Default Waterfall and Margin Call Tests..."
           CALL "TEST-WATERFALL" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> 14. Tamper-Evident Chained Audit Journal Test Suite
           DISPLAY "--> Running [14/14] Chained Audit Log and Merkle Tree Tests..."
           CALL "TEST-AUDIT" USING WS-SUB-PASSED WS-SUB-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-PASSED
           ADD WS-SUB-FAILED TO WS-TOTAL-FAILED
           ADD WS-SUB-PASSED TO WS-TOTAL-RUN
           ADD WS-SUB-FAILED TO WS-TOTAL-RUN

      *> Print final scorecard
           DISPLAY " "
           DISPLAY "+========================================================+"
           DISPLAY "|                  TEST EXECUTION SUMMARY                |"
           DISPLAY "+========================================================+"
           DISPLAY " Total Test Assertions Executed : " WS-TOTAL-RUN
           DISPLAY " Total Assertions Passed        : " WS-TOTAL-PASSED
           DISPLAY " Total Assertions Failed        : " WS-TOTAL-FAILED

           IF WS-TOTAL-FAILED = 0
               DISPLAY " RESULT : ALL SUBSYSTEM TESTS PASSED WITH ZERO ERRORS."
               DISPLAY "+========================================================+"
               DISPLAY " "
                MOVE 0 TO RETURN-CODE
               STOP RUN
           ELSE
               DISPLAY " RESULT : TEST SUITE DETECTED FAILURES."
               DISPLAY "+========================================================+"
               DISPLAY " "
               MOVE 1 TO RETURN-CODE
               STOP RUN
           END-IF.
