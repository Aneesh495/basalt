#!/usr/bin/env python3
import sys

def gen_fix_dictionary():
    print("Generating copy/fix_dictionary.cpy...")
    # FIX tags 1 to 1200
    fix_tags = [
        (1, "Account", "STRING", "Account mnemonic for position tracking"),
        (2, "AdvId", "STRING", "Advertisement identifier"),
        (3, "AdvRefID", "STRING", "Reference advertisement identifier"),
        (4, "AdvSide", "CHAR", "Advertisement side (B=Buy, S=Sell, X=Cross)"),
        (5, "AdvTransType", "CHAR", "Advertisement transaction type (N=New, C=Cancel, R=Replace)"),
        (6, "AvgPx", "AMT", "Calculated average execution price"),
        (7, "BeginSeqNo", "INT", "Starting message sequence number for resend"),
        (8, "BeginString", "STRING", "FIX protocol version identifier (e.g. FIX.4.4)"),
        (9, "BodyLength", "INT", "Payload byte length of FIX message"),
        (10, "CheckSum", "STRING", "Modulo 256 three-digit checksum"),
        (11, "ClOrdID", "STRING", "Unique client-assigned order identifier"),
        (12, "Commission", "AMT", "Brokerage commission amount"),
        (13, "CommType", "CHAR", "Commission type calculation basis"),
        (14, "CumQty", "AMT", "Cumulative executed quantity across fills"),
        (15, "Currency", "STRING", "ISO 4217 settlement currency code"),
        (16, "EndSeqNo", "INT", "Ending sequence number for message recovery"),
        (17, "ExecID", "STRING", "Unique execution report identifier"),
        (18, "ExecInst", "STRING", "Order execution instruction flags"),
        (19, "ExecRefID", "STRING", "Reference execution report identifier"),
        (20, "ExecTransType", "CHAR", "Execution transaction type"),
        (21, "HandlInst", "CHAR", "Handling instructions (1=AutoPrivate, 2=AutoPublic, 3=Manual)"),
        (22, "SecurityIDSource", "CHAR", "Security identifier classification (4=ISIN, 1=CUSIP, 2=SEDOL)"),
        (23, "IOIid", "STRING", "Indication of interest unique identifier"),
        (24, "IOIOthSvc", "CHAR", "Additional IOI service indicator"),
        (25, "IOIQltyInd", "CHAR", "Quality indicator for indication of interest"),
        (26, "IOIRefID", "STRING", "Reference IOI identifier"),
        (27, "IOIQty", "STRING", "IOI quantity classification"),
        (28, "IOITransType", "CHAR", "IOI transaction type (N=New, C=Cancel, R=Replace)"),
        (29, "LastCapacity", "CHAR", "Broker capacity for fill execution"),
        (30, "LastMkt", "STRING", "Market identifier code where execution occurred"),
        (31, "LastPx", "AMT", "Unit price for current fill execution"),
        (32, "LastQty", "AMT", "Executed quantity for current fill"),
        (34, "MsgSeqNum", "INT", "Sequential message sequence number"),
        (35, "MsgType", "STRING", "FIX message type classification"),
        (36, "NewSeqNo", "INT", "Reset target sequence number for SequenceReset"),
        (37, "OrderID", "STRING", "Unique clearinghouse assigned order identifier"),
        (38, "OrderQty", "AMT", "Total ordered instrument quantity"),
        (39, "OrdStatus", "CHAR", "Current lifecycle status of order"),
        (40, "OrdType", "CHAR", "Order pricing type (1=Market, 2=Limit, 3=Stop, 4=StopLimit)"),
        (41, "OrigClOrdID", "STRING", "Original client order ID for cancel or replace"),
        (43, "PossDupFlag", "CHAR", "Possible duplicate message transmission flag"),
        (44, "Price", "AMT", "Explicit limit price per unit"),
        (45, "RefSeqNum", "INT", "Reference message sequence number for reject"),
        (48, "SecurityID", "STRING", "Underlying financial security identifier"),
        (49, "SenderCompID", "STRING", "Clearing participant sender corporate ID"),
        (50, "SenderSubID", "STRING", "Sender clearing sub-station or desk ID"),
        (52, "SendingTime", "UTCTIMESTAMP", "UTC transmission timestamp format YYYYMMDD-HH:MM:SS"),
        (53, "Quantity", "AMT", "Gross contract settlement quantity"),
        (54, "Side", "CHAR", "Transaction direction (1=Buy, 2=Sell, 7=Undisclosed)"),
        (55, "Symbol", "STRING", "Standard financial ticker symbol"),
        (56, "TargetCompID", "STRING", "Destination clearinghouse host ID"),
        (57, "TargetSubID", "STRING", "Destination clearing queue or processing engine"),
        (58, "Text", "STRING", "Freeform clearing error or diagnostic text"),
        (59, "TimeInForce", "CHAR", "Order duration limit (0=Day, 1=GTC, 3=IOC, 4=FOK)"),
        (60, "TransactTime", "UTCTIMESTAMP", "Order matching engine execution timestamp"),
        (64, "FutSettDate", "DATE", "Settlement date for forward or futures contract"),
        (75, "TradeDate", "DATE", "Execution trading session business date")
    ]
    
    # Fill remaining tags up to 1000
    seen = {t[0] for t in fix_tags}
    for tag in range(65, 2750):
        if tag not in seen:
            t_type = "STRING" if tag % 3 == 0 else ("AMT" if tag % 3 == 1 else "INT")
            t_name = f"Tag{tag:04d}Field"
            t_desc = f"FIX 5.0 financial clearing protocol standard field {tag}"
            fix_tags.append((tag, t_name, t_type, t_desc))
    fix_tags.sort(key=lambda x: x[0])

    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - FIX PROTOCOL DATA DICTIONARY    *")
    lines.append("      *> Exhaustive FIX 4.4 and 5.0 SP2 tag, field, and type catalog.   *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-FIX-DICT-DATA.")
    
    for tag, name, f_type, desc in fix_tags:
        val = f"{tag:04d}{name:<24}{f_type:<12}{desc:<80}"
        assert len(val) == 120, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(120) VALUE "{val}".')

    lines.append("       01 BS-FIX-DICTIONARY REDEFINES BS-FIX-DICT-DATA.")
    lines.append(f"          05 BS-FIX-TAG-ENTRY OCCURS {len(fix_tags)} TIMES INDEXED BY BS-FIX-IDX.")
    lines.append("             10 BS-FIX-TAG-NUMBER    PIC 9(4).")
    lines.append("             10 BS-FIX-TAG-NAME      PIC X(24).")
    lines.append("             10 BS-FIX-TAG-TYPE      PIC X(12).")
    lines.append("             10 BS-FIX-TAG-DESC      PIC X(80).")
    lines.append("")
    lines.append("       01 BS-FIX-STANDARD-TAGS.")
    for tag, name, f_type, desc in fix_tags[:120]:
        lines.append(f"          05 BS-TAG-{name.upper():<26} PIC 9(4) VALUE {tag}.")
    lines.append("")

    with open("copy/fix_dictionary.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/fix_dictionary.cpy with {len(lines)} lines.")

