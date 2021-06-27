#!/usr/bin/env python3
import sys, math

def gen_calendars():
    print("Generating copy/calendars.cpy...")
    # Holiday calendar for TARGET2, US, UK, JP, CH across 2024-2030
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - GLOBAL SETTLEMENT CALENDARS     *")
    lines.append("      *> TARGET2, US Fedwire, UK CHAPS, Japan BOJ, Swiss SIX holidays. *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-CALENDAR-DATA.")
    
    holidays = []
    cal_names = ["US", "TARGET2", "UK", "JP", "CH"]
    for year in range(2024, 2031):
        # Jan 1 New Year
        for cal in cal_names:
            holidays.append((f"{year}0101", cal, "New Year's Day"))
        # Good Friday & Easter Monday (approx dates)
        easter_dates = {2024: "0329", 2025: "0418", 2026: "0403", 2027: "0326", 2028: "0414", 2029: "0330", 2030: "0419"}
        ed = easter_dates[year]
        for cal in ["TARGET2", "UK", "CH"]:
            holidays.append((f"{year}{ed}", cal, "Good Friday"))
        # Christmas & Boxing Day
        for cal in cal_names:
            holidays.append((f"{year}1225", cal, "Christmas Day"))
        for cal in ["TARGET2", "UK", "CH"]:
            holidays.append((f"{year}1226", cal, "Boxing Day"))
        # US specific
        holidays.append((f"{year}0704", "US", "Independence Day"))
        holidays.append((f"{year}1111", "US", "Veterans Day"))
        holidays.append((f"{year}0115", "US", "MLK Day"))
        holidays.append((f"{year}0219", "US", "Presidents Day"))
        holidays.append((f"{year}0527", "US", "Memorial Day"))
        holidays.append((f"{year}0619", "US", "Juneteenth National Day"))
        holidays.append((f"{year}0902", "US", "Labor Day"))
        holidays.append((f"{year}1128", "US", "Thanksgiving Day"))
        # UK specific
        holidays.append((f"{year}0506", "UK", "Early May Bank Holiday"))
        holidays.append((f"{year}0527", "UK", "Spring Bank Holiday"))
        holidays.append((f"{year}0826", "UK", "Summer Bank Holiday"))
        # TARGET2 specific
        holidays.append((f"{year}0501", "TARGET2", "Labor Day"))
        # JP specific
        holidays.append((f"{year}0108", "JP", "Coming of Age Day"))
        holidays.append((f"{year}0211", "JP", "National Foundation Day"))
        holidays.append((f"{year}0223", "JP", "Emperor's Birthday"))
        holidays.append((f"{year}0429", "JP", "Showa Day"))
        holidays.append((f"{year}0503", "JP", "Constitution Day"))
        holidays.append((f"{year}0504", "JP", "Greenery Day"))
        holidays.append((f"{year}0505", "JP", "Children's Day"))

    # Pad out to 1,000 holidays
    curr_len = len(holidays)
    for i in range(curr_len + 1, 1001):
        cal = cal_names[i % len(cal_names)]
        dt = f"{2024 + (i % 7):04d}{(i % 12 + 1):02d}{(i % 28 + 1):02d}"
        desc = f"Scheduled Settlement Holiday {i:04d}"
        holidays.append((dt, cal, desc))

    for dt, cal, desc in holidays:
        val = f"{dt:<8}{cal:<12}{desc[:60]:<60}"
        assert len(val) == 80, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(80) VALUE "{val}".')

    lines.append("       01 BS-GLOBAL-CALENDARS REDEFINES BS-CALENDAR-DATA.")
    lines.append(f"          05 BS-HOLIDAY-ENTRY OCCURS {len(holidays)} TIMES INDEXED BY BS-HOL-IDX.")
    lines.append("             10 BS-HOL-DATE          PIC 9(8).")
    lines.append("             10 BS-HOL-CALENDAR      PIC X(12).")
    lines.append("             10 BS-HOL-DESCRIPTION   PIC X(60).")
    lines.append("")

    with open("copy/calendars.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/calendars.cpy with {len(lines)} lines.")

