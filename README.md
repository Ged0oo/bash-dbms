# Bash DBMS

A lightweight Database Management System built with Bash.
It stores data directly on disk using folders and text files, with a menu-driven CLI.

---

## Overview

`Bash DBMS` lets you:
- Create, list, connect, and drop databases
- Create, list, and drop tables
- Insert, select, update, and delete rows
- Backup and restore databases
- Log operations to a local log file

Everything is file-based, simple to inspect, and easy to run on Linux.

---

## Features

### Database Operations
- Create database
- List databases
- Connect to database
- Drop database
- Backup database
- Restore database

### Table Operations
- Create table with schema
- List tables
- Drop table
- Insert row
- Select all rows
- Update row by primary key
- Delete row by primary key

### Utilities
- Input validation
- Colored terminal messages
- Operation logging

---

## Project Structure

```text
bash-dbms/
├── main.sh
├── config/
│   └── config.sh
├── lib/
│   ├── utils.sh
│   ├── validation.sh
│   ├── display.sh
│   └── logger.sh
├── modules/
│   ├── database/
│   │   ├── db_menu.sh
│   │   ├── create_db.sh
│   │   ├── list_db.sh
│   │   ├── connect_db.sh
│   │   ├── drop_db.sh
│   │   └── backup_db.sh
│   └── table/
│       ├── table_menu.sh
│       ├── create_table.sh
│       ├── list_tables.sh
│       ├── drop_table.sh
│       ├── insert.sh
│       ├── select.sh
│       ├── delete.sh
│       └── update.sh
├── data/
├── backups/
└── tests/
```

---

## Requirements

- Bash 4+
- GNU core utilities
- `awk`
- `tar`

---

## Quick Start

```bash
git clone <your-repo-url>
cd bash-dbms
chmod +x main.sh
./main.sh
```

---

## Usage

Run the app:

```bash
./main.sh
```

### Main Menu
- Create Database
- List Databases
- Connect To Database
- Drop Database
- List Backup Databases
- Restore Database
- Backup Database
- View Logs
- Exit

### Table Menu
- Create table
- List tables
- Drop table
- Insert row
- Select all
- Delete (by PK)
- Update (by PK)
- Back

---

## Storage Format

### Databases
Each database is a directory under `data/`.

### Table Schema (`.meta`)
Each line is:

```text
column_name:data_type[:PK]
```

Example:

```text
id:int:PK
name:str
age:int
```

### Table Data (`.data`)
Each line is one row, values separated by `:`.

Example:

```text
1:Alice:30
2:Bob:25
```

---

## Validation Rules

- Names must start with a letter or `_`
- Allowed characters: letters, numbers, `_`
- Supported data types: `int`, `str`
- Primary key must be unique on insert

---

## Logging

Logs are written to:

```text
data/.dbms.log
```

Typical log entry format:

```text
[timestamp] [LEVEL] [function] message
```

---

## Backup and Restore

Backups are stored in:

```text
backups/
```

File format:

```text
<db_name>_YYYYMMDD_HHMMSS.tar.gz
```

---

## Configuration

Main configuration file:

- `config/config.sh`

Important variables:
- `DBMS_ROOT`
- `DATA_DIR`
- `SEPARATOR`
- `META_EXT`
- `DATA_EXT`

---

## Troubleshooting

- **Permission denied**: run `chmod +x main.sh`
- **No colors in output**: use a terminal with ANSI support
- **Backup failure**: ensure `tar` is installed and `backups/` is writable
- **No databases shown**: verify `data/` contains DB directories

---

## Authors

- Nagy
- Ebrahim