db_menu(){
    clear

    echo "═══════════════════════════════════"
    echo "=====* Bash DBMS — Main Menu *====="
    echo "═══════════════════════════════════"

    PS3=${PS3_PROMP}
    while true; do
        select option in "Create Database" "List Databases" "Connect To Database" "Drop Database" "List Backup Databases" "Restore Database" "Backup Database" "View Logs" "Exit"; do
            case $REPLY in
                1) echo "Create Database..."; create_db; break ;;
                2) echo "List Databases..."; list_db; break ;;
                3) echo "Connect To Database..."; connect_db; break ;;
                4) echo "Drop Database..."; drop_db; break ;;
                5) echo "List Backup Databases..."; list_backups; break ;;
                6) echo "Restore Database..."; restore_db; break ;;
                7) echo "Backup Database..."; backup_db; break ;;
                8) echo "View Logs..."; show_logs; break ;;
                9) echo "Goodbye"; exit 0 ;;
                *) echo "Invalid choice" ;;
            esac
        done
    done
}