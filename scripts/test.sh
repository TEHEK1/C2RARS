#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BUILD_DIR="${PROJECT_ROOT}/build"
C2RARS="${BUILD_DIR}/src/cli/c2rars"
RARS_JAR="${PROJECT_ROOT}/rars.jar"
EXAMPLES_DIR="${PROJECT_ROOT}/examples"
EXPECTED_DIR="${PROJECT_ROOT}/tests/expected_output"
OUTPUT_DIR="${BUILD_DIR}/test_output"

PASS=0
FAIL=0
SKIP=0

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m'

usage() {
    echo "Usage: $0 [options]"
    echo ""
    echo "Options:"
    echo "  --build         Build c2rars before testing (default: off)"
    echo "  --no-rars       Skip RARS simulation (only test c2rars transformation)"
    echo "  --example NAME  Run only the specified example (e.g. 01_hello)"
    echo "  -v, --verbose   Verbose output"
    echo "  -h, --help      Show this help"
}

DO_BUILD=false
NO_RARS=false
SINGLE=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)     DO_BUILD=true; shift ;;
        --no-rars)   NO_RARS=true; shift ;;
        --example)   SINGLE="$2"; shift 2 ;;
        -v|--verbose) VERBOSE=true; shift ;;
        -h|--help)   usage; exit 0 ;;
        *)           echo "Unknown option: $1"; usage; exit 1 ;;
    esac
done

if $DO_BUILD; then
    echo "==> Building c2rars..."
    mkdir -p "$BUILD_DIR"
    cmake -S "$PROJECT_ROOT" -B "$BUILD_DIR" -DCMAKE_BUILD_TYPE=Release 2>&1
    cmake --build "$BUILD_DIR" -j"$(nproc 2>/dev/null || sysctl -n hw.ncpu)" 2>&1
    echo ""
fi

if [[ ! -x "$C2RARS" ]]; then
    echo -e "${RED}Error: c2rars binary not found at $C2RARS${NC}"
    echo "Run with --build or build manually first."
    exit 1
fi

if ! $NO_RARS && [[ ! -f "$RARS_JAR" ]]; then
    echo -e "${YELLOW}Warning: rars.jar not found at $RARS_JAR — skipping simulation${NC}"
    NO_RARS=true
fi

if ! $NO_RARS && ! command -v java &>/dev/null; then
    echo -e "${YELLOW}Warning: java not found — skipping RARS simulation${NC}"
    NO_RARS=true
fi

mkdir -p "$OUTPUT_DIR"

run_test() {
    local cfile="$1"
    local name
    name="$(basename "$cfile" .c)"

    local asm_file="${OUTPUT_DIR}/${name}.asm"
    local actual_file="${OUTPUT_DIR}/${name}.actual.txt"
    local expected_file="${EXPECTED_DIR}/${name}.txt"

    printf "  %-20s " "$name"

    # Step 1: Transform C -> RARS assembly
    local c2rars_args=(-i "$cfile" -o "$asm_file")
    if $VERBOSE; then
        c2rars_args+=(-v)
    fi

    if ! "$C2RARS" "${c2rars_args[@]}" >"${OUTPUT_DIR}/${name}.c2rars.log" 2>&1; then
        echo -e "${RED}FAIL${NC} (c2rars transformation failed)"
        if $VERBOSE; then
            cat "${OUTPUT_DIR}/${name}.c2rars.log"
        fi
        FAIL=$((FAIL + 1))
        return
    fi

    if [[ ! -f "$asm_file" ]]; then
        echo -e "${RED}FAIL${NC} (no .asm output produced)"
        FAIL=$((FAIL + 1))
        return
    fi

    # Step 2: Run in RARS simulator
    if $NO_RARS; then
        echo -e "${GREEN}PASS${NC} (transform only)"
        PASS=$((PASS + 1))
        return
    fi

    if ! java -jar "$RARS_JAR" nc "$asm_file" > "$actual_file" 2>"${OUTPUT_DIR}/${name}.rars.log"; then
        echo -e "${RED}FAIL${NC} (RARS simulation error)"
        if $VERBOSE; then
            cat "${OUTPUT_DIR}/${name}.rars.log"
        fi
        FAIL=$((FAIL + 1))
        return
    fi

    # Step 3: Compare output with expected
    if [[ ! -f "$expected_file" ]]; then
        echo -e "${YELLOW}SKIP${NC} (no expected output file)"
        SKIP=$((SKIP + 1))
        return
    fi

    if diff -q "$expected_file" "$actual_file" &>/dev/null; then
        echo -e "${GREEN}PASS${NC}"
        PASS=$((PASS + 1))
    else
        echo -e "${RED}FAIL${NC} (output mismatch)"
        if $VERBOSE; then
            echo "    --- Expected ---"
            cat "$expected_file"
            echo "    --- Actual ---"
            cat "$actual_file"
            echo "    --- Diff ---"
            diff "$expected_file" "$actual_file" || true
        fi
        FAIL=$((FAIL + 1))
    fi
}

echo "========================================"
echo " C2RARS Integration Tests"
echo "========================================"
echo ""
echo "Binary:   $C2RARS"
echo "RARS:     $(if $NO_RARS; then echo 'disabled'; else echo $RARS_JAR; fi)"
echo "Examples: $EXAMPLES_DIR"
echo ""
echo "Results:"

if [[ -n "$SINGLE" ]]; then
    cfile="${EXAMPLES_DIR}/${SINGLE}.c"
    if [[ ! -f "$cfile" ]]; then
        echo -e "${RED}Error: example not found: $cfile${NC}"
        exit 1
    fi
    run_test "$cfile"
else
    for cfile in "$EXAMPLES_DIR"/*.c; do
        [[ -f "$cfile" ]] || continue
        run_test "$cfile"
    done
fi

echo ""
echo "========================================"
TOTAL=$((PASS + FAIL + SKIP))
echo -e " Total: $TOTAL  ${GREEN}Pass: $PASS${NC}  ${RED}Fail: $FAIL${NC}  ${YELLOW}Skip: $SKIP${NC}"
echo "========================================"

if [[ $FAIL -gt 0 ]]; then
    exit 1
fi
