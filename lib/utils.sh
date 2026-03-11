#!/usr/bin/env bash

print_error()    { printf '%b\n' "${RED}[ERROR] $1${NC}"; }
print_success()  { printf '%b\n' "${GREEN}[OK]  $1${NC}"; }
print_info()     { printf '%b\n' "${CYAN}[INFO] $1${NC}"; }

read_input() {
    local prompt="$1"
    local input
    read -rp "$prompt: " input
    echo "$input"
}

confirm() {
    local prompt="$1"
    local answer
    read -rp "$prompt [y/N]: " answer
    [[ "$answer" =~ ^[Yy]$ ]]
}

is_valid_name() {
    [[ "$1" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]
}
