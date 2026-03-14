#!/bin/bash
# ================================================================
# test_database.sh — Full coverage tests for database modules:
#   create_db  |  list_db  |  drop_db  |  connect_db
# ================================================================

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBMS_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

# ── Load colours & helpers (skip config.sh — it resets DATA_DIR) ──
source "$DBMS_ROOT/lib/utils.sh"

# ── Point DATA_DIR at an isolated temp directory ──────────────────
export DATA_DIR
DATA_DIR="$(mktemp -d /tmp/bash_dbms_test_XXXXXX)"

# ── Source database modules under test ───────────────────────────
source "$DBMS_ROOT/modules/database/create_db.sh"
source "$DBMS_ROOT/modules/database/list_db.sh"
source "$DBMS_ROOT/modules/database/drop_db.sh"
source "$DBMS_ROOT/modules/database/connect_db.sh"

# ── Stub side-effect dependencies used by modules ────────────────
log_info() { :; }
log_warn() { :; }
log_error() { :; }
log_success() { :; }
table_menu() { :; }

# ================================================================
#  Minimal test framework
# ================================================================
PASS=0
FAIL=0

_pass() { ((PASS++)); echo -e "\033[0;32m  [PASS]\033[0m $1"; }
_fail() { ((FAIL++)); echo -e "\033[0;31m  [FAIL]\033[0m $1"; }

assert_exit_ok() {
    local rc=$1 desc=$2
    [[ $rc -eq 0 ]] && _pass "$desc" || _fail "$desc  (expected exit 0, got $rc)"
}

assert_exit_err() {
    local rc=$1 desc=$2
    [[ $rc -ne 0 ]] && _pass "$desc" || _fail "$desc  (expected non-zero exit, got 0)"
}

assert_contains() {
    local desc=$1 needle=$2 haystack=$3
    [[ "$haystack" == *"$needle"* ]] \
        && _pass "$desc" \
        || _fail "$desc  (expected '$needle' in output)"
}

assert_not_contains() {
    local desc=$1 needle=$2 haystack=$3
    [[ "$haystack" != *"$needle"* ]] \
        && _pass "$desc" \
        || _fail "$desc  (did NOT expect '$needle' in output)"
}

assert_dir_exists() {
    [[ -d "$1" ]] && _pass "$2" || _fail "$2  (dir '$1' missing)"
}

assert_dir_gone() {
    [[ ! -d "$1" ]] && _pass "$2" || _fail "$2  (dir '$1' should not exist)"
}

# ================================================================
#  Stub helpers — re-define read_input and confirm per test
# ================================================================
MOCK_INPUT=""
MOCK_CONFIRM="n"

read_input() { echo "$MOCK_INPUT"; }
confirm()    { [[ "$MOCK_CONFIRM" =~ ^[Yy]$ ]]; }

# ================================================================
#  Setup / Teardown
# ================================================================
setup()    { rm -rf "$DATA_DIR"; mkdir -p "$DATA_DIR"; }
teardown() { rm -rf "$DATA_DIR"; mkdir -p "$DATA_DIR"; }   # keep dir for next group

make_db()  { mkdir -p "$DATA_DIR/$1"; }   # helper: pre-create a DB dir

# ================================================================
#  Tests: is_valid_name  (shared validator used by all modules)
# ================================================================
test_is_valid_name() {
    echo ""
    echo "── is_valid_name ───────────────────────────────────────────────"

    # --- valid names ------------------------------------------------
    is_valid_name "mydb"          && _pass "valid: simple lowercase"       || _fail "valid: simple lowercase"
    is_valid_name "MyDB"          && _pass "valid: mixed case"             || _fail "valid: mixed case"
    is_valid_name "db_2"          && _pass "valid: underscore + digit"     || _fail "valid: underscore + digit"
    is_valid_name "_leading"      && _pass "valid: leading underscore"     || _fail "valid: leading underscore"
    is_valid_name "a"             && _pass "valid: single char"            || _fail "valid: single char"
    is_valid_name "ALLCAPS"       && _pass "valid: all caps"               || _fail "valid: all caps"
    is_valid_name "mix_123_End"   && _pass "valid: complex valid name"     || _fail "valid: complex valid name"

    # --- invalid names ----------------------------------------------
    ! is_valid_name ""            && _pass "invalid: empty string"         || _fail "invalid: empty string"
    ! is_valid_name "1starts"     && _pass "invalid: starts with digit"    || _fail "invalid: starts with digit"
    ! is_valid_name "has space"   && _pass "invalid: contains space"       || _fail "invalid: contains space"
    ! is_valid_name "has-dash"    && _pass "invalid: contains dash"        || _fail "invalid: contains dash"
    ! is_valid_name "dot.name"    && _pass "invalid: contains dot"         || _fail "invalid: contains dot"
    ! is_valid_name "slash/name"  && _pass "invalid: contains slash"       || _fail "invalid: contains slash"
    ! is_valid_name "semi;colon"  && _pass "invalid: contains semicolon"   || _fail "invalid: contains semicolon"
    ! is_valid_name "at@sign"     && _pass "invalid: contains @"           || _fail "invalid: contains @"
    ! is_valid_name "star*"       && _pass "invalid: contains *"           || _fail "invalid: contains *"
}

