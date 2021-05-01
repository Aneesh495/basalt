      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - SLOTTED PAGE AND BUFFER POOL     *
      *> Page layout, slot directory, PageLSN, buffer frame management  *
      *>================================================================*
       01 BS-SLOTTED-PAGE.
          05 BS-PAGE-HEADER.
             10 BS-PG-ID                 PIC 9(8)  VALUE 0.
             10 BS-PG-LSN                PIC 9(18) VALUE 0.
             10 BS-PG-TYPE               PIC 9(2)  VALUE 1.
                88 BS-PG-TYPE-DATA       VALUE 1.
                88 BS-PG-TYPE-BTREE-ROOT VALUE 2.
                88 BS-PG-TYPE-BTREE-INT  VALUE 3.
                88 BS-PG-TYPE-BTREE-LEAF VALUE 4.
                88 BS-PG-TYPE-FREE       VALUE 5.
             10 BS-PG-PREV-ID            PIC 9(8)  VALUE 0.
             10 BS-PG-NEXT-ID            PIC 9(8)  VALUE 0.
             10 BS-PG-SLOT-COUNT         PIC 9(4)  VALUE 0.
             10 BS-PG-FREE-START         PIC 9(4)  VALUE 1.
             10 BS-PG-FREE-BYTES         PIC 9(4)  VALUE 3500.
             10 BS-PG-CHECKSUM           PIC 9(10) VALUE 0.
          05 BS-PAGE-SLOTS OCCURS 64 TIMES INDEXED BY BS-SLOT-IDX.
             10 BS-SLOT-OFFSET           PIC 9(4)  VALUE 0.
             10 BS-SLOT-LENGTH           PIC 9(4)  VALUE 0.
             10 BS-SLOT-DELETED          PIC 9(1)  VALUE 0.
          05 BS-PAGE-DATA                PIC X(3500) VALUE LOW-VALUES.

       01 BS-BUFFER-POOL.
          05 BS-BP-FRAME-COUNT           PIC 9(4)  VALUE 64.
          05 BS-BP-CLOCK-HAND            PIC 9(4)  VALUE 1.
          05 BS-BP-FRAMES OCCURS 64 TIMES INDEXED BY BS-FRM-IDX.
             10 BS-FRM-ID                PIC 9(4).
             10 BS-FRM-PAGE-ID           PIC 9(8).
             10 BS-FRM-DIRTY             PIC 9(1).
             10 BS-FRM-PIN-COUNT         PIC 9(4).
             10 BS-FRM-REF-BIT           PIC 9(1).
             10 BS-FRM-PAGE-LSN          PIC 9(18).
             10 BS-FRM-REC-LSN           PIC 9(18).
             10 BS-FRM-DATA              PIC X(4096).
