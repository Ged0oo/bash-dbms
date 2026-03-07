#!/bin/bash

DBMS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DBMS_ROOT

source "$DBMS_ROOT/config/config.sh"
source "$DBMS_ROOT/lib/utils.sh"

mkdir -p "$DATA_DIR"

source "$DBMS_ROOT/modules/database/db_menu.sh"
db_menu