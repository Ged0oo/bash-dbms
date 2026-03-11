#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/validation.sh" ]] && source "$DBMS_ROOT/lib/validation.sh"

tbl_update() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name to update")
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

    # read schema
    local -a cols types
    local pk_col=0
    while IFS= read -r line; do
        IFS=':' read -r colname coltype rest <<< "$line"
        cols+=("$colname")
        types+=("$coltype")
        if [[ "$rest" == "PK" ]]; then
            pk_col=${#cols[@]}
        fi
    done < "$meta_file"

    if (( pk_col == 0 )); then
        print_error "No primary key defined for table '$table' — update by PK supported only"
        return 1
    fi

    local pk_val
    pk_val=$(read_input "Enter primary key value to update")

    # check existence
    if pk_is_unique "$data_file" "$pk_col" "$pk_val"; then
        print_error "No row with PK=$pk_val"
        return 1
    fi

    # find the existing row and build new row
    local -a new_values
    # read current row into array
    IFS="$SEPARATOR" read -r -a current_row < <(awk -F"$SEPARATOR" -v pkcol="$pk_col" -v val="$pk_val" '$pkcol==val{print; exit}' "$data_file")

    for idx in "${!cols[@]}"; do
        local prompt="New value for ${cols[$idx]} (${types[$idx]}) [leave empty to keep current: ${current_row[$idx]}]"
        local val
        val=$(read_input "$prompt")
        if [[ -z "$val" ]]; then
            new_values+=("${current_row[$idx]}")
            continue
        fi
        if ! validate_value_by_type "$val" "${types[$idx]}"; then
            print_error "Invalid value for ${cols[$idx]}"
            return 1
        fi
        new_values+=("$val")
    done

    # build new line
    local new_line=""
    for idx in "${!new_values[@]}"; do
        if [[ $idx -gt 0 ]]; then new_line+="$SEPARATOR"; fi
        new_line+="${new_values[$idx]}"
    done

    # replace line in file (atomic)
    local tmp
    tmp=$(mktemp)
    awk -F"$SEPARATOR" -v OFS="$SEPARATOR" -v pkcol="$pk_col" -v val="$pk_val" -v newline="$new_line" ' $pkcol==val {print newline; next} {print}' "$data_file" > "$tmp"
    mv "$tmp" "$data_file"
    print_success "Row with PK=$pk_val updated in '$table'"
}
