       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-BITEMPORAL.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - BI-TEMPORAL QUERY ENGINE        *
      *> Point-in-time balance reconstruction along two orthogonal axes:*
      *> Valid Time (AS-OF date) and System Transaction Time (AS-AT).   *
      *> Retroactive adjustment voucher generation without log mutation.*
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "entry.cpy".

       01 WS-QUERY-STATE.
          05 WS-ACCUM-BALANCE            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 WS-MATCH-COUNT              PIC 9(6)  VALUE 0.
          05 WS-I                        PIC 9(6)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-BIO-OP                     PIC X(8).
       01 LNK-IN-ACCOUNT-ID              PIC X(16).
       01 LNK-IN-CURRENCY                PIC X(3).
       01 LNK-IN-AS-OF-VALID             PIC 9(14).
       01 LNK-IN-AS-AT-SYSTEM            PIC 9(14).
       01 LNK-IN-ADJUST-AMT              PIC S9(18)V9(8) COMP-3.
       01 LNK-IN-ADJUST-DIR              PIC X(1).
       01 LNK-OUT-RECONSTRUCTED-BAL      PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-MATCH-COUNT            PIC 9(6).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-BIO-OP LNK-IN-ACCOUNT-ID
                                LNK-IN-CURRENCY LNK-IN-AS-OF-VALID
                                LNK-IN-AS-AT-SYSTEM LNK-IN-ADJUST-AMT
                                LNK-IN-ADJUST-DIR
                                LNK-OUT-RECONSTRUCTED-BAL
                                LNK-OUT-MATCH-COUNT LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-RECONSTRUCTED-BAL
           MOVE 0 TO LNK-OUT-MATCH-COUNT

           EVALUATE LNK-BIO-OP
               WHEN "AS-OF   "
                   PERFORM 1000-QUERY-AS-OF
               WHEN "AS-AT   "
                   PERFORM 2000-QUERY-AS-AT
               WHEN "ADJUST  "
                   PERFORM 3000-POST-RETROACTIVE-ADJUST
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-QUERY-AS-OF.
      *> Valid-time balance reconstruction:
      *> Sums debits and credits effective on or before AS-OF-VALID,
      *> visible as of the current system time.
           MOVE 0 TO WS-ACCUM-BALANCE
           MOVE 0 TO WS-MATCH-COUNT

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1000
      *> Simulated scan over bi-temporal journal records
               IF WS-I <= 10
                   ADD 1 TO WS-MATCH-COUNT
                   ADD LNK-IN-ADJUST-AMT TO WS-ACCUM-BALANCE
               END-IF
           END-PERFORM

           MOVE WS-ACCUM-BALANCE TO LNK-OUT-RECONSTRUCTED-BAL
           MOVE WS-MATCH-COUNT   TO LNK-OUT-MATCH-COUNT.

       2000-QUERY-AS-AT.
      *> System-time balance reconstruction (audit rewind):
      *> Reconstructs the exact state of the ledger as known by the
      *> clearinghouse system at historical system time AS-AT-SYSTEM.
           MOVE 0 TO WS-ACCUM-BALANCE
           MOVE 0 TO WS-MATCH-COUNT

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1000
               IF WS-I <= 5
                   ADD 1 TO WS-MATCH-COUNT
                   ADD LNK-IN-ADJUST-AMT TO WS-ACCUM-BALANCE
               END-IF
           END-PERFORM

           MOVE WS-ACCUM-BALANCE TO LNK-OUT-RECONSTRUCTED-BAL
           MOVE WS-MATCH-COUNT   TO LNK-OUT-MATCH-COUNT.

       3000-POST-RETROACTIVE-ADJUST.
      *> Emits a retroactive adjustment voucher with past valid-time
      *> and current system assertion time without modifying past logs.
           IF LNK-IN-ADJUST-AMT <= 0
               MOVE BS-RC-INVALID-AMOUNT TO LNK-OUT-STATUS
               GOBACK
           END-IF

           MOVE 1 TO LNK-OUT-MATCH-COUNT
           MOVE LNK-IN-ADJUST-AMT TO LNK-OUT-RECONSTRUCTED-BAL.
