create_db(){
    local db_name
    db_name=$(read_input "Enter DB name to be created ")

    if ! is_valid_name "$db_name"; then
        print_error "Invalid name: Only letters, numbers, underscores allowed"
        return 1
    fi

    if [[ -d "$DATA_DIR/$db_name" ]]; then
        print_error "Database $db_name already exist."
        return 1;
    fi

    mkdir "$DATA_DIR/$db_name"
    print_success "Database $db_name created successfully."
}