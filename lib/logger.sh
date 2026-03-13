#!/bin/bash

LOG_FILE="$DATA_DIR/.dbms.log"

init_log(){
    mkdir -p "$DATA_DIR"
    touch "$LOG_FILE"
}

log_info()    { log "INFO"    "$@"; }
log_warn()    { log "WARN"    "$@"; }
log_error()   { log "ERROR"   "$@"; }
log_success() { log "SUCCESS" "$@"; }

log(){
    init_log
    local level="$1"
    shift
    local message="$*"
    local timestamp
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local caller="${FUNCNAME[1]:-main}"
    echo "[$timestamp] [$level] [$caller] $message" >> "$LOG_FILE"
}

show_logs(){
    if [[ ! -f "$LOG_FILE" ]]; then
        print_info "No logs found."
        return 0;
    fi

    local lines="${1:-20}"

    echo "═══════════════════════════════════════════════════════"
    echo "══════════════* Last $lines Log Entries *══════════════"
    echo "═══════════════════════════════════════════════════════"
    tail -n "$lines" "$LOG_FILE"
    echo "═══════════════════════════════════════════════════════"
}

rotate_logs(){
    local keep="${1:-500}"
    if [[ -f "$LOG_FILE" ]]; then
        local tmp
        tmp=$(tail -n "$keep" "$LOG_FILE")
        echo "$tmp" > "$LOG_FILE"
        log_info "Log rotated — kept last $keep entries"
    fi
}