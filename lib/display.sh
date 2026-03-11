#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"

display_table() {
    local meta_file="$1" data_file="$2"
    if [[ ! -f "$meta_file" ]]; then
        printf '%s\n' "[ERROR] missing meta file: $meta_file"
        return 1
    fi
    if [[ ! -f "$data_file" || ! -s "$data_file" ]]; then
        printf '%s\n' "(no rows)"
        return 0
    fi

    local header
    header=$(awk -F":" '{print $1}' "$meta_file" | paste -sd"$SEPARATOR" -)
    { printf '%s\n' "$header"; cat "$data_file"; } | column -s"$SEPARATOR" -t
}
