# Basalt Native Interoperability & Integration Guide

Basalt exports a C-linkage Application Binary Interface (ABI) that allows developers to embed the pure COBOL settlement kernel directly into low-latency systems, Python pipelines, and network servers.

---

## 1. COBOL to C Type Mapping

GnuCOBOL maps standard COBOL picture clauses to native C data types as follows:

| COBOL Picture Clause | Representation | C Equivalent |
| :--- | :--- | :--- |
| `PIC X(N)` | Fixed-width alphanumeric string | `char[N]` (space-padded, no null terminator required in COBOL) |
| `PIC 9(4)` | 4-digit unsigned display integer | `char[4]` or unpacked numeric ASCII |
| `USAGE BINARY-LONG UNSIGNED` | 32-bit unsigned binary integer | `uint32_t` |
| `USAGE BINARY-DOUBLE` | 64-bit signed binary integer | `int64_t` |
| `PIC S9(18)V9(8) COMP-3` | 128-bit packed BCD decimal | 14-byte packed binary-coded decimal buffer |

### COMP-3 Packed Decimal Layout

A COBOL `PIC S9(18)V9(8) COMP-3` field contains 26 decimal digits (18 integral, 8 fractional) plus one sign nibble, packed two digits per byte into a 14-byte buffer:

```
Byte:   0    1    2    3    4    5    6    7    8    9   10   11   12   13
Nibble: [D0][D1] [D2][D3] ... [D24][D25] [D26][Sign]
```

* **Positive Sign**: `0xC` (or `0xF` for unsigned)
* **Negative Sign**: `0xD`

---

## 2. Compiling the Shared Library

To build the dynamic shared library (`libbasalt.dylib` on macOS or `libbasalt.so` on Linux):

```bash
make bin/libbasalt.dylib
```

Under the hood, the build executes:

```bash
cobc -b -free -Wall -I copy -O2 -o bin/libbasalt.dylib \
     src/kernel/*.cbl src/ledger/*.cbl src/netting/*.cbl \
     src/risk/*.cbl src/storage/*.cbl src/contracts/*.cbl \
     src/messages/*.cbl src/math/*.cbl \
     c/bslt_crypto_glue.c c/basalt_bridge.c
```

---

## 3. C Client Integration

```c
#include "c/basalt.h"
#include <stdio.h>

int main(void) {
    /* Initialize the GnuCOBOL runtime and Basalt engine */
    bslt_init();

    /* Provision a new clearing member settlement account */
    int rc = bslt_account_create("ACC-JPM-0001", "CHASUS33XXX", "USD", 1, 500000000.0);
    if (rc == BSLT_OK) {
        printf("Settlement account registered successfully.\n");
    }

    /* Execute a multilateral cycle netting sweep */
    uint16_t cycles = 0;
    double volume = 0.0;
    bslt_netting_run_cycle(10, 25, &cycles, &volume);
    printf("Netting pass resolved %d elementary cycles.\n", cycles);

    /* Clean shutdown */
    bslt_shutdown();
    return 0;
}
```

Compile with:

```bash
clang -O3 -I c example.c -L bin -lbasalt -lcob -o example
```

---

## 4. Python ctypes SDK

The `python/basalt.py` module exposes an idiomatic Python interface:

```python
from python.basalt import BasaltClearinghouse

# Connect to the local compiled kernel
ch = BasaltClearinghouse()

# Provision clearing participants
ch.create_account(
    account_id="ACC-BNP-001",
    owner_bic="BNPAFRPPXXX",
    currency="USD",
    account_type=1,
    credit_limit=500000000.0
)

# Run multilateral cycle elimination
result = ch.run_multilateral_netting(num_nodes=8, num_edges=24)
print(f"Cycles Cancelled : {result.cycles_found}")
print(f"Volume Conserved : ${result.volume_cancelled:,.2f} USD")

# Evaluate SPAN portfolio risk
im = ch.calculate_span_margin([
    {"symbol": "UST-10Y", "notional": 25000000.0, "haircut": 0.015},
    {"symbol": "SPY",     "notional": 10000000.0, "haircut": 0.100}
])
print(f"Required Initial Margin: ${im:,.2f} USD")
```

---

## 5. Telemetry and Operational Console

Basalt provides an operational terminal dashboard for monitoring continuous multilateral clearing:

```bash
python3 python/dashboard.py
```

The console displays real-time liquidity compression ratios, CPMI-IOSCO waterfall tranche absorption, ARIES log sequence progression, and interbank nostro liquidity balances.