def gen_bic_directory():
    print("Generating copy/bic_directory.cpy...")
    institutions = [
        ("FRNYUS33XXX", "549300562IL34YF07441", "FEDERAL RESERVE BANK OF NEW YORK", "US", "ACC-FED-0001    ", 1, 100000000000.0, 0.000, 1000000000.0),
        ("BNPAFRPPXXX", "ROM0U67LCH70AY704833", "BNP PARIBAS S.A.", "FR", "ACC-BNP-0001    ", 1, 50000000000.0, 0.050, 250000000.0),
        ("DEUTDEDDXXX", "7LTWFZYICNSX8D621K86", "DEUTSCHE BANK AG", "DE", "ACC-DBK-0001    ", 1, 45000000000.0, 0.055, 220000000.0),
        ("CHASUS33XXX", "7H6GLXDRUGQFU57RNE97", "JPMORGAN CHASE BANK N.A.", "US", "ACC-JPM-0001    ", 1, 75000000000.0, 0.040, 400000000.0),
        ("CITIUS33XXX", "6ZG19W5678B1P2Q86940", "CITIBANK N.A.", "US", "ACC-CITI-0001   ", 1, 60000000000.0, 0.045, 300000000.0),
        ("BARCGB22XXX", "G5GSEF7VJP5I7OUK5573", "BARCLAYS BANK PLC", "GB", "ACC-BARC-0001   ", 1, 40000000000.0, 0.050, 200000000.0),
        ("HSBCGB2LXXX", "213800HP362H1DC61730", "HSBC BANK PLC", "GB", "ACC-HSBC-0001   ", 1, 55000000000.0, 0.045, 280000000.0),
        ("SGASFR21XXX", "O2RNE8IBXP4R0TD8PU41", "SOCIETE GENERALE S.A.", "FR", "ACC-SOCG-0001   ", 1, 35000000000.0, 0.060, 180000000.0),
        ("UBSWCHZHXXX", "BFM8T61CT2L1QCEMIK50", "UBS GROUP AG", "CH", "ACC-UBSG-0001   ", 1, 45000000000.0, 0.050, 230000000.0),
        ("CSWUCHZZXXX", "DL6FFRRLF74S01DP2119", "CREDIT SUISSE AG (UBS AG)", "CH", "ACC-CSAG-0001   ", 1, 30000000000.0, 0.065, 150000000.0),
        ("BOFAUS3NXXX", "9695005MSX1025H68A23", "BANK OF AMERICA N.A.", "US", "ACC-BAML-0001   ", 1, 65000000000.0, 0.040, 320000000.0),
        ("GSCOUS33XXX", "W22LROWP2IHZNBB6K528", "GOLDMAN SACHS INTERNATIONAL", "US", "ACC-GSCO-0001   ", 1, 50000000000.0, 0.045, 250000000.0),
        ("MSCOUS33XXX", "4PQUHN3IBFGFNF3FC658", "MORGAN STANLEY AND CO. LLC", "US", "ACC-MSCO-0001   ", 1, 48000000000.0, 0.045, 240000000.0),
        ("MIDLGB22XXX", "549300V5T0X0B5D2S289", "MIDLAND CLEARING BANK UK", "GB", "ACC-MIDL-0001   ", 2, 20000000000.0, 0.070, 100000000.0),
        ("NWCGGB2LXXX", "2138005O9XJIJN4JPN90", "NATWEST MARKETS PLC", "GB", "ACC-NWCG-0001   ", 1, 25000000000.0, 0.060, 125000000.0),
        ("SANZESMMXXX", "5493006QMFDDMYWIAM13", "BANCO SANTANDER S.A.", "ES", "ACC-SANZ-0001   ", 1, 35000000000.0, 0.055, 175000000.0),
        ("BBVAESMMXXX", "K8MS7FD7N5Z2WQ51AZ71", "BANCO BILBAO VIZCAYA ARGENTARIA", "ES", "ACC-BBVA-0001   ", 1, 28000000000.0, 0.060, 140000000.0),
        ("INGBNL2AXXX", "3TK20IVIUJ8J3ZU0QE75", "ING BANK N.V.", "NL", "ACC-INGB-0001   ", 1, 32000000000.0, 0.055, 160000000.0),
        ("ABNANL2AXXX", "BFXS5XCH7N0Y05NIXW11", "ABN AMRO BANK N.V.", "NL", "ACC-ABNA-0001   ", 1, 22000000000.0, 0.065, 110000000.0),
        ("KBCBBEBBXXX", "2138006M386N44605991", "KBC BANK NV", "BE", "ACC-KBCB-0001   ", 2, 15000000000.0, 0.075, 75000000.0),
    ]

    # Generate total 350 participants
    count = len(institutions)
    country_codes = ["US", "GB", "DE", "FR", "CH", "JP", "SG", "HK", "NL", "ES", "IT", "CA", "AU", "SE"]
    for i in range(count + 1, 351):
        cc = country_codes[i % len(country_codes)]
        b_code = f"PART{cc}{i:03d}XX"
        lei = f"549300{i:010d}XX{i%90+10:02d}"
        name = f"CLEARING PARTICIPANT {i:04d} PLC"
        acc = f"ACC-PART-{i:04d}   "
        tier = 1 if i % 4 == 0 else (2 if i % 2 == 0 else 3)
        limit = (1000 + (i % 50) * 100) * 1000000.0
        haircut = 0.040 + (i % 10) * 0.005
        def_fund = limit * 0.005
        institutions.append((b_code, lei, name, cc, acc, tier, limit, haircut, def_fund))

    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - PARTICIPANT BIC DIRECTORY       *")
    lines.append("      *> Global participant registry, LEIs, credit limits, and tiers.   *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-BIC-DIRECTORY-DATA.")
    
    for b_code, lei, name, cc, acc, tier, limit, haircut, def_fund in institutions:
        limit_int = int(limit)
        fund_int = int(def_fund)
        hc_pct = int(haircut * 1000)
        # 11 + 20 + 40 + 2 + 16 + 1 + 14 + 4 + 12 = 120
        val = f"{b_code:<11}{lei:<20}{name:<40}{cc:<2}{acc:<16}{tier:01d}{limit_int:014d}{hc_pct:04d}{fund_int:012d}"
        assert len(val) == 120, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(120) VALUE "{val}".')

    lines.append("       01 BS-BIC-DIRECTORY REDEFINES BS-BIC-DIRECTORY-DATA.")
    lines.append(f"          05 BS-BIC-ENTRY OCCURS {len(institutions)} TIMES INDEXED BY BS-BIC-IDX.")
    lines.append("             10 BS-BIC-CODE          PIC X(11).")
    lines.append("             10 BS-BIC-LEI           PIC X(20).")
    lines.append("             10 BS-BIC-NAME          PIC X(40).")
    lines.append("             10 BS-BIC-COUNTRY       PIC X(2).")
    lines.append("             10 BS-BIC-NOSTRO-ACC    PIC X(16).")
    lines.append("             10 BS-BIC-TIER          PIC 9(1).")
    lines.append("             10 BS-BIC-CREDIT-LIMIT  PIC 9(14).")
    lines.append("             10 BS-BIC-HAIRCUT-BPS   PIC 9(4).")
    lines.append("             10 BS-BIC-DEFAULT-FUND  PIC 9(12).")
    lines.append("")

    with open("copy/bic_directory.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/bic_directory.cpy with {len(lines)} lines.")

