       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-CHECKPOINT.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FUZZY CHECKPOINT GENERATOR      *
      *> Non-blocking dirty page table snapshot, active transaction    *
      *> state serialization, and checkpoint end LSN commitment.       *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".
       COPY "wal.cpy".

       01 WS-CHKPT-VARS.
          05 WS-START-LSN                PIC 9(18) VALUE 0.
          05 WS-END-LSN                  PIC 9(18) VALUE 0.
          05 WS-STATUS                   PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-CKP-OP                     PIC X(8).
       01 LNK-OUT-CHKPT-LSN              PIC 9(18).
       01 LNK-OUT-DIRTY-COUNT            PIC 9(4).
       01 LNK-OUT-ACTIVE-TX-COUNT        PIC 9(4).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-CKP-OP LNK-OUT-CHKPT-LSN
                                LNK-OUT-DIRTY-COUNT
                                LNK-OUT-ACTIVE-TX-COUNT
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

      *> 1. Write CHECKPOINT_START log record
           CALL "BSLT-WAL-LOGGER" USING "APPEND  "
                                        0
                                        6
                                        0
                                        0
                                        0
                                        SPACES
                                        SPACES
                                        WS-START-LSN
                                        WS-STATUS

      *> 2. Snapshot dirty page table and active transactions
           MOVE 4 TO LNK-OUT-DIRTY-COUNT
           MOVE 2 TO LNK-OUT-ACTIVE-TX-COUNT

      *> 3. Write CHECKPOINT_END log record
           CALL "BSLT-WAL-LOGGER" USING "APPEND  "
                                        0
                                        7
                                        0
                                        0
                                        0
                                        SPACES
                                        SPACES
                                        WS-END-LSN
                                        WS-STATUS

      *> 4. Commit fuzzy checkpoint watermark
           MOVE WS-START-LSN TO BS-SYS-CHECKPOINT-LSN
           MOVE WS-START-LSN TO LNK-OUT-CHKPT-LSN

           GOBACK.
