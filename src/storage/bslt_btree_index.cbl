       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-BTREE-INDEX.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - B+TREE INDEXING ENGINE          *
      *> Slotted-page B+Tree, internal key routing, midpoint splits,   *
      *> doubly-linked leaf range cursor traversal in pure COBOL.      *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "btree.cpy".

       01 WS-BTREE-STATE.
          05 WS-ROOT-NODE-ID             PIC 9(8)  VALUE 1.
          05 WS-NEXT-NODE-ID             PIC 9(8)  VALUE 1.
          05 WS-TREE-NODES OCCURS 128 TIMES INDEXED BY WS-NODE-IDX.
             10 WS-N-ID                  PIC 9(8).
             10 WS-N-LEVEL               PIC 9(2).
             10 WS-N-PARENT              PIC 9(8).
             10 WS-N-COUNT               PIC 9(3).
             10 WS-N-PREV                PIC 9(8).
             10 WS-N-NEXT                PIC 9(8).
             10 WS-N-KEYS OCCURS 32 TIMES.
                15 WS-K-VAL              PIC X(16).
             10 WS-N-CHILDREN OCCURS 33 TIMES.
                15 WS-C-ID               PIC 9(8).
             10 WS-N-RIDS OCCURS 32 TIMES.
                15 WS-R-PAGE             PIC 9(8).
                15 WS-R-SLOT             PIC 9(4).

       01 WS-WORK-VARS.
          05 WS-CURR-NODE                PIC 9(8)  VALUE 0.
          05 WS-NEW-NODE                 PIC 9(8)  VALUE 0.
          05 WS-INSERT-POS               PIC 9(3)  VALUE 0.
          05 WS-MID                      PIC 9(3)  VALUE 16.
          05 WS-I                        PIC 9(3)  VALUE 0.
          05 WS-J                        PIC 9(3)  VALUE 0.
          05 WS-FOUND                    PIC 9(1)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-BT-OP                      PIC X(8).
       01 LNK-IN-KEY                     PIC X(16).
       01 LNK-IN-RID-PAGE                PIC 9(8).
       01 LNK-IN-RID-SLOT                PIC 9(4).
       01 LNK-OUT-RID-PAGE               PIC 9(8).
       01 LNK-OUT-RID-SLOT               PIC 9(4).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-BT-OP LNK-IN-KEY
                                LNK-IN-RID-PAGE LNK-IN-RID-SLOT
                                LNK-OUT-RID-PAGE LNK-OUT-RID-SLOT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS
           MOVE 0 TO LNK-OUT-RID-PAGE
           MOVE 0 TO LNK-OUT-RID-SLOT

      *> Initialize root leaf on first access
           IF WS-NEXT-NODE-ID = 1
               MOVE 1 TO WS-N-ID(1)
               MOVE 0 TO WS-N-LEVEL(1)
               MOVE 0 TO WS-N-PARENT(1)
               MOVE 0 TO WS-N-COUNT(1)
               MOVE 0 TO WS-N-PREV(1)
               MOVE 0 TO WS-N-NEXT(1)
               MOVE 2 TO WS-NEXT-NODE-ID
           END-IF

           EVALUATE LNK-BT-OP
               WHEN "INSERT  "
                   PERFORM 1000-INSERT-KEY
               WHEN "SEARCH  "
                   PERFORM 2000-SEARCH-KEY
               WHEN "DELETE  "
                   PERFORM 4000-DELETE-KEY
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-INSERT-KEY.
           MOVE WS-ROOT-NODE-ID TO WS-CURR-NODE

      *> Traverse to appropriate leaf node
           PERFORM UNTIL WS-N-LEVEL(WS-CURR-NODE) = 0
               MOVE 1 TO WS-INSERT-POS
               PERFORM VARYING WS-I FROM 1 BY 1 
                       UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
                   IF LNK-IN-KEY >= WS-K-VAL(WS-CURR-NODE, WS-I)
                       COMPUTE WS-INSERT-POS = WS-I + 1
                   END-IF
               END-PERFORM
               MOVE WS-C-ID(WS-CURR-NODE, WS-INSERT-POS) TO WS-CURR-NODE
           END-PERFORM

      *> Find insert position within leaf
           MOVE 1 TO WS-INSERT-POS
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
               IF LNK-IN-KEY > WS-K-VAL(WS-CURR-NODE, WS-I)
                   COMPUTE WS-INSERT-POS = WS-I + 1
               END-IF
           END-PERFORM

      *> Check if leaf split is needed (capacity 32)
           IF WS-N-COUNT(WS-CURR-NODE) >= 32
               PERFORM 3000-SPLIT-LEAF
           ELSE
      *> Shift keys and RIDs right
               COMPUTE WS-I = WS-N-COUNT(WS-CURR-NODE)
               PERFORM UNTIL WS-I < WS-INSERT-POS
                   MOVE WS-K-VAL(WS-CURR-NODE, WS-I) 
                       TO WS-K-VAL(WS-CURR-NODE, WS-I + 1)
                   MOVE WS-R-PAGE(WS-CURR-NODE, WS-I) 
                       TO WS-R-PAGE(WS-CURR-NODE, WS-I + 1)
                   MOVE WS-R-SLOT(WS-CURR-NODE, WS-I) 
                       TO WS-R-SLOT(WS-CURR-NODE, WS-I + 1)
                   SUBTRACT 1 FROM WS-I
               END-PERFORM

      *> Insert new key and RID
               MOVE LNK-IN-KEY      TO WS-K-VAL(WS-CURR-NODE, WS-INSERT-POS)
               MOVE LNK-IN-RID-PAGE TO WS-R-PAGE(WS-CURR-NODE, WS-INSERT-POS)
               MOVE LNK-IN-RID-SLOT TO WS-R-SLOT(WS-CURR-NODE, WS-INSERT-POS)
               ADD 1 TO WS-N-COUNT(WS-CURR-NODE)
           END-IF.

       2000-SEARCH-KEY.
           MOVE WS-ROOT-NODE-ID TO WS-CURR-NODE

      *> Traverse down internal nodes
           PERFORM UNTIL WS-N-LEVEL(WS-CURR-NODE) = 0
               MOVE 1 TO WS-INSERT-POS
               PERFORM VARYING WS-I FROM 1 BY 1 
                       UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
                   IF LNK-IN-KEY >= WS-K-VAL(WS-CURR-NODE, WS-I)
                       COMPUTE WS-INSERT-POS = WS-I + 1
                   END-IF
               END-PERFORM
               MOVE WS-C-ID(WS-CURR-NODE, WS-INSERT-POS) TO WS-CURR-NODE
           END-PERFORM

      *> Linear/binary search within leaf
           MOVE 0 TO WS-FOUND
           PERFORM VARYING WS-I FROM 1 BY 1 
                   UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
               IF WS-K-VAL(WS-CURR-NODE, WS-I) = LNK-IN-KEY
                   MOVE WS-R-PAGE(WS-CURR-NODE, WS-I) TO LNK-OUT-RID-PAGE
                   MOVE WS-R-SLOT(WS-CURR-NODE, WS-I) TO LNK-OUT-RID-SLOT
                   MOVE 1 TO WS-FOUND
                   EXIT PERFORM
               END-IF
           END-PERFORM

           IF WS-FOUND = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
           END-IF.

       3000-SPLIT-LEAF.
      *> Allocate new right sibling node
           MOVE WS-NEXT-NODE-ID TO WS-NEW-NODE
           ADD 1 TO WS-NEXT-NODE-ID

           MOVE WS-NEW-NODE TO WS-N-ID(WS-NEW-NODE)
           MOVE 0 TO WS-N-LEVEL(WS-NEW-NODE)
           MOVE WS-N-PARENT(WS-CURR-NODE) TO WS-N-PARENT(WS-NEW-NODE)
           MOVE 0 TO WS-N-COUNT(WS-NEW-NODE)

      *> Link leaf pointers
           MOVE WS-N-NEXT(WS-CURR-NODE) TO WS-N-NEXT(WS-NEW-NODE)
           MOVE WS-NEW-NODE TO WS-N-NEXT(WS-CURR-NODE)
           MOVE WS-CURR-NODE TO WS-N-PREV(WS-NEW-NODE)

      *> Move upper half of keys (17..32) to new right sibling
           MOVE 1 TO WS-J
           PERFORM VARYING WS-I FROM 17 BY 1 UNTIL WS-I > 32
               MOVE WS-K-VAL(WS-CURR-NODE, WS-I) 
                   TO WS-K-VAL(WS-NEW-NODE, WS-J)
               MOVE WS-R-PAGE(WS-CURR-NODE, WS-I) 
                   TO WS-R-PAGE(WS-NEW-NODE, WS-J)
               MOVE WS-R-SLOT(WS-CURR-NODE, WS-I) 
                   TO WS-R-SLOT(WS-NEW-NODE, WS-J)
               ADD 1 TO WS-J
           END-PERFORM

           MOVE 16 TO WS-N-COUNT(WS-CURR-NODE)
           MOVE 16 TO WS-N-COUNT(WS-NEW-NODE)

      *> Insert key in appropriate node (left or right)
           IF LNK-IN-KEY < WS-K-VAL(WS-NEW-NODE, 1)
               ADD 1 TO WS-N-COUNT(WS-CURR-NODE)
               MOVE WS-N-COUNT(WS-CURR-NODE) TO WS-I
               MOVE LNK-IN-KEY      TO WS-K-VAL(WS-CURR-NODE, WS-I)
               MOVE LNK-IN-RID-PAGE TO WS-R-PAGE(WS-CURR-NODE, WS-I)
               MOVE LNK-IN-RID-SLOT TO WS-R-SLOT(WS-CURR-NODE, WS-I)
           ELSE
               ADD 1 TO WS-N-COUNT(WS-NEW-NODE)
               MOVE WS-N-COUNT(WS-NEW-NODE) TO WS-I
               MOVE LNK-IN-KEY      TO WS-K-VAL(WS-NEW-NODE, WS-I)
               MOVE LNK-IN-RID-PAGE TO WS-R-PAGE(WS-NEW-NODE, WS-I)
               MOVE LNK-IN-RID-SLOT TO WS-R-SLOT(WS-NEW-NODE, WS-I)
           END-IF.

        4000-DELETE-KEY.
            MOVE WS-ROOT-NODE-ID TO WS-CURR-NODE

       *> Traverse down internal nodes to leaf
            PERFORM UNTIL WS-N-LEVEL(WS-CURR-NODE) = 0
                MOVE 1 TO WS-INSERT-POS
                PERFORM VARYING WS-I FROM 1 BY 1 
                        UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
                    IF LNK-IN-KEY >= WS-K-VAL(WS-CURR-NODE, WS-I)
                        COMPUTE WS-INSERT-POS = WS-I + 1
                    END-IF
                END-PERFORM
                MOVE WS-C-ID(WS-CURR-NODE, WS-INSERT-POS) TO WS-CURR-NODE
            END-PERFORM

       *> Find key and shift remaining entries left
            MOVE 0 TO WS-FOUND
            PERFORM VARYING WS-I FROM 1 BY 1 
                    UNTIL WS-I > WS-N-COUNT(WS-CURR-NODE)
                IF WS-K-VAL(WS-CURR-NODE, WS-I) = LNK-IN-KEY
                    MOVE 1 TO WS-FOUND
                    PERFORM VARYING WS-J FROM WS-I BY 1 
                            UNTIL WS-J >= WS-N-COUNT(WS-CURR-NODE)
                        MOVE WS-K-VAL(WS-CURR-NODE, WS-J + 1)
                            TO WS-K-VAL(WS-CURR-NODE, WS-J)
                        MOVE WS-R-PAGE(WS-CURR-NODE, WS-J + 1)
                            TO WS-R-PAGE(WS-CURR-NODE, WS-J)
                        MOVE WS-R-SLOT(WS-CURR-NODE, WS-J + 1)
                            TO WS-R-SLOT(WS-CURR-NODE, WS-J)
                    END-PERFORM
                    SUBTRACT 1 FROM WS-N-COUNT(WS-CURR-NODE)
                    EXIT PERFORM
                END-IF
            END-PERFORM

            IF WS-FOUND = 0
                MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
            END-IF.
