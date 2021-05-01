      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - ARIES WAL RECORD SCHEMAS         *
      *> Physiological logging, LSN chains, CLR records, checkpoints    *
      *>================================================================*
       01 BS-WAL-RECORD.
          05 BS-WAL-LSN                  PIC 9(18) VALUE 0.
          05 BS-WAL-PREV-LSN             PIC 9(18) VALUE 0.
          05 BS-WAL-TX-ID                PIC 9(12) VALUE 0.
          05 BS-WAL-TYPE                 PIC 9(2)  VALUE 1.
             88 BS-WAL-TYPE-BEGIN        VALUE 1.
             88 BS-WAL-TYPE-UPDATE       VALUE 2.
             88 BS-WAL-TYPE-COMMIT       VALUE 3.
             88 BS-WAL-TYPE-ABORT        VALUE 4.
             88 BS-WAL-TYPE-CLR          VALUE 5.
             88 BS-WAL-TYPE-CHKPT-START  VALUE 6.
             88 BS-WAL-TYPE-CHKPT-END    VALUE 7.
             88 BS-WAL-TYPE-ALLOC        VALUE 8.
          05 BS-WAL-PAGE-ID              PIC 9(8)  VALUE 0.
          05 BS-WAL-SLOT-ID              PIC 9(4)  VALUE 0.
          05 BS-WAL-OFFSET               PIC 9(6)  VALUE 0.
          05 BS-WAL-LENGTH               PIC 9(4)  VALUE 0.
          05 BS-WAL-UNDO-NEXT-LSN        PIC 9(18) VALUE 0.
          05 BS-WAL-BEFORE-IMAGE         PIC X(256) VALUE LOW-VALUES.
          05 BS-WAL-AFTER-IMAGE          PIC X(256) VALUE LOW-VALUES.
          05 BS-WAL-CRC32                PIC 9(10) VALUE 0.

       01 BS-CHECKPOINT-DIRTY-PAGES.
          05 BS-DPT-COUNT                PIC 9(4)  VALUE 0.
          05 BS-DPT-ENTRY OCCURS 128 TIMES INDEXED BY BS-DPT-IDX.
             10 BS-DPT-PAGE-ID           PIC 9(8).
             10 BS-DPT-REC-LSN           PIC 9(18).

       01 BS-CHECKPOINT-ACTIVE-TXS.
          05 BS-ATT-COUNT                PIC 9(4)  VALUE 0.
          05 BS-ATT-ENTRY OCCURS 64 TIMES INDEXED BY BS-ATT-IDX.
             10 BS-ATT-TX-ID             PIC 9(12).
             10 BS-ATT-STATUS            PIC 9(1).
                88 BS-ATT-STAT-ACTIVE    VALUE 1.
                88 BS-ATT-STAT-COMMITTED VALUE 2.
                88 BS-ATT-STAT-ABORTING  VALUE 3.
             10 BS-ATT-LAST-LSN          PIC 9(18).
             10 BS-ATT-UNDO-NEXT-LSN     PIC 9(18).

       01 BS-RECOVERY-STATE.
          05 BS-REC-CHECKPOINT-LSN       PIC 9(18) VALUE 0.
          05 BS-REC-MIN-REC-LSN          PIC 9(18) VALUE 0.
          05 BS-REC-ANALYSIS-COMPLETE    PIC 9(1)  VALUE 0.
          05 BS-REC-REDO-COMPLETE        PIC 9(1)  VALUE 0.
          05 BS-REC-UNDO-COMPLETE        PIC 9(1)  VALUE 0.
          05 BS-REC-REDO-COUNT           PIC 9(8)  VALUE 0.
          05 BS-REC-UNDO-COUNT           PIC 9(8)  VALUE 0.
          05 BS-REC-CLR-COUNT            PIC 9(8)  VALUE 0.
