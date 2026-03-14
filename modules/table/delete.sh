#!/bin/bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/validation.sh" ]] && source "$DBMS_ROOT/lib/validation.sh"

tbl_delete() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name to delete from")
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

    # find PK column
    local pk_col=0
    while IFS= read -r line; do
        IFS=':' read -r colname coltype rest <<< "$line"
        if [[ "$rest" == "PK" ]]; then
            pk_col=$((pk_col+1))
            break
        fi
        pk_col=$((pk_col+1))
    done < "$meta_file"

    if (( pk_col == 0 )); then
        print_error "No primary key defined for table '$table' — delete by PK supported only"
        return 1
    fi

    local pk_val
    pk_val=$(read_input "Enter primary key value to delete")

    # if pk_is_unique returns 0 -> unique (not found) -> error
    if pk_is_unique "$data_file" "$pk_col" "$pk_val"; then
        print_error "No row with PK=$pk_val"
        return 1
    fi

    local tmp
    tmp=$(mktemp)
    awk -F"$SEPARATOR" -v OFS="$SEPARATOR" -v pkcol="$pk_col" -v val="$pk_val" '$pkcol != val {print}' "$data_file" > "$tmp"
    mv "$tmp" "$data_file"
    print_success "Deleted rows with PK=$pk_val from '$table'"
}
