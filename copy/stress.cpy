      *>================================================================*
      *> BASALT CLEARINGHOUSE ENGINE - STRESS TESTING SCENARIO MATRIX  *
      *> Historical crisis replays: 2008 Lehman GFC, 2011 Eurozone,    *
      *> 2020 Pandemic Freeze, and 2023 Rapid Rate Hike Liquidity Run. *
      *>================================================================*
       01 BS-STRESS-SCENARIO-TABLE.
          05 BS-STR-COUNT                PIC 9(2) VALUE 4.
          05 BS-STR-SCENARIO OCCURS 4 TIMES INDEXED BY BS-STR-IDX.
             10 BS-STR-NAME              PIC X(32).
             10 BS-STR-EQUITY-SHOCK      PIC S9(3)V9(4) COMP-3.
             10 BS-STR-SPREAD-BPS-SHOCK  PIC S9(5)      COMP-3.
             10 BS-STR-RATES-BPS-SHOCK   PIC S9(5)      COMP-3.
             10 BS-STR-VOL-PERCENT-SHOCK PIC S9(3)V9(4) COMP-3.
             10 BS-STR-FX-EUR-SHOCK      PIC S9(3)V9(4) COMP-3.
             10 BS-STR-HAIRCUT-ADDON     PIC S9(3)V9(4) COMP-3.
             10 BS-STR-RUNOFF-PERCENT    PIC S9(3)V9(4) COMP-3.

       01 BS-STRESS-DEFAULTS.
      *> Pre-calibrated historical shocks
          05 FILLER PIC X(85) VALUE "2008_LEHMAN_GLOBAL_FINANCIAL_CRISIS -0.4000+0450-0150+0.8000-0.1200+0.1500+0.2500".
          05 FILLER PIC X(85) VALUE "2011_EUROZONE_SOVEREIGN_DEBT_CRISIS -0.2500+0600+0050+0.5000-0.1800+0.2500+0.2000".
          05 FILLER PIC X(85) VALUE "2020_PANDEMIC_LIQUIDITY_FREEZE_CRSH -0.3200+0800-0120+1.2000+0.0500+0.2000+0.3000".
          05 FILLER PIC X(85) VALUE "2023_RAPID_RATE_HIKE_BANK_RUN_SHOCK -0.1500+0350+0500+0.4000-0.0800+0.1000+0.3500".