# ================================================================
#  Tests: create_db
# ================================================================
test_create_db() {
    echo ""
    echo "── create_db ───────────────────────────────────────────────────"
    setup

    local out rc

    # 1 — happy path: valid new name
    MOCK_INPUT="testdb"
    out=$(create_db 2>&1); rc=$?
    assert_exit_ok  $rc "create: valid name exits 0"
    assert_dir_exists "$DATA_DIR/testdb" "create: directory is created"
    assert_contains   "create: success message shown" "testdb" "$out"

    # 2 — duplicate: same name again
    MOCK_INPUT="testdb"
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: duplicate exits non-0"
    assert_contains "create: 'already exist' error shown" "already exist" "$out"

    # 3 — invalid: special characters
    MOCK_INPUT="bad-name!"
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: special chars exits non-0"
    assert_contains "create: 'Invalid name' shown for special chars" "Invalid name" "$out"
    assert_dir_gone "$DATA_DIR/bad-name!" "create: no dir created for special chars"

    # 4 — invalid: starts with digit
    MOCK_INPUT="1db"
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: digit-leading name exits non-0"
    assert_dir_gone "$DATA_DIR/1db" "create: no dir created for digit-leading name"

    # 5 — invalid: empty string
    MOCK_INPUT=""
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: empty name exits non-0"
    assert_contains "create: 'Invalid name' shown for empty input" "Invalid name" "$out"

    # 6 — invalid: name with spaces
    MOCK_INPUT="my db"
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: name with space exits non-0"
    assert_dir_gone "$DATA_DIR/my db" "create: no dir for space name"

    # 7 — invalid: name with dash
    MOCK_INPUT="my-db"
    out=$(create_db 2>&1); rc=$?
    assert_exit_err $rc "create: dash in name exits non-0"

    # 8 — valid: underscore and digits in name
    MOCK_INPUT="my_database_2"
    out=$(create_db 2>&1); rc=$?
    assert_exit_ok  $rc "create: underscore+digit name exits 0"
    assert_dir_exists "$DATA_DIR/my_database_2" "create: underscore+digit dir created"

    # 9 — valid: all-uppercase name
    MOCK_INPUT="PROD_DB"
    out=$(create_db 2>&1); rc=$?
    assert_exit_ok  $rc "create: all-caps name exits 0"
    assert_dir_exists "$DATA_DIR/PROD_DB" "create: all-caps dir created"

    teardown
}

# ================================================================
#  Tests: list_db
# ================================================================
test_list_db() {
    echo ""
    echo "── list_db ─────────────────────────────────────────────────────"
    setup

    local out

    # 1 — empty DATA_DIR
    out=$(list_db 2>&1)
    assert_exit_ok  0 "list: exits 0 when no DBs"
    assert_contains "list: 'No Databases found' when empty" "No Databases found" "$out"
    assert_not_contains "list: no header when empty" "Available Databases" "$out"

    # 2 — single database
    make_db "alpha"
    out=$(list_db 2>&1)
    assert_contains "list: shows DB name 'alpha'" "alpha" "$out"
    assert_contains "list: shows 'Total: 1'" "Total: 1" "$out"
    assert_contains "list: header printed" "Available Databases" "$out"

    # 3 — multiple databases
    make_db "beta"
    make_db "gamma"
    out=$(list_db 2>&1)
    assert_contains "list: shows 'alpha' among many"  "alpha" "$out"
    assert_contains "list: shows 'beta' among many"   "beta"  "$out"
    assert_contains "list: shows 'gamma' among many"  "gamma" "$out"
    assert_contains "list: shows 'Total: 3'" "Total: 3" "$out"

    # 4 — does NOT show 'No Databases found' when DBs exist
    assert_not_contains "list: no empty-message when DBs present" "No Databases found" "$out"

    teardown
}

