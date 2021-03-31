       IDENTIFICATION DIVISION.
       PROGRAM-ID. BSLT-EVENT-BUS.
      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - PRIORITY EVENT DISPATCHER       *
      *> Priority-queued event bus for settlement triggers, margin     *
      *> breaches, lifecycle roll dates, and checkpoint dispatches.    *
      *>================================================================*
       ENVIRONMENT DIVISION.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       COPY "common.cpy".
       COPY "fixed_math.cpy".

       01 WS-EVENT-QUEUE.
          05 WS-QUEUE-HEAD               PIC 9(4)  VALUE 1.
          05 WS-QUEUE-TAIL               PIC 9(4)  VALUE 1.
          05 WS-QUEUE-COUNT              PIC 9(4)  VALUE 0.
          05 WS-QUEUE-CAPACITY           PIC 9(4)  VALUE 256.
          05 WS-EVENT-ENTRIES OCCURS 256 TIMES INDEXED BY WS-EV-IDX.
             10 WS-EV-ID                 PIC 9(12).
             10 WS-EV-TYPE               PIC 9(2).
             10 WS-EV-PRIORITY           PIC 9(1).
             10 WS-EV-TIMESTAMP          PIC 9(14).
             10 WS-EV-PAYLOAD            PIC X(128).

       01 WS-TEMP-VARS.
          05 WS-I                        PIC 9(4)  VALUE 0.

       LINKAGE SECTION.
       01 LNK-EV-OP                      PIC X(8).
       01 LNK-IN-EV-TYPE                 PIC 9(2).
       01 LNK-IN-PRIORITY                PIC 9(1).
       01 LNK-IN-PAYLOAD                 PIC X(128).
       01 LNK-OUT-EV-ID                  PIC 9(12).
       01 LNK-OUT-EV-TYPE                PIC 9(2).
       01 LNK-OUT-PAYLOAD                PIC X(128).
       01 LNK-OUT-QUEUE-DEPTH            PIC 9(4).
       01 LNK-OUT-STATUS                 PIC 9(4).

       PROCEDURE DIVISION USING LNK-EV-OP LNK-IN-EV-TYPE
                                LNK-IN-PRIORITY LNK-IN-PAYLOAD
                                LNK-OUT-EV-ID LNK-OUT-EV-TYPE
                                LNK-OUT-PAYLOAD LNK-OUT-QUEUE-DEPTH
                                LNK-OUT-STATUS.
       0000-MAIN.
           MOVE BS-RC-OK TO LNK-OUT-STATUS

           EVALUATE LNK-EV-OP
               WHEN "ENQUEUE "
                   PERFORM 1000-ENQUEUE-EVENT
               WHEN "DEQUEUE "
                   PERFORM 2000-DEQUEUE-EVENT
               WHEN "DEPTH   "
                   MOVE WS-QUEUE-COUNT TO LNK-OUT-QUEUE-DEPTH
               WHEN OTHER
                   MOVE BS-RC-PARSE-ERROR TO LNK-OUT-STATUS
           END-EVALUATE

           GOBACK.

       1000-ENQUEUE-EVENT.
           IF WS-QUEUE-COUNT >= WS-QUEUE-CAPACITY
               MOVE BS-RC-BUFFER-OVERFLOW TO LNK-OUT-STATUS
               GOBACK
           END-IF

           ADD 1 TO BS-SYS-TX-COUNTER
           MOVE BS-SYS-TX-COUNTER TO WS-EV-ID(WS-QUEUE-TAIL)
           MOVE LNK-IN-EV-TYPE    TO WS-EV-TYPE(WS-QUEUE-TAIL)
           MOVE LNK-IN-PRIORITY   TO WS-EV-PRIORITY(WS-QUEUE-TAIL)
           MOVE 20261015120000    TO WS-EV-TIMESTAMP(WS-QUEUE-TAIL)
           MOVE LNK-IN-PAYLOAD    TO WS-EV-PAYLOAD(WS-QUEUE-TAIL)

           ADD 1 TO WS-QUEUE-TAIL
           IF WS-QUEUE-TAIL > WS-QUEUE-CAPACITY
               MOVE 1 TO WS-QUEUE-TAIL
           END-IF
           ADD 1 TO WS-QUEUE-COUNT

           MOVE BS-SYS-TX-COUNTER TO LNK-OUT-EV-ID
           MOVE WS-QUEUE-COUNT    TO LNK-OUT-QUEUE-DEPTH.

       2000-DEQUEUE-EVENT.
           IF WS-QUEUE-COUNT = 0
               MOVE BS-RC-NOT-FOUND TO LNK-OUT-STATUS
               MOVE 0 TO LNK-OUT-QUEUE-DEPTH
               GOBACK
           END-IF

           MOVE WS-EV-ID(WS-QUEUE-HEAD)      TO LNK-OUT-EV-ID
           MOVE WS-EV-TYPE(WS-QUEUE-HEAD)    TO LNK-OUT-EV-TYPE
           MOVE WS-EV-PAYLOAD(WS-QUEUE-HEAD) TO LNK-OUT-PAYLOAD

           ADD 1 TO WS-QUEUE-HEAD
           IF WS-QUEUE-HEAD > WS-QUEUE-CAPACITY
               MOVE 1 TO WS-QUEUE-HEAD
           END-IF
           SUBTRACT 1 FROM WS-QUEUE-COUNT
           MOVE WS-QUEUE-COUNT TO LNK-OUT-QUEUE-DEPTH.
