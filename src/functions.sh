#!/bin/bash

encrypt_and_save() {
    local data="$1"
    local password="$2"
    echo "$data" | openssl enc -aes-256-cbc -salt -pbkdf2 -out "$PASSWORD_FILE" -pass pass:"$password"
}

decrypt_and_retrieve() {
    local password="$1"
    openssl enc -aes-256-cbc -d -salt -pbkdf2 -in "$PASSWORD_FILE" -pass pass:"$password"
}

generate_password() {
    local length=${1:-12}
    tr -dc 'A-Za-z0-9!@#$%^&*()_+' < /dev/urandom | head -c "$length"
}

display_entries() {
    local data="$1"
    echo "ID | URL | Login | Password"
    echo "--------------------------------"
    echo "$data" | awk -F',' '{print NR "," $0}' | column -t -s ',' | sed 's/,/ | /g'
}

add_entry() {
    local data="$1"
    read -p "Enter URL: " url
    read -p "Enter login: " login
    read -p "Enter password (leave blank to generate): " password
    
    if [[ -z "$password" ]]; then
        password=$(generate_password)
    fi
    
    new_entry="$url,$login,$password"
    if [[ -n "$data" ]]; then
        echo "${data}"$'\n'"${new_entry}"
    else
        echo "$new_entry"
    fi
}

remove_entry() {
    local data="$1"
    local id="$2"
    echo "$data" | awk -v id="$id" 'NR != id {print}'
}

change_master_password() {
    local old_password="$1"
    local data
    data=$(decrypt_and_retrieve "$old_password")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt with the current password."
        return 1
    fi
    
    read -sp "Enter new master password: " new_password
    echo
    read -sp "Confirm new master password: " confirm_password
    echo
    
    if [[ "$new_password" != "$confirm_password" ]]; then
        echo "Passwords do not match."
        return 1
    fi
    
    encrypt_and_save "$data" "$new_password"
    echo "Master password changed successfully."
}

