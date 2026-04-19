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
INCLUDE_DIR="${PROJECT_ROOT}/include"
HOST_CC="${HOST_CC:-cc}"

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
    echo "  --no-host       Skip native host build/run (only test RARS path)"
    echo "  --example NAME  Run only the specified example (e.g. 01_hello)"
    echo "  -v, --verbose   Verbose output"
    echo "  -h, --help      Show this help"
    echo ""
    echo "Environment:"
    echo "  HOST_CC         Native compiler for host build (default: cc)"
}

DO_BUILD=false
NO_RARS=false
NO_HOST=false
SINGLE=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --build)     DO_BUILD=true; shift ;;
        --no-rars)   NO_RARS=true; shift ;;
        --no-host)   NO_HOST=true; shift ;;
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

if ! $NO_HOST && ! command -v "$HOST_CC" &>/dev/null; then
    echo -e "${YELLOW}Warning: $HOST_CC not found — skipping native host build${NC}"
    NO_HOST=true
fi

mkdir -p "$OUTPUT_DIR"

run_single_test() {
    local cfile="$1"
    local name="$2"
    local test_output_dir="$3"

    local asm_file="${test_output_dir}/${name}.asm"

    local c2rars_args=(-i "$cfile" -o "$asm_file")
    if $VERBOSE; then
        c2rars_args+=(-v)
    fi

    if ! "$C2RARS" "${c2rars_args[@]}" >"${test_output_dir}/${name}.c2rars.log" 2>&1; then
        return 1
    fi

    if [[ ! -f "$asm_file" ]]; then
        return 1
    fi

    echo "$asm_file"
    return 0
}

