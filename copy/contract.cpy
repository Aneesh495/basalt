      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - FINANCIAL CONTRACT SCHEMAS       *
      *> ACTUS contract models (PAM, ANN, LAM, IRS, FXFRWD) and flows   *
      *>================================================================*
       01 BS-FINANCIAL-CONTRACT.
          05 BS-CTR-ID                   PIC X(16) VALUE SPACES.
          05 BS-CTR-TYPE                 PIC 9(2)  VALUE 1.
             88 BS-CTR-TYPE-PAM          VALUE 1.
             88 BS-CTR-TYPE-ANN          VALUE 2.
             88 BS-CTR-TYPE-LAM          VALUE 3.
             88 BS-CTR-TYPE-IRS          VALUE 4.
             88 BS-CTR-TYPE-FXFRWD       VALUE 5.
          05 BS-CTR-DEBTOR-BIC           PIC X(11) VALUE SPACES.
          05 BS-CTR-CREDITOR-BIC         PIC X(11) VALUE SPACES.
          05 BS-CTR-CURRENCY             PIC X(3)  VALUE "USD".
          05 BS-CTR-PRINCIPAL            PIC S9(18)V9(8) COMP-3 VALUE 0.
          05 BS-CTR-NOMINAL-RATE         PIC S9(3)V9(8)  COMP-3 VALUE 0.
          05 BS-CTR-DAYCOUNT             PIC 9(2)  VALUE 1.
          05 BS-CTR-CYCLE-FREQ           PIC 9(2)  VALUE 12.
             88 BS-CTR-FREQ-ANNUAL       VALUE 12.
             88 BS-CTR-FREQ-SEMI         VALUE 6.
             88 BS-CTR-FREQ-QUARTERLY    VALUE 3.
             88 BS-CTR-FREQ-MONTHLY      VALUE 1.
          05 BS-CTR-IED-DATE             PIC 9(8)  VALUE 0.
          05 BS-CTR-MD-DATE              PIC 9(8)  VALUE 0.
          05 BS-CTR-STATUS               PIC X(1)  VALUE 'A'.
             88 BS-CTR-STAT-ACTIVE       VALUE 'A'.
             88 BS-CTR-STAT-TERMINATED   VALUE 'T'.
             88 BS-CTR-STAT-DEFAULTED    VALUE 'D'.

       01 BS-CONTRACT-SCHEDULE.
          05 BS-SCHED-COUNT              PIC 9(4)  VALUE 0.
          05 BS-SCHED-FLOW OCCURS 120 TIMES INDEXED BY BS-SCHED-IDX.
             10 BS-FLOW-DATE             PIC 9(8).
             10 BS-FLOW-EVENT-TYPE       PIC 9(2).
                88 BS-FLOW-IED           VALUE 1.
                88 BS-FLOW-INTEREST      VALUE 2.
                88 BS-FLOW-PRINCIPAL     VALUE 3.
                88 BS-FLOW-MATURITY      VALUE 4.
                88 BS-FLOW-RESET         VALUE 5.
             10 BS-FLOW-INTEREST-AMT     PIC S9(18)V9(8) COMP-3.
             10 BS-FLOW-PRINCIPAL-AMT    PIC S9(18)V9(8) COMP-3.
             10 BS-FLOW-TOTAL-CASHFLOW   PIC S9(18)V9(8) COMP-3.
             10 BS-FLOW-REMAINING-BAL    PIC S9(18)V9(8) COMP-3.
