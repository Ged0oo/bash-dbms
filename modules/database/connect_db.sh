connect_db(){
    list_db

    echo "═══════════════════════════════════"
    echo "======* Connect to Database *======"
    echo "═══════════════════════════════════"

    local db_name
    db_name=$(read_input "Enter DB name to connect ")

    if ! is_valid_name "$db_name"; then
        print_error "Invalid name: Only letters, numbers, underscores allowed"
        return 1
    fi

    if [[ ! -d "$DATA_DIR/$db_name" ]]; then
        print_error "Database $db_name does not exist."
        return 1
    fi

    local db_path="$DATA_DIR/$db_name"
    print_success "Connected to database $db_name."

    table_menu "$db_path"
}