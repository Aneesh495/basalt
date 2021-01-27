      *================================================================*
      * BASALT CLEARINGHOUSE ENGINE - B+TREE INDEX SCHEMAS             *
      * Node layout, key slots, child pointers, cursor range iterators *
      *================================================================*
       01 BS-BTREE-NODE.
          05 BS-BT-NODE-ID               PIC 9(8)  VALUE 0.
          05 BS-BT-LEVEL                 PIC 9(2)  VALUE 0.
             88 BS-BT-IS-LEAF            VALUE 0.
             88 BS-BT-IS-INTERNAL        VALUE 1 THRU 99.
          05 BS-BT-PARENT-ID             PIC 9(8)  VALUE 0.
          05 BS-BT-KEY-COUNT             PIC 9(3)  VALUE 0.
          05 BS-BT-PREV-LEAF             PIC 9(8)  VALUE 0.
          05 BS-BT-NEXT-LEAF             PIC 9(8)  VALUE 0.
          05 BS-BT-KEYS OCCURS 32 TIMES INDEXED BY BS-BT-KIDX.
             10 BS-BT-KEY-VAL            PIC X(16) VALUE SPACES.
          05 BS-BT-CHILDREN OCCURS 33 TIMES INDEXED BY BS-BT-CIDX.
             10 BS-BT-CHILD-ID           PIC 9(8)  VALUE 0.
          05 BS-BT-LEAF-RIDS OCCURS 32 TIMES INDEXED BY BS-BT-RIDX.
             10 BS-BT-RID-PAGE           PIC 9(8)  VALUE 0.
             10 BS-BT-RID-SLOT           PIC 9(4)  VALUE 0.

       01 BS-BTREE-SEARCH-REQ.
          05 BS-BT-SEARCH-KEY            PIC X(16) VALUE SPACES.
          05 BS-BT-SEARCH-MODE           PIC 9(1)  VALUE 1.
             88 BS-BT-MODE-EXACT         VALUE 1.
             88 BS-BT-MODE-RANGE-START   VALUE 2.
             88 BS-BT-MODE-RANGE-END     VALUE 3.

       01 BS-BTREE-CURSOR.
          05 BS-CUR-NODE-ID              PIC 9(8)  VALUE 0.
          05 BS-CUR-SLOT-IDX             PIC 9(3)  VALUE 0.
          05 BS-CUR-KEY                  PIC X(16) VALUE SPACES.
          05 BS-CUR-RID-PAGE             PIC 9(8)  VALUE 0.
          05 BS-CUR-RID-SLOT             PIC 9(4)  VALUE 0.
          05 BS-CUR-FOUND                PIC 9(1)  VALUE 0.
          05 BS-CUR-EOF                  PIC 9(1)  VALUE 0.

       01 BS-BTREE-SPLIT-STATE.
          05 BS-SPLIT-LEFT-ID            PIC 9(8)  VALUE 0.
          05 BS-SPLIT-RIGHT-ID           PIC 9(8)  VALUE 0.
          05 BS-SPLIT-PROMOTED-KEY       PIC X(16) VALUE SPACES.
          05 BS-SPLIT-MID-INDEX          PIC 9(3)  VALUE 16.