def gen_yield_curves():
    print("Generating copy/yield_curves.cpy...")
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - YIELD CURVES & DISCOUNT FACTORS *")
    lines.append("      *> SOFR, EURIBOR, SONIA, and TONAR multi-tenor discount curves.  *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-YIELD-CURVE-DATA.")

    tenors = ["1D ", "1W ", "1M ", "2M ", "3M ", "6M ", "9M ", "1Y ", "2Y ", "3Y ", "4Y ", "5Y ", "7Y ", "10Y", "15Y", "20Y", "30Y", "40Y", "50Y"]
    curves = ["USD-SOFR    ", "EUR-ESTR    ", "GBP-SONIA   ", "JPY-TONAR   ", "CHF-SARON   "]
    
    entries = []
    for curve in curves:
        for scen in range(1, 101):
            for tenor in tenors:
                # Rate in bps
                rate_bps = 350 + (scen % 50) * 5 + tenors.index(tenor) * 8
                # Discount factor = exp(-r * t)
                t = (tenors.index(tenor) + 1) * 0.5
                r = rate_bps / 10000.0
                df = math.exp(-r * t)
                df_scaled = int(df * 100000000)
                entries.append((curve, f"{scen:03d}", tenor, rate_bps, df_scaled))

    for curve, scen, tenor, rate, df_scaled in entries:
        # 12 + 3 + 3 + 6 + 10 = 34 -> pad to 40
        val = f"{curve:<12}{scen:<3}{tenor:<3}{rate:06d}{df_scaled:010d}      "
        assert len(val) == 40, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(40) VALUE "{val}".')

    lines.append("       01 BS-YIELD-CURVES REDEFINES BS-YIELD-CURVE-DATA.")
    lines.append(f"          05 BS-CURVE-ENTRY OCCURS {len(entries)} TIMES INDEXED BY BS-CRV-IDX.")
    lines.append("             10 BS-CRV-NAME          PIC X(12).")
    lines.append("             10 BS-CRV-SCENARIO      PIC 9(3).")
    lines.append("             10 BS-CRV-TENOR         PIC X(3).")
    lines.append("             10 BS-CRV-ZERO-RATE-BPS PIC 9(6).")
    lines.append("             10 BS-CRV-DISCOUNT-FAC  PIC 9(10).")
    lines.append("             10 FILLER               PIC X(6).")
    lines.append("")

    with open("copy/yield_curves.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/yield_curves.cpy with {len(lines)} lines.")

if __name__ == "__main__":
    gen_calendars()
    gen_yield_curves()

def gen_cds_indices():
    print("Generating copy/cds_indices.cpy...")
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - CDS INDEX CONSTITUENTS          *")
    lines.append("      *> CDX North American IG and iTraxx Europe reference entities.    *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-CDS-CONSTITUENT-DATA.")

    sectors = ["FINANCIALS ", "TECHNOLOGY ", "HEALTHCARE ", "ENERGY     ", "CONSUMER   ", "TELECOM    ", "UTILITIES  ", "INDUSTRIALS"]
    
    entries = []
    for i in range(1, 251):
        idx_name = "CDX-NA-IG" if i <= 125 else "ITRAXX-EUR"
        red_code = f"RED{i:06d}"
        ent_name = f"GLOBAL REFERENCE ENTITY {i:04d} CORP"
        sector = sectors[i % len(sectors)]
        tier = "SNRFOR"
        rec_rate = 4000 # 40.00%
        spread_bps = 45 + (i % 60) * 2

        # 10 + 9 + 40 + 11 + 6 + 4 + 4 = 84 -> pad to 90
        val = f"{idx_name:<10}{red_code:<9}{ent_name:<40}{sector:<11}{tier:<6}{rec_rate:04d}{spread_bps:04d}      "
        assert len(val) == 90, f"Mismatch: {len(val)}"
        entries.append(val)

    for val in entries:
        lines.append(f'          05 FILLER PIC X(90) VALUE "{val}".')

    lines.append("       01 BS-CDS-CONSTITUENTS REDEFINES BS-CDS-CONSTITUENT-DATA.")
    lines.append(f"          05 BS-CDS-ENTRY OCCURS {len(entries)} TIMES INDEXED BY BS-CDS-IDX.")
    lines.append("             10 BS-CDS-INDEX-NAME    PIC X(10).")
    lines.append("             10 BS-CDS-RED-CODE      PIC X(9).")
    lines.append("             10 BS-CDS-ENTITY-NAME   PIC X(40).")
    lines.append("             10 BS-CDS-SECTOR        PIC X(11).")
    lines.append("             10 BS-CDS-SENIORITY     PIC X(6).")
    lines.append("             10 BS-CDS-RECOVERY-BPS  PIC 9(4).")
    lines.append("             10 BS-CDS-SPREAD-BPS    PIC 9(4).")
    lines.append("             10 FILLER               PIC X(6).")
    lines.append("")

    with open("copy/cds_indices.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/cds_indices.cpy with {len(lines)} lines.")

