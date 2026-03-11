#!/usr/bin/env bash
set -Eeuo pipefail

# Determine repository root if not already set
: "${DBMS_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/validation.sh" ]] && source "$DBMS_ROOT/lib/validation.sh"
[[ -f "$DBMS_ROOT/lib/display.sh" ]] && source "$DBMS_ROOT/lib/display.sh"

table_menu() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    while true; do
        echo
        echo "Table Menu — DB: $(basename "$DB_PATH")"
        echo "1) Create table"
        echo "2) List tables"
        echo "3) Drop table"
        echo "4) Insert row"
        echo "5) Select all"
        echo "6) Delete (by PK)"
        echo "7) Update (by PK)"
        echo "0) Back"
        read -rp "Choice: " ch
        case "$ch" in
            1)
                source "$DBMS_ROOT/modules/table/create_table.sh"
                tbl_create "$DB_PATH"
                ;;
            2)
                source "$DBMS_ROOT/modules/table/list_tables.sh"
                tbl_list "$DB_PATH"
                ;;
            3)
                source "$DBMS_ROOT/modules/table/drop_table.sh"
                tbl_drop "$DB_PATH"
                ;;
            4)
                source "$DBMS_ROOT/modules/table/insert.sh"
                tbl_insert "$DB_PATH"
                ;;
            5)
                source "$DBMS_ROOT/modules/table/select.sh"
                tbl_select "$DB_PATH"
                ;;
            6)
                source "$DBMS_ROOT/modules/table/delete.sh"
                tbl_delete "$DB_PATH"
                ;;
            7)
                source "$DBMS_ROOT/modules/table/update.sh"
                tbl_update "$DB_PATH"
                ;;
            0)
                break
                ;;
            *)
                print_error "Invalid choice"
                ;;
        esac
    done
}