# Run RARS path. Sets globals: RARS_STATUS (pass|fail|skip), RARS_DETAIL (msg).
run_rars_path() {
    local example_dir="$1"
    local name="$2"
    local test_output_dir="$3"
    local expected_file="$4"
    shift 4
    local c_files=("$@")

    local asm_files=()

    if [[ ${#c_files[@]} -eq 1 ]]; then
        local result
        if ! result=$(run_single_test "${c_files[0]}" "$name" "$test_output_dir"); then
            RARS_STATUS=fail
            RARS_DETAIL="c2rars transformation failed"
            return
        fi
        asm_files+=("$result")
    else
        for cfile in "${c_files[@]}"; do
            local basename_c
            basename_c="$(basename "$cfile" .c)"
            local result
            if ! result=$(run_single_test "$cfile" "$basename_c" "$test_output_dir"); then
                RARS_STATUS=fail
                RARS_DETAIL="c2rars transformation failed for $basename_c"
                return
            fi
            asm_files+=("$result")
        done

        # Verify: non-main .asm files must NOT contain .globl main; reorder so
        # the file with main: is first (RARS requirement).
        local main_asm=""
        local other_asms=()
        for asm_file in "${asm_files[@]}"; do
            local basename_asm
            basename_asm="$(basename "$asm_file" .asm)"
            if grep -q '^main:' "$asm_file" 2>/dev/null; then
                main_asm="$asm_file"
            else
                other_asms+=("$asm_file")
                if grep -q '\.globl main' "$asm_file" 2>/dev/null; then
                    RARS_STATUS=fail
                    RARS_DETAIL="${basename_asm}.asm has .globl main but no main function"
                    return
                fi
            fi
        done
        asm_files=()
        if [[ -n "$main_asm" ]]; then
            asm_files+=("$main_asm")
        fi
        asm_files+=("${other_asms[@]}")
    fi

    if [[ ! -f "$expected_file" ]]; then
        RARS_STATUS=skip
        RARS_DETAIL="no expected output (interactive)"
        return
    fi

    if $NO_RARS; then
        RARS_STATUS=skip
        RARS_DETAIL="--no-rars"
        return
    fi

    local actual_file="${test_output_dir}/${name}.rars.actual.txt"
    if ! java -jar "$RARS_JAR" nc "${asm_files[@]}" > "$actual_file" 2>"${test_output_dir}/${name}.rars.log"; then
        RARS_STATUS=fail
        RARS_DETAIL="RARS simulation error"
        return
    fi

    if diff -q "$expected_file" "$actual_file" &>/dev/null; then
        RARS_STATUS=pass
        RARS_DETAIL=""
    else
        RARS_STATUS=fail
        RARS_DETAIL="output mismatch"
        if $VERBOSE; then
            echo
            echo "    --- RARS expected ---"
            cat "$expected_file"
            echo "    --- RARS actual ---"
            cat "$actual_file"
            echo "    --- diff ---"
            diff "$expected_file" "$actual_file" || true
        fi
    fi
}

run_host_path() {
    local name="$1"
    local test_output_dir="$2"
    local expected_file="$3"
    shift 3
    local c_files=("$@")

    if $NO_HOST; then
        HOST_STATUS=skip
        HOST_DETAIL="--no-host"
        return
    fi

    if [[ ! -f "$expected_file" ]]; then
        HOST_STATUS=skip
        HOST_DETAIL="no expected output (interactive)"
        return
    fi

    local bin="${test_output_dir}/${name}.host"
    local cc_log="${test_output_dir}/${name}.host.cc.log"

    if ! "$HOST_CC" -I "$INCLUDE_DIR" -O0 -Wno-implicit-function-declaration \
        "${c_files[@]}" -o "$bin" >"$cc_log" 2>&1; then
        HOST_STATUS=fail
        HOST_DETAIL="$HOST_CC compile failed"
        if $VERBOSE; then
            echo
            cat "$cc_log"
        fi
        return
    fi

    local actual_file="${test_output_dir}/${name}.host.actual.txt"
    if ! "$bin" > "$actual_file" 2>"${test_output_dir}/${name}.host.run.log"; then
        HOST_STATUS=fail
        HOST_DETAIL="host binary crashed"
        return
    fi

    if diff -q "$expected_file" "$actual_file" &>/dev/null; then
        HOST_STATUS=pass
        HOST_DETAIL=""
    else
        HOST_STATUS=fail
        HOST_DETAIL="output mismatch"
        if $VERBOSE; then
            echo
            echo "    --- host expected ---"
            cat "$expected_file"
            echo "    --- host actual ---"
            cat "$actual_file"
            echo "    --- diff ---"
            diff "$expected_file" "$actual_file" || true
        fi
    fi
}

run_test() {
    local example_dir="$1"
    local name
    name="$(basename "$example_dir")"

    local test_output_dir="${OUTPUT_DIR}/${name}"
    mkdir -p "$test_output_dir"

    local expected_file="${EXPECTED_DIR}/${name}.txt"

    printf "  %-20s " "$name"

    local c_files=()
    while IFS= read -r -d '' f; do
        c_files+=("$f")
    done < <(find "$example_dir" -maxdepth 1 -name '*.c' -print0 | sort -z)

    if [[ ${#c_files[@]} -eq 0 ]]; then
        echo -e "${YELLOW}SKIP${NC} (no .c files)"
        SKIP=$((SKIP + 1))
        return
    fi

    RARS_STATUS=pass; RARS_DETAIL=""
    HOST_STATUS=pass; HOST_DETAIL=""

    run_rars_path "$example_dir" "$name" "$test_output_dir" "$expected_file" "${c_files[@]}"
    run_host_path "$name" "$test_output_dir" "$expected_file" "${c_files[@]}"

    local backends=()
    [[ "$RARS_STATUS" == pass ]] && backends+=("RARS")
    [[ "$HOST_STATUS" == pass ]] && backends+=("host")
    local backends_str
    if [[ ${#backends[@]} -eq 0 ]]; then
        backends_str="none"
    else
        backends_str=$(printf "%s" "${backends[@]/%/ + }")
        backends_str=${backends_str% + }
    fi

    if [[ "$RARS_STATUS" == fail || "$HOST_STATUS" == fail ]]; then
        local msg=""
        [[ "$RARS_STATUS" == fail ]] && msg="RARS: $RARS_DETAIL"
        if [[ "$HOST_STATUS" == fail ]]; then
            [[ -n "$msg" ]] && msg+="; "
            msg+="host: $HOST_DETAIL"
        fi
        echo -e "${RED}FAIL${NC} ($msg)"
        FAIL=$((FAIL + 1))
        return
    fi

    if [[ "$RARS_STATUS" == skip && "$HOST_STATUS" == skip ]]; then
        local msg=""
        [[ -n "$RARS_DETAIL" ]] && msg="$RARS_DETAIL"
        echo -e "${GREEN}PASS${NC} (transform only${msg:+: $msg})"
        PASS=$((PASS + 1))
        return
    fi

    echo -e "${GREEN}PASS${NC} ($backends_str)"
    PASS=$((PASS + 1))
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
    example_dir="${EXAMPLES_DIR}/${SINGLE}"
    if [[ ! -d "$example_dir" ]]; then
        echo -e "${RED}Error: example directory not found: $example_dir${NC}"
        exit 1
    fi
    run_test "$example_dir"
else
    for example_dir in "$EXAMPLES_DIR"/*/; do
        [[ -d "$example_dir" ]] || continue
        run_test "$example_dir"
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
