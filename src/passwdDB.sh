#!/bin/bash

PASSWORD_FILE=$1

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

password=""
data=""

if [[ -e "$PASSWORD_FILE" ]]; then
    echo "Password database exists."
    read -sp "Enter master password: " password
    echo
    data=$(decrypt_and_retrieve "$password")
    
    if [[ $? -ne 0 ]]; then
        echo "Failed to decrypt. Incorrect password or corrupted file."
        exit 1
    fi
else
    echo "Creating new password database."
    read -sp "Set a master password: " password
    echo
    read -sp "Confirm master password: " confirm_password
    echo
    
    if [[ "$password" != "$confirm_password" ]]; then
        echo "Passwords do not match."
        exit 1
    fi
    
    data=""
    encrypt_and_save "$data" "$password"
fi

while true; do
    echo
    echo "Password Manager Menu:"
    echo "1. Display all entries"
    echo "2. Add a new entry"
    echo "3. Remove an entry"
    echo "4. Generate a random password"
    echo "5. Change master password"
    echo "6. Exit"
    echo
    
    read -p "Choose an option: " choice
    
    case $choice in
        1)
            display_entries "$data"
            ;;
        2)
            new_data=$(add_entry "$data")
            if [[ "$new_data" != "$data" ]]; then
                data="$new_data"
                encrypt_and_save "$data" "$password"
                echo "Entry added successfully."
            fi
            ;;
        3)
            read -p "Enter the ID of the entry to remove: " id
            data=$(remove_entry "$data" "$id")
            encrypt_and_save "$data" "$password"
            echo "Entry removed successfully."
            ;;
        4)
            read -p "Enter desired password length (default 12): " length
            generated_password=$(generate_password "${length:-12}")
            echo "Generated password: $generated_password"
            echo "This password has not been saved."
            continue 
            ;;
        5)
            if change_master_password "$password"; then
                password="$new_password"
            fi
            ;;
        6)
            echo "Exiting..."
            exit 0
            ;;
        *)
            echo "Invalid option. Please try again."
            ;;
    esac
done