# ================================================================
#  Tests: drop_db
# ================================================================
test_drop_db() {
    echo ""
    echo "── drop_db ─────────────────────────────────────────────────────"
    setup

    local out rc

    # 1 — confirmed drop of existing DB
    make_db "to_drop"
    MOCK_INPUT="to_drop"; MOCK_CONFIRM="y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_ok  $rc "drop: confirmed drop exits 0"
    assert_dir_gone "$DATA_DIR/to_drop" "drop: directory removed after drop"
    assert_contains "drop: success message shown" "dropped successfully" "$out"

    # 2 — cancel (confirm = n) — directory preserved
    make_db "keep_me"
    MOCK_INPUT="keep_me"; MOCK_CONFIRM="n"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_ok  $rc "drop: cancelled drop exits 0"
    assert_dir_exists "$DATA_DIR/keep_me" "drop: directory preserved on cancel"
    assert_contains "drop: 'cancelled' message shown" "cancelled" "$out"

    # 3 — non-existent database
    MOCK_INPUT="ghost_db"; MOCK_CONFIRM="y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_err $rc "drop: non-existent DB exits non-0"
    assert_contains "drop: 'does not exist' error shown" "does not exist" "$out"

    # 4 — invalid name: special chars
    MOCK_INPUT="bad name!"; MOCK_CONFIRM="y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_err $rc "drop: invalid name exits non-0"
    assert_contains "drop: 'Invalid name' shown" "Invalid name" "$out"

    # 5 — invalid name: empty
    MOCK_INPUT=""; MOCK_CONFIRM="y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_err $rc "drop: empty name exits non-0"
    assert_contains "drop: 'Invalid name' shown for empty" "Invalid name" "$out"

    # 6 — invalid name: starts with digit
    MOCK_INPUT="3db"; MOCK_CONFIRM="y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_err $rc "drop: digit-leading name exits non-0"

    # 7 — confirm with uppercase Y
    make_db "drop_with_Y"
    MOCK_INPUT="drop_with_Y"; MOCK_CONFIRM="Y"
    out=$(drop_db 2>&1); rc=$?
    assert_exit_ok  $rc "drop: uppercase Y confirm exits 0"
    assert_dir_gone "$DATA_DIR/drop_with_Y" "drop: directory removed with Y confirm"

    teardown
}

# ================================================================
#  Tests: connect_db
# ================================================================
test_connect_db() {
    echo ""
    echo "── connect_db ──────────────────────────────────────────────────"
    setup

    local out rc

    # 1 — connect to existing database
    make_db "mydb"
    MOCK_INPUT="mydb"
    out=$(connect_db 2>&1); rc=$?
    assert_exit_ok  $rc "connect: existing DB exits 0"
    assert_contains "connect: success message shown" "Connected to database mydb" "$out"

    # 2 — non-existent database
    MOCK_INPUT="phantom"
    out=$(connect_db 2>&1); rc=$?
    assert_exit_err $rc "connect: non-existent DB exits non-0"
    assert_contains "connect: 'does not exist' error" "does not exist" "$out"

    # 3 — invalid name: special chars
    MOCK_INPUT="bad-db!"
    out=$(connect_db 2>&1); rc=$?
    assert_exit_err $rc "connect: special chars exits non-0"
    assert_contains "connect: 'Invalid name' shown" "Invalid name" "$out"

    # 4 — invalid name: empty
    MOCK_INPUT=""
    out=$(connect_db 2>&1); rc=$?
    assert_exit_err $rc "connect: empty name exits non-0"
    assert_contains "connect: 'Invalid name' shown for empty" "Invalid name" "$out"

    # 5 — invalid name: starts with digit
    MOCK_INPUT="1db"
    out=$(connect_db 2>&1); rc=$?
    assert_exit_err $rc "connect: digit-leading name exits non-0"

    # 6 — invalid name: name with space
    MOCK_INPUT="my db"
    out=$(connect_db 2>&1); rc=$?
    assert_exit_err $rc "connect: name with space exits non-0"

    # 7 — list_db is called (output includes header)
    make_db "visible_db"
    MOCK_INPUT="visible_db"
    out=$(connect_db 2>&1)
    assert_contains "connect: list_db output shown before prompt" "visible_db" "$out"

    teardown
}

# ================================================================
#  Run all test groups
# ================================================================
echo "══════════════════════════════════════════════════════════════"
echo "      Bash DBMS — Database Module Test Suite"
echo "══════════════════════════════════════════════════════════════"

test_is_valid_name
test_create_db
test_list_db
test_drop_db
test_connect_db

# ── Final cleanup ─────────────────────────────────────────────────
rm -rf "$DATA_DIR"

# ── Summary ───────────────────────────────────────────────────────
TOTAL=$(( PASS + FAIL ))
echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "  Results:  \033[0;32m${PASS} passed\033[0m  |  \033[0;31m${FAIL} failed\033[0m  |  ${TOTAL} total"
echo "══════════════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1