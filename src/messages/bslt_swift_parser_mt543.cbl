       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-SWIFT-PARSER-MT543.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SWIFT MT541/MT543 PARSER         *
      *> Deliver Against Payment (DVP) and Receive Against Payment (RVP)*
      *> securities settlement message de-serialization.                *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "swift.cpy".

       01 WS-PARSE-STATE.
          05 WS-POS                      PIC 9(6)  VALUE 1.
          05 WS-START-POS                PIC 9(6)  VALUE 0.
          05 WS-END-POS                  PIC 9(6)  VALUE 0.
          05 WS-EXTRACTED-VAL            PIC X(64) VALUE SPACES.
          05 WS-FOUND-TAG                PIC 9(1)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-IN-MT543-TEXT              PIC X(2048).
       01 LNK-OUT-TXN-REF                PIC X(16).
       01 LNK-OUT-ISIN                   PIC X(12).
       01 LNK-OUT-SETT-QTY               PIC 9(12).
       01 LNK-OUT-SETT-AMOUNT            PIC S9(18)V9(8) COMP-3.
       01 LNK-OUT-SETT-CURRENCY          PIC X(3).
       01 LNK-OUT-SETT-DATE              PIC 9(8).
       01 LNK-OUT-SELLER-BIC             PIC X(11).
       01 LNK-OUT-BUYER-BIC              PIC X(11).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-IN-MT543-TEXT
                                LNK-OUT-TXN-REF LNK-OUT-ISIN
                                LNK-OUT-SETT-QTY LNK-OUT-SETT-AMOUNT
                                LNK-OUT-SETT-CURRENCY LNK-OUT-SETT-DATE
                                LNK-OUT-SELLER-BIC LNK-OUT-BUYER-BIC
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE SPACES   TO LNK-OUT-TXN-REF
           MOVE SPACES   TO LNK-OUT-ISIN
           MOVE 0        TO LNK-OUT-SETT-QTY
           MOVE 0        TO LNK-OUT-SETT-AMOUNT
           MOVE "USD"    TO LNK-OUT-SETT-CURRENCY
           MOVE 0        TO LNK-OUT-SETT-DATE
           MOVE SPACES   TO LNK-OUT-SELLER-BIC
           MOVE SPACES   TO LNK-OUT-BUYER-BIC

      *> 1. Extract Transaction Reference :20C::SETR//
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:13) = ":20C::SETR//"
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 13:16) TO LNK-OUT-TXN-REF
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 2. Extract ISIN :35B:ISIN 
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:10) = ":35B:ISIN "
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 10:12) TO LNK-OUT-ISIN
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 3. Extract Settlement Date :98A::SETT//
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:13) = ":98A::SETT//"
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 13:8) TO LNK-OUT-SETT-DATE
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 4. Extract Settlement Quantity :36B::SETT//FAMT/
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:18) = ":36B::SETT//FAMT/"
                   COMPUTE LNK-OUT-SETT-QTY = 
                       FUNCTION NUMVAL(LNK-IN-MT543-TEXT(WS-POS + 18:12))
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 5. Extract Settlement Amount :19A::PSET//
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:13) = ":19A::PSET//"
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 13:3) TO LNK-OUT-SETT-CURRENCY
                   COMPUTE LNK-OUT-SETT-AMOUNT = 
                       FUNCTION NUMVAL(LNK-IN-MT543-TEXT(WS-POS + 16:16))
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 6. Extract Seller BIC :95P::SELL//
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:13) = ":95P::SELL//"
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 13:11) TO LNK-OUT-SELLER-BIC
                   EXIT PERFORM
               END-IF
           END-PERFORM

      *> 7. Extract Buyer BIC :95P::BUYR//
           PERFORM VARYING WS-POS FROM 1 BY 1 UNTIL WS-POS > 1900
               IF LNK-IN-MT543-TEXT(WS-POS:13) = ":95P::BUYR//"
                   MOVE LNK-IN-MT543-TEXT(WS-POS + 13:11) TO LNK-OUT-BUYER-BIC
                   EXIT PERFORM
               END-IF
           END-PERFORM

           GOBACK.
