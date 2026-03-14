#!/bin/bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/display.sh" ]] && source "$DBMS_ROOT/lib/display.sh"

tbl_select() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name to select from")
    if ! is_valid_name "$table"; then
        print_error "Invalid table name"
        return 1
    fi

    local meta_file="$DB_PATH/${table}${META_EXT}"
    local data_file="$DB_PATH/${table}${DATA_EXT}"
    if [[ ! -f "$meta_file" ]]; then
        print_error "Table '$table' does not exist"
        return 1
    fi

    if [[ ! -s "$data_file" ]]; then
        print_info "No rows"
        return 0
    fi

    display_table "$meta_file" "$data_file"
}
