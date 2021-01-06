# Basalt: Deterministic Bi-Temporal Clearinghouse and Settlement Kernel in Pure COBOL
# Compiler configuration

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

# Targets
.PHONY: all clean test bench demo verify help

all: directories $(BIN_DIR)/basalt $(BIN_DIR)/test_runner

directories:
	@mkdir -p $(BIN_DIR) $(OBJ_DIR)

help:
	@echo "Basalt: High-Assurance Financial Settlement Kernel"
	@echo "Available targets:"
	@echo "  make              - Build core kernel and test harness"
	@echo "  make test         - Run full verification test suite"
	@echo "  make bench        - Run settlement and math benchmarks"
	@echo "  make demo         - Run interactive multilateral netting demo"
	@echo "  make clean        - Remove build artifacts and temporary files"

clean:
	@rm -rf $(BIN_DIR) $(OBJ_DIR) *.wal *.dat *.tmp *.log

