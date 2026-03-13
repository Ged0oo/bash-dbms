drop_db(){
    list_db
    local db_name
    db_name=$(read_input "Enter DB name to drop ")
    db_name="${db_name//$'\r'/}"   # strip carriage returns captured by read

    if ! is_valid_name "$db_name"; then
        print_error "Invalid name: Only letters, numbers, underscores allowed"
        return 1
    fi

    if [[ ! -d "$DATA_DIR/$db_name" ]]; then
        print_error "Database $db_name does not exist."
        return 1
    fi

    echo -e "${YELLOW} WARNING: This will delete ALL tables and data in '$db_name'.${NC}"
    if ! confirm "Are you sure you want to continue?"; then
        print_info "Operation cancelled."
        return 0
    fi

    rm -r "$DATA_DIR/$db_name"
    print_success "Database '$db_name' dropped successfully."
    log_warn "Database '$db_name' dropped by user"
}