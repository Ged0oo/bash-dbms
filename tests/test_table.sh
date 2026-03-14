#!/bin/bash
# ================================================================
# test_table.sh — Full coverage tests for table modules:
#   tbl_create | tbl_list | tbl_drop | tbl_insert | tbl_select
#   tbl_delete | tbl_update
# ================================================================

TESTS_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DBMS_ROOT="$(cd "$TESTS_DIR/.." && pwd)"

# ── Isolated temp paths ───────────────────────────────────────────
export DATA_DIR
DATA_DIR="$(mktemp -d /tmp/bash_dbms_table_test_XXXXXX)"
DB_PATH="$DATA_DIR/testdb"
mkdir -p "$DB_PATH"

# ── Load shared utilities ─────────────────────────────────────────
source "$DBMS_ROOT/lib/utils.sh"
source "$DBMS_ROOT/lib/validation.sh"

# ── Source table modules under test ───────────────────────────────
source "$DBMS_ROOT/modules/table/create_table.sh"
source "$DBMS_ROOT/modules/table/list_tables.sh"
source "$DBMS_ROOT/modules/table/drop_table.sh"
source "$DBMS_ROOT/modules/table/insert.sh"
source "$DBMS_ROOT/modules/table/select.sh"
source "$DBMS_ROOT/modules/table/delete.sh"
source "$DBMS_ROOT/modules/table/update.sh"

# sourced modules enable strict mode; disable fail-fast in tests
set +e

# keep tests sandboxed after config.sh side effects from sourced modules
DATA_DIR="$(dirname "$DB_PATH")"
mkdir -p "$DB_PATH"

# ── Stub side-effect dependencies ─────────────────────────────────
log_info() { :; }
log_warn() { :; }
log_error() { :; }
log_success() { :; }
display_table() {
    local meta_file="$1"
    local data_file="$2"
    echo "DISPLAY:$(basename "$meta_file"):$(basename "$data_file")"
}

# ================================================================
#  Minimal test framework (same style as test_database.sh)
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
    [[ "$haystack" == *"$needle"* ]] && _pass "$desc" || _fail "$desc  (expected '$needle' in output)"
}

assert_not_contains() {
    local desc=$1 needle=$2 haystack=$3
    [[ "$haystack" != *"$needle"* ]] && _pass "$desc" || _fail "$desc  (did NOT expect '$needle' in output)"
}

assert_file_exists() {
    [[ -f "$1" ]] && _pass "$2" || _fail "$2  (file '$1' missing)"
}

assert_file_gone() {
    [[ ! -f "$1" ]] && _pass "$2" || _fail "$2  (file '$1' should not exist)"
}

assert_file_contains() {
    local file=$1 needle=$2 desc=$3
    grep -q -- "$needle" "$file" 2>/dev/null && _pass "$desc" || _fail "$desc  (expected '$needle' in $file)"
}

# ================================================================
#  Mock helpers — support sequential read_input values
# ================================================================
MOCK_CONFIRM="n"
MOCK_INPUT_FILE="$DATA_DIR/.mock_input"

set_mock_inputs() {
    : > "$MOCK_INPUT_FILE"
    for item in "$@"; do
        printf '%s\n' "$item" >> "$MOCK_INPUT_FILE"
    done
}

read_input() {
    local value=""
    if [[ -s "$MOCK_INPUT_FILE" ]]; then
        value="$(head -n1 "$MOCK_INPUT_FILE")"
        tail -n +2 "$MOCK_INPUT_FILE" > "$MOCK_INPUT_FILE.tmp"
        mv "$MOCK_INPUT_FILE.tmp" "$MOCK_INPUT_FILE"
    fi
    echo "$value"
}

confirm() { [[ "$MOCK_CONFIRM" =~ ^[Yy]$ ]]; }

# ================================================================
#  Setup / Teardown
# ================================================================
setup() {
    rm -rf "$DB_PATH"
    mkdir -p "$DB_PATH"
    : > "$MOCK_INPUT_FILE"
    MOCK_CONFIRM="n"
}

teardown() {
    rm -rf "$DB_PATH"
    mkdir -p "$DB_PATH"
}

