#!/bin/bash

export DBMS_ROOT="$(dirname "$(realpath "\$0")")"
export DATA_DIR="$DBMS_ROOT/data"

export SEPARATOR=":"
export META_EXT=".meta"
export DATA_EXT=".data"
export PS3_PROMP=">>> "
export RED='\033[0;31m'
export GREEN='\033[0;32m'
export YELLOW='\033[1;33m'
export CYAN='\033[0;36m'
export NC='\033[0m'