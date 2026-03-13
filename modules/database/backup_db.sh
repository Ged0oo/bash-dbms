#!/bin/bash

BACKUP_DIR="$DBMS_ROOT/backups"

backup_db(){
    list_db
    local db_name
    db_name=$(read_input "Enter database name to backup: ")

    if [[ -z "$db_name" ]]; then
        print_error "Database name cannot be empty."
        return 1
    fi

    if [[ ! -d "$DATA_DIR/$db_name" ]]; then
        print_error "Database '$db_name' does not exist."
        return 1
    fi

    mkdir -p "$BACKUP_DIR"

    local timestamp
    timestamp=$(date '+%Y%m%d_%H%M%S')
    local backup_file="$BACKUP_DIR/${db_name}_${timestamp}.tar.gz"

    tar -czf "$backup_file" -C "$DATA_DIR" "$db_name" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        local size
        size=$(du -h "$backup_file" | cut -f1)
        print_success "Backup created: $backup_file ($size)"
        log_success "Database '$db_name' backed up to $backup_file"
    else
        print_error "Backup failed."
        log_error "Backup failed for database '$db_name'"
        return 1
    fi
}

list_backups() {
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]]; then
        print_info "No backups found."
        return 0
    fi

    echo "═══════════════════════════════════════════════════════"
    echo "════════════════════* All Backups *════════════════════"
    echo "═══════════════════════════════════════════════════════"

    printf "  %-30s %-8s %s\n" "FILENAME" "SIZE" "DATE"
    echo "  ─────────────────────────────────────────────────────"

    for f in "$BACKUP_DIR"/*.tar.gz; do
        local fname=$(basename "$f")
        local fsize=$(du -h "$f" | cut -f1)
        local fdate=$(stat -c '%y' "$f" 2>/dev/null | cut -d'.' -f1)
        printf "  %-30s %-8s %s\n" "$fname" "$fsize" "$fdate"
    done
    
    echo "═══════════════════════════════════════════════════════"
}

restore_db(){
    if [[ ! -d "$BACKUP_DIR" ]] || [[ -z "$(ls "$BACKUP_DIR"/*.tar.gz 2>/dev/null)" ]]; then
        print_info "No backup found."
        return 0
    fi

    echo "═══════════════════════════════════"
    echo "   Available Backups"
    echo "═══════════════════════════════════"
    local backups=()
    local i=1
    for f in "$BACKUP_DIR"/*.tar.gz; do
        local fname=$(basename "$f")
        local fsize=$(du -h "$f" | cut -f1)
        local fdate=$(stat -c '%y' "$f" 2>/dev/null | cut -d'.' -f1)
        echo "  $i) $fname  [$fsize]  $fdate"
        backups+=("$f")
        ((i++))
    done
    echo "═══════════════════════════════════"

    local choice
    choice=$(read_input "Select Backup number to restore: ")

    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#backups[@]} )); then
        print_error "Invalid Selection."
        return 1
    fi

    local selected="${backups[$((choice-1))]}"
    local db_name
    db_name=$(basename "$selected" | sed 's/_[0-9]\{8\}_[0-9]\{6\}\.tar\.gz//')

    if [[ -d "$DATA_DIR/$db_name" ]]; then
        echo -e "${YELLOW}⚠ Database '$db_name' already exists.${NC}"
        if ! confirm "Overwrite it?"; then
            print_info "Restore cancelled."
            return 0
        fi
        rm -rf "$DATA_DIR/$db_name"
    fi

    tar -xzf "$selected" -C "$DATA_DIR" 2>/dev/null

    if [[ $? -eq 0 ]]; then
        print_success "Database '$db_name' restored successfully."
        log_success "Database '$db_name' restored from $(basename "$selected")"
    else
        print_error "Restore failed."
        log_error "Restore failed from $(basename "$selected")"
        return 1
    fi
}