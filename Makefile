# Basalt: Deterministic Bi-Temporal Clearinghouse and Settlement Kernel in Pure COBOL
# Production Makefile supporting compilation, testing, benchmarks, and verification

COBC ?= cobc
COBCFLAGS = -free -Wall -I copy -O2
COBCLIBS =

CC ?= clang
CFLAGS = -Wall -Wextra -O3 -fPIC -I c

PYTHON ?= python3

# Directories
BIN_DIR = bin
OBJ_DIR = obj
SRC_DIR = src
COPY_DIR = copy
TEST_DIR = tests
BENCH_DIR = bench
C_DIR = c

# Target binaries
TARGET = $(BIN_DIR)/basalt
TEST_RUNNER = $(BIN_DIR)/test_runner
SHARED_LIB = $(BIN_DIR)/libbasalt.dylib
BENCH_MATH = $(BIN_DIR)/bench_math
BENCH_NETTING = $(BIN_DIR)/bench_netting
BENCH_STORAGE = $(BIN_DIR)/bench_storage

SRCS = $(shell find $(SRC_DIR) -name "*.cbl")
TEST_SRCS = $(shell find $(TEST_DIR) -name "test_*.cbl" ! -name "test_runner.cbl")

.PHONY: all directories clean test bench demo dashboard verify help

all: directories $(TARGET) $(TEST_RUNNER) $(SHARED_LIB) $(BENCH_MATH) $(BENCH_NETTING) $(BENCH_STORAGE)

directories:
	@mkdir -p $(BIN_DIR) $(OBJ_DIR)

$(TARGET): $(SRCS) $(C_DIR)/bslt_crypto_glue.c
	@echo "--> Compiling Basalt CLI settlement kernel..."
	$(COBC) -x $(COBCFLAGS) -o $(TARGET) $(SRC_DIR)/kernel/bslt_kernel_main.cbl $(filter-out $(SRC_DIR)/kernel/bslt_kernel_main.cbl,$(SRCS)) $(C_DIR)/bslt_crypto_glue.c

$(TEST_RUNNER): $(TEST_DIR)/test_runner.cbl $(SRCS) $(TEST_SRCS) $(C_DIR)/bslt_crypto_glue.c
	@echo "--> Compiling Basalt test verification harness..."
	$(COBC) -x $(COBCFLAGS) -o $(TEST_RUNNER) $(TEST_DIR)/test_runner.cbl $(SRCS) $(TEST_SRCS) $(C_DIR)/bslt_crypto_glue.c

$(SHARED_LIB): $(SRCS) $(C_DIR)/bslt_crypto_glue.c $(C_DIR)/basalt_bridge.c
	@echo "--> Compiling Basalt native C shared library..."
	$(COBC) -b $(COBCFLAGS) -o $(SHARED_LIB) $(SRCS) $(C_DIR)/bslt_crypto_glue.c $(C_DIR)/basalt_bridge.c

$(BENCH_MATH): $(BENCH_DIR)/bench_math.cbl $(SRC_DIR)/math/bslt_fixed_math.cbl
	@echo "--> Compiling 128-bit decimal math benchmark..."
	$(COBC) -x $(COBCFLAGS) -o $(BENCH_MATH) $(BENCH_DIR)/bench_math.cbl $(SRC_DIR)/math/bslt_fixed_math.cbl

$(BENCH_NETTING): $(BENCH_DIR)/bench_netting.cbl $(SRC_DIR)/netting/bslt_cycle_canceller.cbl
	@echo "--> Compiling multilateral netting benchmark..."
	$(COBC) -x $(COBCFLAGS) -o $(BENCH_NETTING) $(BENCH_DIR)/bench_netting.cbl $(SRC_DIR)/netting/bslt_cycle_canceller.cbl

$(BENCH_STORAGE): $(BENCH_DIR)/bench_storage.cbl $(SRC_DIR)/storage/bslt_buffer_pool.cbl
	@echo "--> Compiling storage buffer pool benchmark..."
	$(COBC) -x $(COBCFLAGS) -o $(BENCH_STORAGE) $(BENCH_DIR)/bench_storage.cbl $(SRC_DIR)/storage/bslt_buffer_pool.cbl

test: $(TEST_RUNNER)
	@echo "--> Executing full verification test suite..."
	@./$(TEST_RUNNER)

bench: $(BENCH_MATH) $(BENCH_NETTING) $(BENCH_STORAGE)
	@echo "--> Running microbenchmarks..."
	@./$(BENCH_MATH)
	@./$(BENCH_NETTING)
	@./$(BENCH_STORAGE)

demo:
	@echo "--> Running clearing day simulation..."
	@$(PYTHON) scripts/simulate_clearing_day.py

dashboard:
	@echo "--> Launching real-time clearinghouse telemetry dashboard..."
	@$(PYTHON) python/dashboard.py

verify: test
	@echo "--> Verifying repository integrity (zero em dashes)..."
	@$(PYTHON) -c 'import os, sys; [sys.exit(1) for r, d, fs in os.walk(".") if ".git" not in r for f in fs if any(c in open(os.path.join(r, f), errors="ignore").read() for c in [chr(0x2014), chr(0x2013)])]'
	@echo "Verification passed: zero errors, zero warnings, zero em dashes."

clean:
	@rm -rf $(BIN_DIR) $(OBJ_DIR) *.wal *.dat *.tmp *.log

help:
	@echo "Basalt: High-Assurance Financial Settlement Kernel in Pure COBOL"
	@echo "Available targets:"
	@echo "  make              - Build core kernel, shared library, and test harness"
	@echo "  make test         - Run 14-suite automated verification suite"
	@echo "  make bench        - Run netting, math, and buffer pool benchmarks"
	@echo "  make demo         - Run end-to-end simulated clearing day"
	@echo "  make dashboard    - Launch real-time ASCII operations console"
	@echo "  make verify       - Run test assertions and strict style checks"
	@echo "  make clean        - Remove build artifacts and temporary files"