create_people_table_schema() {
    cat > "$DB_PATH/people.meta" <<EOF
id:int:PK
name:str
age:int
EOF
    : > "$DB_PATH/people.data"
}

# ================================================================
#  Tests: tbl_create
# ================================================================
test_tbl_create() {
    echo ""
    echo "── tbl_create ─────────────────────────────────────────────────"
    setup

    local out rc

    # 1 — happy path
    set_mock_inputs "people" "id" "int" "name" "str"
    out=$(tbl_create "$DB_PATH" <<< $'2\n1\n' 2>&1); rc=$?
    assert_exit_ok $rc "create table: valid schema exits 0"
    assert_file_exists "$DB_PATH/people.meta" "create table: meta file created"
    assert_file_exists "$DB_PATH/people.data" "create table: data file created"
    assert_file_contains "$DB_PATH/people.meta" "id:int:PK" "create table: PK marked in meta"

    # 2 — duplicate table
    set_mock_inputs "people"
    out=$(tbl_create "$DB_PATH" <<< $'2\n1\n' 2>&1); rc=$?
    assert_exit_err $rc "create table: duplicate exits non-0"
    assert_contains "create table: duplicate error shown" "already exists" "$out"

    # 3 — invalid table name
    set_mock_inputs "bad-name"
    out=$(tbl_create "$DB_PATH" <<< $'2\n1\n' 2>&1); rc=$?
    assert_exit_err $rc "create table: invalid name exits non-0"
    assert_contains "create table: invalid-name message" "Invalid table name" "$out"

    # 4 — invalid DB path
    set_mock_inputs "anything"
    out=$(tbl_create "/no/such/path" <<< $'2\n1\n' 2>&1); rc=$?
    assert_exit_err $rc "create table: invalid DB path exits non-0"

    teardown
}

