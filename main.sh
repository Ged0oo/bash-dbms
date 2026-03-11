#!/bin/bash

DBMS_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export DBMS_ROOT

source "$DBMS_ROOT/config/config.sh"

source "$DBMS_ROOT/lib/utils.sh"
source "$DBMS_ROOT/lib/display.sh"
source "$DBMS_ROOT/lib/validation.sh"

mkdir -p "$DATA_DIR"

source "$DBMS_ROOT/modules/database/create_db.sh"
source "$DBMS_ROOT/modules/database/drop_db.sh"
source "$DBMS_ROOT/modules/database/list_db.sh"
source "$DBMS_ROOT/modules/database/connect_db.sh"
source "$DBMS_ROOT/modules/database/db_menu.sh"

source "$DBMS_ROOT/modules/table/table_menu.sh"
source "$DBMS_ROOT/modules/table/drop_table.sh"
source "$DBMS_ROOT/modules/table/list_tables.sh"
source "$DBMS_ROOT/modules/table/create_table.sh"
source "$DBMS_ROOT/modules/table/select.sh"
source "$DBMS_ROOT/modules/table/insert.sh"
source "$DBMS_ROOT/modules/table/update.sh"
source "$DBMS_ROOT/modules/table/delete.sh"

db_menu