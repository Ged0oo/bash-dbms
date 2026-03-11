#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"

is_int() {
    [[ "$1" =~ ^-?[0-9]+$ ]]
}

is_valid_string() {
    # non-empty and does not contain the separator
    [[ -n "$1" && "$1" != *"$SEPARATOR"* ]]
}

validate_value_by_type() {
    local val="$1" type="$2"
    case "$type" in
        int) is_int "$val" ;;
        str) is_valid_string "$val" ;;
        *) return 1 ;;
    esac
}

# pk_is_unique <data_file> <pk_col> <value>
# returns 0 when value is unique (not found), 1 when it exists
pk_is_unique() {
    local data_file="$1" pk_col="$2" value="$3"
    if [[ ! -f "$data_file" ]]; then
        return 0
    fi
    # Use cut + grep for reliability: return 1 if found, 0 if unique
    if cut -d"$SEPARATOR" -f"$pk_col" "$data_file" | grep -Fxq -- "$value"; then
        return 1
    else
        return 0
    fi
}
