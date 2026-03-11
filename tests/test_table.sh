#!/usr/bin/env bash
set -Eeuo pipefail

DBMS_ROOT="${DBMS_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export DBMS_ROOT

[[ -f "$DBMS_ROOT/config/config.sh" ]] && source "$DBMS_ROOT/config/config.sh"
[[ -f "$DBMS_ROOT/lib/utils.sh" ]] && source "$DBMS_ROOT/lib/utils.sh"
[[ -f "$DBMS_ROOT/lib/validation.sh" ]] && source "$DBMS_ROOT/lib/validation.sh"
[[ -f "$DBMS_ROOT/lib/display.sh" ]] && source "$DBMS_ROOT/lib/display.sh"

tmpdb=$(mktemp -d)
trap 'rm -rf "$tmpdb"' EXIT

mkdir -p "$tmpdb"
meta="$tmpdb/employees${META_EXT}"
data="$tmpdb/employees${DATA_EXT}"

cat > "$meta" <<EOF
id:int:PK
name:str
age:int
EOF

cat > "$data" <<EOF
1:John:30
2:Jane:25
EOF

echo "Running basic table tests against $tmpdb"

# test pk_is_unique (1 exists -> should return 1)
if pk_is_unique "$data" 1 1; then
    echo "FAIL: pk_is_unique reported unique for existing PK"
    exit 1
else
    echo "OK: pk_is_unique detected existing PK"
fi

# test pk_is_unique for non-existing value
if pk_is_unique "$data" 1 99; then
    echo "OK: pk_is_unique reports unique for missing PK"
else
    echo "FAIL: pk_is_unique reported exists for missing PK"
    exit 1
fi

echo "Display output:"
display_table "$meta" "$data"

echo "All tests passed"
