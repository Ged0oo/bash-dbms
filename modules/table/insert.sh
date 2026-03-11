#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/validation.sh" ]] && source "$DBMS_ROOT/lib/validation.sh"

tbl_insert() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name to insert into")
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

    local -a values
    for idx in "${!cols[@]}"; do
        local col_index=$((idx+1))
        local val
        while true; do
            val=$(read_input "Value for ${cols[$idx]} (${types[$idx]})")
            if ! validate_value_by_type "$val" "${types[$idx]}"; then
                print_error "Value does not match type ${types[$idx]} or contains illegal characters"
                continue
            fi
            # check separator
            if [[ "$val" == *"$SEPARATOR"* ]]; then
                print_error "Value cannot contain the separator '$SEPARATOR'"
                continue
            fi
            break
        done
        values+=("$val")
    done

    # check PK uniqueness
    if (( pk_col > 0 )); then
        local pk_val="${values[$((pk_col-1))]}"
        if ! pk_is_unique "$data_file" "$pk_col" "$pk_val"; then
            print_error "Primary key value '$pk_val' already exists"
            return 1
        fi
    fi

    # join values with separator
    local line=""
    for idx in "${!values[@]}"; do
        if [[ $idx -gt 0 ]]; then line+="$SEPARATOR"; fi
        line+="${values[$idx]}"
    done

    # append under lock
    exec 200>"$data_file.lock"
    flock -x 200
    echo "$line" >> "$data_file"
    flock -u 200
    exec 200>&-

    print_success "Row inserted into '$table'"
}