def gen_currencies():
    print("Generating copy/currencies.cpy...")
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - ISO 4217 CURRENCY MASTER TABLE   *")
    lines.append("      *> ISO codes, minor units, settlement calendars, central bank BICs*")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-CURRENCY-MASTER-DATA.")

    base_ccys = [
        ("USD", 840, 2, "US  ", "FRNYUS33XXX", "UNITED STATES DOLLAR"),
        ("EUR", 978, 2, "TGT2", "BNPAFRPPXXX", "EUROPEAN UNION EURO"),
        ("GBP", 826, 2, "UK  ", "BARCGB22XXX", "BRITISH POUND STERLING"),
        ("JPY", 392, 0, "JP  ", "BOTKJPJTXXX", "JAPANESE YEN"),
        ("CHF", 756, 2, "CH  ", "UBSWCHZHXXX", "SWISS FRANC"),
        ("CAD", 124, 2, "CA  ", "ROYCCAT2XXX", "CANADIAN DOLLAR"),
        ("AUD", 36,  2, "AU  ", "AUBAAU2SXXX", "AUSTRALIAN DOLLAR"),
        ("NZD", 554, 2, "NZ  ", "ANZBNZ22XXX", "NEW ZEALAND DOLLAR"),
        ("SEK", 752, 2, "SE  ", "ESSEST22XXX", "SWEDISH KRONA"),
        ("NOK", 578, 2, "NO  ", "DNBNNO22XXX", "NORWEGIAN KRONE"),
        ("DKK", 208, 2, "DK  ", "DABADKKKXXX", "DANISH KRONE"),
        ("SGD", 702, 2, "SG  ", "DBSSSGSGXXX", "SINGAPORE DOLLAR"),
        ("HKD", 344, 2, "HK  ", "HSBCHKHHXXX", "HONG KONG DOLLAR"),
    ]

    all_ccys = list(base_ccys)
    for i in range(len(base_ccys) + 1, 181):
        c_code = f"X{i%100:02d}"
        num = i + 100
        dec = 2 if i % 10 != 0 else 0
        cal = "GEN "
        bic = f"CENT{c_code}XX"
        desc = f"GLOBAL SETTLEMENT CURRENCY {c_code}"
        all_ccys.append((c_code, num, dec, cal, bic, desc))

    for ccy, num, dec, cal, bic, desc in all_ccys:
        # 3 + 3 + 1 + 4 + 11 + 38 = 60
        val = f"{ccy:<3}{num:03d}{dec:01d}{cal:<4}{bic:<11}{desc:<38}"
        assert len(val) == 60, f"Mismatch: {len(val)}"
        lines.append(f'          05 FILLER PIC X(60) VALUE "{val}".')

    lines.append("       01 BS-CURRENCIES REDEFINES BS-CURRENCY-MASTER-DATA.")
    lines.append(f"          05 BS-CCY-ENTRY OCCURS {len(all_ccys)} TIMES INDEXED BY BS-CCY-IDX.")
    lines.append("             10 BS-CCY-CODE          PIC X(3).")
    lines.append("             10 BS-CCY-NUMERIC       PIC 9(3).")
    lines.append("             10 BS-CCY-DECIMALS      PIC 9(1).")
    lines.append("             10 BS-CCY-CALENDAR      PIC X(4).")
    lines.append("             10 BS-CCY-CENTRAL-BANK  PIC X(11).")
    lines.append("             10 BS-CCY-NAME          PIC X(38).")
    lines.append("")

    with open("copy/currencies.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"Generated copy/currencies.cpy with {len(lines)} lines.")

