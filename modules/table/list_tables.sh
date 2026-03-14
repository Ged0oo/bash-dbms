#!/bin/bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"

tbl_list() {
    local DB_PATH="$1"
    if [[ -z "${DB_PATH:-}" || ! -d "$DB_PATH" ]]; then
        print_error "Invalid DB path: $DB_PATH"
        return 1
    fi

    shopt -s nullglob
    local files=("$DB_PATH"/*"$META_EXT")
    if [[ ${#files[@]} -eq 0 ]]; then
        print_info "No tables found in $(basename "$DB_PATH")"
        return 0
    fi

    echo "Tables in $(basename "$DB_PATH")":
    for f in "${files[@]}"; do
        local name
        name=$(basename "$f" "$META_EXT")
        echo "- $name"
    done
}
