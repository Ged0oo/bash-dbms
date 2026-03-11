#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"

# tbl_create <DB_PATH>
tbl_create() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    local table
    table=$(read_input "Enter table name")
    if ! is_valid_name "$table"; then
        print_error "Invalid table name. Use letters, numbers and underscores, not starting with a digit."
        return 1
    fi

    local meta_file="$DB_PATH/${table}${META_EXT}"
    local data_file="$DB_PATH/${table}${DATA_EXT}"
    if [[ -e "$meta_file" || -e "$data_file" ]]; then
        print_error "Table '$table' already exists"
        return 1
    fi

    read -rp "Number of columns: " ncols
    if ! [[ "$ncols" =~ ^[1-9][0-9]*$ ]]; then
        print_error "Number of columns must be a positive integer"
        return 1
    fi

    local -a cols types
    for ((i=1;i<=ncols;i++)); do
        # column name
        while true; do
            local colname
            colname=$(read_input "Column #$i name")
            if ! is_valid_name "$colname"; then
                print_error "Invalid column name"
                continue
            fi
            local dup=0
            for existing in "${cols[@]:-}"; do
                if [[ "$existing" == "$colname" ]]; then dup=1; break; fi
            done
            if [[ $dup -eq 1 ]]; then
                print_error "Duplicate column name"
                continue
            fi
            cols+=("$colname")
            break
        done

        # column type
        while true; do
            local coltype
            coltype=$(read_input "Column #$i type (int/str)")
            case "$coltype" in
                int|str)
                    types+=("$coltype")
                    break
                    ;;
                *) print_error "Type must be 'int' or 'str'" ;;
            esac
        done
    done

    echo "Columns:";
    for idx in "${!cols[@]}"; do
        echo "$((idx+1))) ${cols[$idx]} (${types[$idx]})"
    done

    local pk_idx
    while true; do
        read -rp "Primary key column number: " pk_idx
        if ! [[ "$pk_idx" =~ ^[1-9][0-9]*$ ]] || (( pk_idx < 1 || pk_idx > ncols )); then
            print_error "Invalid choice"
        else
            break
        fi
    done

    # write meta
    {
        for idx in "${!cols[@]}"; do
            local line="${cols[$idx]}:${types[$idx]}"
            if (( idx+1 == pk_idx )); then
                line+=":PK"
            fi
            printf '%s\n' "$line"
        done
    } > "$meta_file"

    # create empty data file
    : > "$data_file"

    print_success "Table '$table' created (meta=$(basename "$meta_file"), data=$(basename "$data_file"))"
}
