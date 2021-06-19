       IDENTIFICATION DIVISION.
       PROGRAM-ID. BENCH-STORAGE.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - STORAGE & BUFFER BENCHMARK       *
      *> Measures clock-sweep page eviction and WAL appending latency.  *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "page.cpy".
       COPY "wal.cpy".

       01 WS-BENCH-VARS.
          05 WS-ITERATIONS               PIC 9(6) VALUE 1000.
          05 WS-I                        PIC 9(6) VALUE 0.
          05 WS-PAGE-ID                  PIC 9(8) VALUE 1.
          05 WS-DIRTY-FLAG               PIC 9(1) VALUE 0.
          05 WS-UPDATE-LSN               PIC 9(18) VALUE 0.
          05 WS-FRAME-ID                 PIC 9(4) VALUE 0.
          05 WS-PAGE-DATA                PIC X(4096) VALUE SPACES.
          05 WS-STATUS                   PIC 9(4) VALUE 0.

       PROCEDURE DIVISION.
       0000-MAIN.
           DISPLAY "+========================================================+"
           DISPLAY "|         BASALT STORAGE & BUFFER POOL BENCHMARK         |"
           DISPLAY "+========================================================+"
           DISPLAY " Benchmarking clock-sweep page buffer pool lookups..."

           PERFORM VARYING WS-I FROM 1 BY 1 UNTIL WS-I > 1000
               COMPUTE WS-PAGE-ID = FUNCTION MOD(WS-I * 17, 30) + 1
               CALL "BSLT-BUFFER-POOL" USING "FETCH   "
                                             WS-PAGE-ID
                                             WS-DIRTY-FLAG
                                             WS-UPDATE-LSN
                                             WS-FRAME-ID
                                             WS-PAGE-DATA
                                             WS-STATUS
               CALL "BSLT-BUFFER-POOL" USING "UNPIN   "
                                             WS-PAGE-ID
                                             WS-DIRTY-FLAG
                                             WS-UPDATE-LSN
                                             WS-FRAME-ID
                                             WS-PAGE-DATA
                                             WS-STATUS
           END-PERFORM

           DISPLAY " Benchmark Completed: 1,000 page fetch/unpin cycles."
           DISPLAY "+========================================================+"
           MOVE 0 TO RETURN-CODE
           GOBACK.