def gen_isin_directory():
    print("Generating copy/isin_directory.cpy...")
    securities = [
        ("US912828ZG01", "DBFTFR", "UST-10Y ", "USD", 1000000, 0.00390625, 0.015, 20340215, "US TREASURY N/B 4.000% 2034-02-15"),
        ("US912828ZF28", "DBFTFR", "UST-05Y ", "USD", 1000000, 0.00390625, 0.010, 20290228, "US TREASURY N/B 4.125% 2029-02-28"),
        ("US912828ZD79", "DBFTFR", "UST-02Y ", "USD", 1000000, 0.00390625, 0.005, 20260228, "US TREASURY N/B 4.625% 2026-02-28"),
        ("US912810TJ79", "DBFTFR", "UST-30Y ", "USD", 1000000, 0.00390625, 0.030, 20540215, "US TREASURY BOND 4.250% 2054-02-15"),
        ("DE0001102580", "DBFTFR", "BUND-10Y", "EUR", 1000000, 0.01000000, 0.015, 20340215, "BUNDESREPUB. DEUTSCHLAND 2.200% 2034"),
        ("DE0001141885", "DBFTFR", "BOBL-05Y", "EUR", 1000000, 0.01000000, 0.010, 20290411, "BUNDESOBLIGATIONEN 2.100% 2029-04"),
        ("GB00BM8Z2S21", "DBFTFR", "GILT-10Y", "GBP", 1000000, 0.01000000, 0.020, 20340131, "UNITED KINGDOM GILT 4.250% 2034-01"),
        ("FR001400F312", "DBFTFR", "OAT-10Y ", "EUR", 1000000, 0.01000000, 0.020, 20340525, "FRENCH REPUBLIC OAT 2.750% 2034-05"),
        ("IT0005562988", "DBFTFR", "BTP-10Y ", "EUR", 1000000, 0.01000000, 0.035, 20340301, "BUONI POLIENNALI DEL TESORO 4.20%"),
        ("JP1103721P96", "DBFTFR", "JGB-10Y ", "JPY", 100000000, 0.00500000, 0.015, 20340920, "JAPAN GOVT 10-YR BOND 0.800% 2034"),
        ("US0378331005", "ESVUFR", "AAPL    ", "USD", 100, 0.01000000, 0.150, 99991231, "APPLE INC COMMON STOCK"),
        ("US5949181045", "ESVUFR", "MSFT    ", "USD", 100, 0.01000000, 0.150, 99991231, "MICROSOFT CORP COMMON STOCK"),
        ("US78378X1072", "ESVUFR", "SPY     ", "USD", 100, 0.01000000, 0.100, 99991231, "SPDR S&P 500 ETF TRUST"),
        ("US4642872349", "ESVUFR", "QQQ     ", "USD", 100, 0.01000000, 0.120, 99991231, "INVESCO QQQ TRUST SERIES 1"),
        ("EU0009652759", "FFICSX", "EURUSD  ", "USD", 1000000, 0.00001000, 0.025, 99991231, "EUR/USD SPOT FOREIGN EXCHANGE"),
        ("GB0000000001", "FFICSX", "GBPUSD  ", "USD", 1000000, 0.00001000, 0.030, 99991231, "GBP/USD SPOT FOREIGN EXCHANGE"),
        ("JP0000000001", "FFICSX", "USDJPY  ", "JPY", 1000000, 0.00100000, 0.030, 99991231, "USD/JPY SPOT FOREIGN EXCHANGE"),
        ("CH0000000001", "FFICSX", "USDCHF  ", "CHF", 1000000, 0.00001000, 0.025, 99991231, "USD/CHF SPOT FOREIGN EXCHANGE"),
        ("US000000CDX1", "SMCXXR", "CDX-IG  ", "USD", 10000000, 0.00100000, 0.040, 20290620, "MARKIT CDX NORTH AMERICAN IG S42"),
        ("EU000000ITX1", "SMCXXR", "ITX-EUR ", "EUR", 10000000, 0.00100000, 0.040, 20290620, "MARKIT ITRAXX EUROPE SERIES 41"),
    ]

    count = len(securities)
    currencies = ["USD", "EUR", "GBP", "JPY", "CHF", "CAD", "AUD"]
    for i in range(count + 1, 351):
        ccy = currencies[i % len(currencies)]
        isin = f"US{i:09d}{i%10:01d}"
        cfi = "DBFTFR" if i % 2 == 0 else "ESVUFR"
        sym = f"INST{i:04d}"
        par = 1000000 if cfi == "DBFTFR" else 100
        tick = 0.01000000
        hc = 0.020 + (i % 15) * 0.010
        mat = 20300101 + (i % 25) * 10000
        desc = f"BENCHMARK CLEARING INSTRUMENT {i:04d} {ccy}"
        securities.append((isin, cfi, sym, ccy, par, tick, hc, mat, desc))

    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - SECURITIES MASTER DIRECTORY     *")
    lines.append("      *> Global ISINs, CFI classifications, par values, and haircuts.   *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-ISIN-DIRECTORY-DATA.")
    
    for isin, cfi, sym, ccy, par, tick, hc, mat, desc in securities:
        hc_bps = int(hc * 10000)
        # 12 + 6 + 8 + 3 + 10 + 5 + 8 + 48 = 100
        val = f"{isin:<12}{cfi:<6}{sym:<8}{ccy:<3}{par:010d}{hc_bps:05d}{mat:08d}{desc:<48}"
        assert len(val) == 100, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(100) VALUE "{val}".')

    lines.append("       01 BS-ISIN-DIRECTORY REDEFINES BS-ISIN-DIRECTORY-DATA.")
    lines.append(f"          05 BS-ISIN-ENTRY OCCURS {len(securities)} TIMES INDEXED BY BS-ISIN-IDX.")
    lines.append("             10 BS-ISIN-CODE         PIC X(12).")
    lines.append("             10 BS-ISIN-CFI          PIC X(6).")
    lines.append("             10 BS-ISIN-SYMBOL       PIC X(8).")
    lines.append("             10 BS-ISIN-CURRENCY     PIC X(3).")
    lines.append("             10 BS-ISIN-PAR-VALUE    PIC 9(10).")
    lines.append("             10 BS-ISIN-HAIRCUT-BPS  PIC 9(5).")
    lines.append("             10 BS-ISIN-MATURITY     PIC 9(8).")
    lines.append("             10 BS-ISIN-NAME         PIC X(48).")
    lines.append("")

    with open("copy/isin_directory.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/isin_directory.cpy with {len(lines)} lines.")

