#!/usr/bin/env bash
# Safe config: only set DBMS_ROOT if not already set; determine path relative to this file.
: "${DBMS_ROOT:=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
export DBMS_ROOT
export DATA_DIR="${DBMS_ROOT}/data"

SEPARATOR=":"
META_EXT=".meta"
DATA_EXT=".data"

# Terminal colors (exported)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
CYAN=$'\033[0;36m'
NC=$'\033[0m'

export SEPARATOR META_EXT DATA_EXT RED GREEN YELLOW CYAN NC
