#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"

tbl_drop() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name to drop")
    if ! is_valid_name "$table"; then
        print_error "Invalid table name"
        return 1
    fi

    local meta_file="$DB_PATH/${table}${META_EXT}"
    local data_file="$DB_PATH/${table}${DATA_EXT}"
    if [[ ! -f "$meta_file" && ! -f "$data_file" ]]; then
        print_error "Table '$table' does not exist"
        return 1
    fi

    if confirm "Are you sure you want to drop table '$table'?"; then
        [[ -f "$meta_file" ]] && rm -f "$meta_file"
        [[ -f "$data_file" ]] && rm -f "$data_file"
        print_success "Table '$table' dropped"
    else
        print_info "Aborted"
    fi
}