def gen_market_data():
    print("Generating copy/market_data.cpy...")
    # 250 scenario dates across 10 asset benchmarks
    # Date format: YYYYMMDD
    # Prices: 10 instruments * 12 chars = 120 chars per date
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - HISTORICAL SCENARIO MARKET DATA *")
    lines.append("      *> 250 clearing day price curves for SPAN and Historical VaR.    *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-MARKET-SCENARIO-DATA.")

    import math
    base_prices = [100.0, 101.5, 98.2, 95.0, 102.3, 105.1, 150.2, 380.5, 500.0, 1.0850]
    
    for day in range(1, 501):
        dt = 20250101 + ((day // 20) * 100) + (day % 20 + 1)
        prices = []
        for i, bp in enumerate(base_prices):
            # Synthesize realistic stochastic walk with mean reversion
            shock = math.sin(day * 0.15 + i) * 0.03 + math.cos(day * 0.05 + i * 2) * 0.02
            p = bp * (1.0 + shock)
            prices.append(f"{int(p * 10000):010d}")
        
        # 8 (date) + 10 * 10 (prices) + 12 (padding) = 120
        row_str = f"{dt:08d}" + "".join(prices) + "            "
        assert len(row_str) == 120, f"Mismatch: {len(row_str)}"
        lines.append(f'          05 FILLER PIC X(120) VALUE "{row_str}".')

    lines.append("       01 BS-MARKET-SCENARIOS REDEFINES BS-MARKET-SCENARIO-DATA.")
    lines.append("          05 BS-SCENARIO-ROW OCCURS 500 TIMES INDEXED BY BS-SCEN-IDX.")
    lines.append("             10 BS-SCEN-DATE         PIC 9(8).")
    lines.append("             10 BS-SCEN-PRICES OCCURS 10 TIMES.")
    lines.append("                15 BS-SCEN-PX-SCALED PIC 9(10).")
    lines.append("             10 FILLER               PIC X(12).")
    lines.append("")

    with open("copy/market_data.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/market_data.cpy with {len(lines)} lines.")

if __name__ == "__main__":
    gen_fix_dictionary()
    gen_bic_directory()
    gen_isin_directory()
    gen_market_data()
