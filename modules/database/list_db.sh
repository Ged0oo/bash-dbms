list_db(){
    local dbs=()
    for dir in "$DATA_DIR"/*/; do
        [[ -d "$dir" ]] && dbs+=("$(basename "$dir")")
    done
    
    if [[ ${#dbs[@]} -eq 0 ]]; then
        print_info "No Databases found."
        return 0;
    fi

    echo "═══════════════════════════════════"
    echo "======* Available Databases *======"
    echo "═══════════════════════════════════"

    local i=1
    for db in "${dbs[@]}"; do
        echo "  $i) $db"
        ((i++))
    done
    
    echo "═══════════════════════════════════"
    echo "Total: ${#dbs[@]} database(s)"
}