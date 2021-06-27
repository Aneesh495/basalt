#!/usr/bin/env python3
import sys

def main():
    errors = []
    
    # Categories:
    # 1: Ledger & Accounting
    # 2: Netting & Settlement
    # 3: Risk & Margining
    # 4: Storage & ARIES
    # 5: Financial Contracts
    # 6: Messaging & Protocol
    # 7: Kernel & Cryptography

    cats = [
        ("LEDGER", "E", "AC01", "Core Ledger and Accounting System"),
        ("NETTING", "E", "ST01", "Multilateral Netting and Settlement"),
        ("RISK", "E", "RG01", "Risk Management and SPAN Margining"),
        ("STORAGE", "F", "IO01", "Slotted Page Storage and ARIES Recovery"),
        ("CONTRACT", "E", "CT01", "Financial Contract Valuation and Cashflows"),
        ("MESSAGE", "E", "MS01", "Financial Messaging and Protocol Parsing"),
        ("SYSTEM", "F", "SY01", "Kernel Runtime and Cryptographic Operations")
    ]
    
    code = 1
    # Generate 500 error entries
    for cat_idx, (cat_name, default_sev, iso_base, cat_desc) in enumerate(cats):
        for item in range(1, 75):
            code_str = f"{code:04d}"
            sev = default_sev
            mnemonic = f"ERR_{cat_name}_{item:03d}"
            iso_reason = f"{iso_base[:2]}{item%90+10:02d}"
            desc = f"{cat_name} validation error {item:03d} encountered during processing."
            action = f"Review {cat_name.lower()} telemetry logs and apply corrective action {item:03d}."
            
            # Specific high-signal names for known errors
            if code == 1:
                mnemonic = "ERR_LEDGER_INSUFFICIENT_FUNDS"
                desc = "Account settled balance below debit amount plus required initial margin."
                action = "Deposit additional collateral or reduce member gross exposure."
                iso_reason = "AM04"
            elif code == 2:
                mnemonic = "ERR_LEDGER_ACCOUNT_NOT_FOUND"
                desc = "Target account identifier is not registered in the participant master."
                action = "Verify account identifier against the clearing participant directory."
                iso_reason = "AC01"
            elif code == 3:
                mnemonic = "ERR_LEDGER_ACCOUNT_FROZEN"
                desc = "Target account is administratively frozen pending regulatory review."
                action = "Contact clearinghouse operations to release administrative lock."
                iso_reason = "AC06"
            elif code == 4:
                mnemonic = "ERR_LEDGER_CREDIT_LIMIT_BREACH"
                desc = "Debit transfer exceeds intraday uncommitted bilateral credit limit."
                action = "Request intraday credit limit increase from sponsor clearing member."
                iso_reason = "AM05"
            elif code == 5:
                mnemonic = "ERR_LEDGER_BITEMPORAL_VIOLATION"
                desc = "Transaction system assertion timestamp precedes prior recorded state."
                action = "Submit retroactive adjustments using standard bi-temporal correction batch."
                iso_reason = "DT01"
            elif code == 6:
                mnemonic = "ERR_NETTING_CYCLE_DETECTED"
                desc = "Directed debt settlement cycle identified during Tarjan DFS traversal."
                action = "Execute multilateral cycle cancellation pass to eliminate gross exposures."
                iso_reason = "NC01"
            elif code == 7:
                mnemonic = "ERR_NETTING_GRIDLOCK_UNRESOLVED"
                desc = "Multilateral gridlock resolution failed to achieve balanced settlement."
                action = "Queue unsettled obligations for next liquidity injection cycle."
                iso_reason = "GL01"
            elif code == 8:
                mnemonic = "ERR_RISK_MARGIN_DEFICIT"
                desc = "Current portfolio SPAN margin requirement exceeds posted collateral."
                action = "Issue intraday variation margin call to clearing participant."
                iso_reason = "MR01"
            elif code == 9:
                mnemonic = "ERR_STORAGE_BUFFER_POOL_FULL"
                desc = "All buffer pool frames are currently pinned with active latches."
                action = "Increase buffer pool frame allocation or verify transaction unpin logic."
                iso_reason = "BP01"
            elif code == 10:
                mnemonic = "ERR_STORAGE_WAL_CHECKSUM_FAIL"
                desc = "Write-ahead log record checksum does not match computed SHA-256 digest."
                action = "Initiate ARIES crash recovery from most recent stable fuzzy checkpoint."
                iso_reason = "WL01"
                
            errors.append((code_str, sev, mnemonic[:30], iso_reason[:4], desc[:80], action[:80]))
            code += 1
            if code > 500:
                break
        if code > 500:
            break

    # Build COBOL copybook
    lines = []
    lines.append("      *>================================================================*")
    lines.append("      *> BASALT CLEARINGHOUSE ENGINE - ENTERPRISE ERROR CATALOG        *")
    lines.append("      *> Exhaustive diagnostic definitions, severities, and ISO codes.  *")
    lines.append("      *>================================================================*")
    lines.append("       01 BS-ERROR-CATALOG-DATA.")
    
    for c_str, sev, mnem, iso_r, desc, act in errors:
        val_str = f"{c_str:<4}{sev:<1}{mnem:<30}{iso_r:<4}{desc:<80}{act:<81}"
        assert len(val_str) == 200, f"Length mismatch: {len(val_str)}"
        lines.append(f'          05 FILLER PIC X(200) VALUE "{val_str}".')

    lines.append("       01 BS-ERROR-CATALOG REDEFINES BS-ERROR-CATALOG-DATA.")
    lines.append(f"          05 BS-ERR-ENTRY OCCURS {len(errors)} TIMES INDEXED BY BS-ERR-IDX.")
    lines.append("             10 BS-ERR-CODE       PIC 9(4).")
    lines.append("             10 BS-ERR-SEVERITY   PIC X(1).")
    lines.append("             10 BS-ERR-MNEMONIC   PIC X(30).")
    lines.append("             10 BS-ERR-ISO-REASON PIC X(4).")
    lines.append("             10 BS-ERR-DESC       PIC X(80).")
    lines.append("             10 BS-ERR-ACTION     PIC X(81).")
    lines.append("")
    lines.append("       01 BS-ERROR-CONSTANTS.")
    for c_str, sev, mnem, iso_r, desc, act in errors[:100]:
        lines.append(f"          05 BS-{mnem:<32} PIC 9(4) VALUE {int(c_str)}.")
    lines.append("")

    with open("copy/error_catalog.cpy", "w") as f:
        f.write("\n".join(lines) + "\n")

    print(f"Generated copy/error_catalog.cpy with {len(errors)} entries, {len(lines)} lines.")

if __name__ == "__main__":
    main()
