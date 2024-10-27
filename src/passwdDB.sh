#!/bin/bash

source src/functions.sh

PASSWORD_FILE=$1


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
