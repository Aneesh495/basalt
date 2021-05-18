       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-MERKLE.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - CRYPTOGRAPHIC MERKLE ACCUMULATOR*
      *> RFC 6962 tree builder, audit proof generator, proof verifier.  *
      *> Produces tamper-evident state commitments for settled batches. *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "merkle.cpy".

       01 WS-SCRATCH-BUFFERS.
          05 WS-PREFIX-LEAF              PIC X(1) VALUE X"00".
          05 WS-PREFIX-NODE              PIC X(1) VALUE X"01".
          05 WS-HASH-INPUT               PIC X(128) VALUE LOW-VALUES.
          05 WS-HASH-LEN                 USAGE BINARY-LONG UNSIGNED.
          05 WS-TEMP-DIGEST-BIN          PIC X(32) VALUE LOW-VALUES.
          05 WS-TEMP-DIGEST-HEX          PIC X(64) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.
          05 WS-CURR-HASH                PIC X(32) VALUE LOW-VALUES.

       01 WS-LOOP-COUNTERS.
          05 WS-LEVEL-START              PIC 9(4)  VALUE 0.
          05 WS-LEVEL-COUNT              PIC 9(4)  VALUE 0.
          05 WS-NEXT-LEVEL-START         PIC 9(4)  VALUE 0.
          05 WS-NEXT-COUNT               PIC 9(4)  VALUE 0.
          05 WS-I                        PIC 9(4)  VALUE 0.
          05 WS-J                        PIC 9(4)  VALUE 0.
          05 WS-LEFT-IDX                 PIC 9(4)  VALUE 0.
          05 WS-RIGHT-IDX                PIC 9(4)  VALUE 0.
          05 WS-CURR-IDX                 PIC 9(4)  VALUE 0.
          05 WS-PARENT-IDX               PIC 9(4)  VALUE 0.
          05 WS-STEP-IDX                 PIC 9(4)  VALUE 0.
          05 WS-FOUND                    PIC 9(1)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-MKL-OP                     PIC X(8).
       01 LNK-MKL-LEAF-COUNT             PIC 9(4).
       01 LNK-MKL-LEAF-DATA.
          05 LNK-LEAVES OCCURS 256 TIMES.
             10 LNK-LEAF-BYTES           PIC X(64).
       01 LNK-MKL-ROOT-OUT               PIC X(32).
       01 LNK-MKL-PROOF-LEAF-IDX         PIC 9(4).
       01 LNK-MKL-PROOF-OUT.
          05 LNK-PRF-LEAF-INDEX          PIC 9(4).
          05 LNK-PRF-LEAF-HASH           PIC X(32).
          05 LNK-PRF-DEPTH               PIC 9(2).
          05 LNK-PRF-STEPS OCCURS 16 TIMES.
             10 LNK-PRF-SIBLING          PIC X(32).
             10 LNK-PRF-DIR              PIC 9(1).
          05 LNK-PRF-ROOT-TO-CHECK       PIC X(32).
          05 LNK-PRF-IS-VALID            PIC 9(1).
       01 LNK-MKL-VERIFY-RESULT          PIC 9(1).
       01 LNK-MKL-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-MKL-OP LNK-MKL-LEAF-COUNT
                                LNK-MKL-LEAF-DATA LNK-MKL-ROOT-OUT
                                LNK-MKL-PROOF-LEAF-IDX LNK-MKL-PROOF-OUT
                                LNK-MKL-VERIFY-RESULT LNK-MKL-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-MKL-STATUS
           MOVE 0 TO LNK-MKL-VERIFY-RESULT

           EVALUATE LNK-MKL-OP
               WHEN "BUILD   "
                   PERFORM 1000-BUILD-TREE
               WHEN "PROOF   "
                   PERFORM 2000-GEN-PROOF
               WHEN "VERIFY  "
                   PERFORM 3000-VERIFY-PROOF
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-MKL-STATUS
           END-EVALUATE

           GOBACK.

       1000-BUILD-TREE.
           IF LNK-MKL-LEAF-COUNT = 0 OR LNK-MKL-LEAF-COUNT > 256
               MOVE BS-RC-INVALID-AMOUNT TO LNK-MKL-STATUS
               GOBACK
           END-IF

           MOVE LNK-MKL-LEAF-COUNT TO BS-MKL-LEAF-COUNT
           MOVE 0 TO BS-MKL-NODE-COUNT

      *> Hash all leaf nodes with 0x00 RFC 6962 domain separation
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-MKL-LEAF-COUNT
               ADD 1 TO BS-MKL-NODE-COUNT
               MOVE BS-MKL-NODE-COUNT TO WS-CURR-IDX
               MOVE WS-CURR-IDX TO BS-MKL-NODE-ID(WS-CURR-IDX)
               MOVE 0 TO BS-MKL-LEVEL(WS-CURR-IDX)
               MOVE 0 TO BS-MKL-LEFT-CHILD(WS-CURR-IDX)
               MOVE 0 TO BS-MKL-RIGHT-CHILD(WS-CURR-IDX)

               MOVE WS-PREFIX-LEAF TO WS-HASH-INPUT(1:1)
               MOVE LNK-LEAF-BYTES(WS-I) TO WS-HASH-INPUT(2:64)
               MOVE 65 TO WS-HASH-LEN

               CALL "BSLT-SHA256" USING WS-HASH-INPUT WS-HASH-LEN
                                        WS-TEMP-DIGEST-BIN 
                                        WS-TEMP-DIGEST-HEX WS-STATUS
               MOVE WS-TEMP-DIGEST-BIN TO BS-MKL-HASH(WS-CURR-IDX)
           END-PERFORM

      *> Iteratively construct parent tree levels with 0x01 prefix
           MOVE 1 TO WS-LEVEL-START
           MOVE LNK-MKL-LEAF-COUNT TO WS-LEVEL-COUNT

           PERFORM UNTIL WS-LEVEL-COUNT <= 1
               MOVE BS-MKL-NODE-COUNT TO WS-NEXT-LEVEL-START
               ADD 1 TO WS-NEXT-LEVEL-START
               MOVE 0 TO WS-NEXT-COUNT

               MOVE 0 TO WS-J
               PERFORM UNTIL WS-J >= WS-LEVEL-COUNT
                   COMPUTE WS-LEFT-IDX = WS-LEVEL-START + WS-J
                   IF WS-J + 1 < WS-LEVEL-COUNT
                       COMPUTE WS-RIGHT-IDX = WS-LEVEL-START + WS-J + 1
                   ELSE
      *> Odd leaf promoted or paired with itself
                       MOVE WS-LEFT-IDX TO WS-RIGHT-IDX
                   END-IF

                   ADD 1 TO BS-MKL-NODE-COUNT
                   ADD 1 TO WS-NEXT-COUNT
                   MOVE BS-MKL-NODE-COUNT TO WS-PARENT-IDX

                   MOVE WS-PARENT-IDX TO BS-MKL-NODE-ID(WS-PARENT-IDX)
                   MOVE WS-LEFT-IDX   TO BS-MKL-LEFT-CHILD(WS-PARENT-IDX)
                   MOVE WS-RIGHT-IDX  TO BS-MKL-RIGHT-CHILD(WS-PARENT-IDX)

                   MOVE WS-PREFIX-NODE TO WS-HASH-INPUT(1:1)
                   MOVE BS-MKL-HASH(WS-LEFT-IDX)  TO WS-HASH-INPUT(2:32)
                   MOVE BS-MKL-HASH(WS-RIGHT-IDX) TO WS-HASH-INPUT(34:32)
                   MOVE 65 TO WS-HASH-LEN

                   CALL "BSLT-SHA256" USING WS-HASH-INPUT WS-HASH-LEN
                                            WS-TEMP-DIGEST-BIN 
                                            WS-TEMP-DIGEST-HEX WS-STATUS
                   MOVE WS-TEMP-DIGEST-BIN TO BS-MKL-HASH(WS-PARENT-IDX)

                   ADD 2 TO WS-J
               END-PERFORM

               MOVE WS-NEXT-LEVEL-START TO WS-LEVEL-START
               MOVE WS-NEXT-COUNT TO WS-LEVEL-COUNT
           END-PERFORM

           MOVE BS-MKL-HASH(BS-MKL-NODE-COUNT) TO LNK-MKL-ROOT-OUT
           MOVE LNK-MKL-ROOT-OUT TO BS-MKL-ROOT-HASH.

       2000-GEN-PROOF.
      *> Build sibling audit trail from target leaf to root
           IF LNK-MKL-PROOF-LEAF-IDX < 1 OR 
              LNK-MKL-PROOF-LEAF-IDX > BS-MKL-LEAF-COUNT
               MOVE BS-RC-NOT-FOUND TO LNK-MKL-STATUS
               GOBACK
           END-IF

           MOVE 0 TO LNK-PRF-DEPTH
           MOVE LNK-MKL-PROOF-LEAF-IDX TO WS-CURR-IDX

      *> Climb from leaf to root finding sibling at each layer
           MOVE 0 TO WS-STEP-IDX
           PERFORM UNTIL WS-CURR-IDX = BS-MKL-NODE-COUNT
               MOVE 0 TO WS-FOUND
               PERFORM VARYING WS-I FROM 1 BY 1 
                       UNTIL WS-I > BS-MKL-NODE-COUNT
                   IF BS-MKL-LEFT-CHILD(WS-I) = WS-CURR-IDX
                       ADD 1 TO WS-STEP-IDX
                       MOVE BS-MKL-HASH(BS-MKL-RIGHT-CHILD(WS-I))
                           TO LNK-PRF-SIBLING(WS-STEP-IDX)
                       MOVE 2 TO LNK-PRF-DIR(WS-STEP-IDX)
                       MOVE WS-I TO WS-CURR-IDX
                       MOVE 1 TO WS-FOUND
                       EXIT PERFORM
                   ELSE
                       IF BS-MKL-RIGHT-CHILD(WS-I) = WS-CURR-IDX
                           ADD 1 TO WS-STEP-IDX
                           MOVE BS-MKL-HASH(BS-MKL-LEFT-CHILD(WS-I))
                               TO LNK-PRF-SIBLING(WS-STEP-IDX)
                           MOVE 1 TO LNK-PRF-DIR(WS-STEP-IDX)
                           MOVE WS-I TO WS-CURR-IDX
                           MOVE 1 TO WS-FOUND
                           EXIT PERFORM
                       END-IF
                   END-IF
               END-PERFORM
               IF WS-FOUND = 0 OR WS-STEP-IDX >= 16
                   EXIT PERFORM
               END-IF
           END-PERFORM

           MOVE WS-STEP-IDX TO LNK-PRF-DEPTH.

       3000-VERIFY-PROOF.
      *> Verify candidate leaf hash against root using sibling chain
           MOVE WS-PREFIX-LEAF TO WS-HASH-INPUT(1:1)
           MOVE LNK-LEAF-BYTES(LNK-MKL-PROOF-LEAF-IDX) 
               TO WS-HASH-INPUT(2:64)
           MOVE 65 TO WS-HASH-LEN

           CALL "BSLT-SHA256" USING WS-HASH-INPUT WS-HASH-LEN
                                    WS-CURR-HASH WS-TEMP-DIGEST-HEX 
                                    WS-STATUS

           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > LNK-PRF-DEPTH
               MOVE WS-PREFIX-NODE TO WS-HASH-INPUT(1:1)
               IF LNK-PRF-DIR(WS-I) = 1
      *> Sibling is on the left
                   MOVE LNK-PRF-SIBLING(WS-I) TO WS-HASH-INPUT(2:32)
                   MOVE WS-CURR-HASH TO WS-HASH-INPUT(34:32)
               ELSE
      *> Sibling is on the right
                   MOVE WS-CURR-HASH TO WS-HASH-INPUT(2:32)
                   MOVE LNK-PRF-SIBLING(WS-I) TO WS-HASH-INPUT(34:32)
               END-IF
               MOVE 65 TO WS-HASH-LEN
               CALL "BSLT-SHA256" USING WS-HASH-INPUT WS-HASH-LEN
                                        WS-CURR-HASH WS-TEMP-DIGEST-HEX 
                                        WS-STATUS
           END-PERFORM

           IF WS-CURR-HASH = LNK-MKL-ROOT-OUT
               MOVE 1 TO LNK-MKL-VERIFY-RESULT
               MOVE BS-RC-OK TO LNK-MKL-STATUS
           ELSE
               MOVE 0 TO LNK-MKL-VERIFY-RESULT
               MOVE BS-RC-MERKLE-INVALID TO LNK-MKL-STATUS
           END-IF.
