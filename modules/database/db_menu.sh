db_menu(){
    clear

    echo "═══════════════════════════════════"
    echo "=====* Bash DBMS — Main Menu *====="
    echo "═══════════════════════════════════"

    PS3=${PS3_PROMP}
    while true; do
        select option in "Create Database" "List Databases" "Connect To Database" "Drop Database" "Exit"; do
            case $REPLY in
                1) echo "Create Database..."; create_db; break ;;
                2) echo "List Databases..."; list_db; break ;;
                3) echo "Connect To Database..."; connect_db; break ;;
                4) echo "Drop Database..."; drop_db; break ;;
                5) echo "Goodbye"; exit 0 ;;
                *) echo "Invalid choice" ;;
            esac
        done
    done
}