# ================================================================
#  Tests: tbl_list
# ================================================================
test_tbl_list() {
    echo ""
    echo "── tbl_list ───────────────────────────────────────────────────"
    setup

    local out rc

    # 1 — no tables
    out=$(tbl_list "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "list tables: empty DB exits 0"
    assert_contains "list tables: empty message shown" "No tables found" "$out"

    # 2 — with tables
    create_people_table_schema
    cp "$DB_PATH/people.meta" "$DB_PATH/departments.meta"
    : > "$DB_PATH/departments.data"
    out=$(tbl_list "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "list tables: populated DB exits 0"
    assert_contains "list tables: people shown" "people" "$out"
    assert_contains "list tables: departments shown" "departments" "$out"

    teardown
}

# ================================================================
#  Tests: tbl_drop
# ================================================================
test_tbl_drop() {
    echo ""
    echo "── tbl_drop ───────────────────────────────────────────────────"
    setup

    local out rc

    create_people_table_schema

    # 1 — cancel drop
    set_mock_inputs "people"
    MOCK_CONFIRM="n"
    out=$(tbl_drop "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "drop table: cancelled exits 0"
    assert_file_exists "$DB_PATH/people.meta" "drop table: meta preserved on cancel"

    # 2 — confirmed drop
    set_mock_inputs "people"
    MOCK_CONFIRM="y"
    out=$(tbl_drop "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "drop table: confirmed exits 0"
    assert_file_gone "$DB_PATH/people.meta" "drop table: meta removed"
    assert_file_gone "$DB_PATH/people.data" "drop table: data removed"

    # 3 — non-existent table
    set_mock_inputs "ghost"
    out=$(tbl_drop "$DB_PATH" 2>&1); rc=$?
    assert_exit_err $rc "drop table: non-existent exits non-0"

    teardown
}

# ================================================================
#  Tests: tbl_insert
# ================================================================
test_tbl_insert() {
    echo ""
    echo "── tbl_insert ─────────────────────────────────────────────────"
    setup

    local out rc

    create_people_table_schema

    # 1 — happy path
    set_mock_inputs "people" "1" "Alice" "30"
    out=$(tbl_insert "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "insert: valid row exits 0"
    assert_file_contains "$DB_PATH/people.data" "1:Alice:30" "insert: row written"

    # 2 — duplicate PK
    set_mock_inputs "people" "1" "Bob" "40"
    out=$(tbl_insert "$DB_PATH" 2>&1); rc=$?
    assert_exit_err $rc "insert: duplicate PK exits non-0"
    assert_contains "insert: duplicate PK message" "already exists" "$out"

    # 3 — invalid int then valid retry
    set_mock_inputs "people" "abc" "2" "Charlie" "25"
    out=$(tbl_insert "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "insert: retries invalid int and succeeds"
    assert_file_contains "$DB_PATH/people.data" "2:Charlie:25" "insert: retry row written"

    teardown
}

# ================================================================
#  Tests: tbl_select
# ================================================================
test_tbl_select() {
    echo ""
    echo "── tbl_select ─────────────────────────────────────────────────"
    setup

    local out rc

    create_people_table_schema

    # 1 — no rows
    set_mock_inputs "people"
    out=$(tbl_select "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "select: empty table exits 0"
    assert_contains "select: no rows message" "No rows" "$out"

    # 2 — with rows
    echo "1:Alice:30" >> "$DB_PATH/people.data"
    set_mock_inputs "people"
    out=$(tbl_select "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "select: with rows exits 0"
    assert_contains "select: display_table called" "DISPLAY:people.meta:people.data" "$out"

    teardown
}

# ================================================================
#  Tests: tbl_delete
# ================================================================
test_tbl_delete() {
    echo ""
    echo "── tbl_delete ─────────────────────────────────────────────────"
    setup

    local out rc

    create_people_table_schema
    cat > "$DB_PATH/people.data" <<EOF
1:Alice:30
2:Bob:40
EOF

    # 1 — delete existing PK
    set_mock_inputs "people" "2"
    out=$(tbl_delete "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "delete: existing PK exits 0"
    assert_not_contains "delete: row removed" "2:Bob:40" "$(cat "$DB_PATH/people.data")"

    # 2 — delete missing PK
    set_mock_inputs "people" "99"
    out=$(tbl_delete "$DB_PATH" 2>&1); rc=$?
    assert_exit_err $rc "delete: missing PK exits non-0"
    assert_contains "delete: missing PK message" "No row with PK=99" "$out"

    teardown
}

# ================================================================
#  Tests: tbl_update
# ================================================================
test_tbl_update() {
    echo ""
    echo "── tbl_update ─────────────────────────────────────────────────"
    setup

    local out rc

    create_people_table_schema
    cat > "$DB_PATH/people.data" <<EOF
1:Alice:30
2:Bob:40
EOF

    # 1 — update existing row (partial)
    set_mock_inputs "people" "1" "" "Alicia" ""
    out=$(tbl_update "$DB_PATH" 2>&1); rc=$?
    assert_exit_ok $rc "update: existing PK exits 0"
    assert_file_contains "$DB_PATH/people.data" "1:Alicia:30" "update: row updated"

    # 2 — update missing PK
    set_mock_inputs "people" "99"
    out=$(tbl_update "$DB_PATH" 2>&1); rc=$?
    assert_exit_err $rc "update: missing PK exits non-0"
    assert_contains "update: missing PK message" "No row with PK=99" "$out"

    # 3 — invalid typed value
    set_mock_inputs "people" "1" "" "" "not_int"
    out=$(tbl_update "$DB_PATH" 2>&1); rc=$?
    assert_exit_err $rc "update: invalid type exits non-0"
    assert_contains "update: invalid value message" "Invalid value for age" "$out"

    teardown
}

# ================================================================
#  Run all table test groups
# ================================================================
echo "══════════════════════════════════════════════════════════════"
echo "      Bash DBMS — Table Module Test Suite"
echo "══════════════════════════════════════════════════════════════"

test_tbl_create
test_tbl_list
test_tbl_drop
test_tbl_insert
test_tbl_select
test_tbl_delete
test_tbl_update

# ── Final cleanup ─────────────────────────────────────────────────
rm -rf "$DATA_DIR"

# ── Summary ───────────────────────────────────────────────────────
TOTAL=$(( PASS + FAIL ))
echo ""
echo "══════════════════════════════════════════════════════════════"
echo -e "  Results:  \033[0;32m${PASS} passed\033[0m  |  \033[0;31m${FAIL} failed\033[0m  |  ${TOTAL} total"
echo "══════════════════════════════════════════════════════════════"

[[ $FAIL -eq 0 ]] && exit 0 || exit 1
