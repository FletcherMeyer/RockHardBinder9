#!/bin/bash
if [[ "$EUID" -ne 0 ]]
then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

echo "Please enter the location of the backup directory [q to exit] : "
read backup_dir
if [ "$backup_dir" == "q" ]; then
    echo -e "[${GREEN}OKAY${RESET}] Exiting"
    exit 0
fi
if [ -d "$backup_dir" ]; then
    echo -e "[${GREEN}OKAY${RESET}] Backup found..."
else
    echo -e "[${RED}FAILURE${RESET}] Backup directory '$backup_dir' not in file system... Unable to fetch files."
    exit 1
fi

# Define the file that contains the list of files to back up
echo "Please enter the location of the file list [q to exit] : "
read file_list
if [ "$file_list" == "q" ]; then
    echo -e "[${GREEN}OKAY${RESET}] Exiting"
    exit 0
fi
if [ -f "$file_list" ]; then
    echo -e "[${GREEN}OKAY${RESET}] File list found..."
else
    echo -e "[${RED}FAILURE${RESET}] File list not found. Exiting."
    exit 0
fi

# Create the backup directory if it does not exist
mkdir -p "$backup_dir"

# Read the file list line by line
while IFS= read -r file; do
    # Check if the file exists before copying
    if [ -f "$backup_dir$file" ] || [ -d "$backup_dir$file" ]; then
        cp -r "$backup_dir$file" "$file"

        if [ $? -ne 0 ]; then
            echo -e "[${RED}FAILURE${RESET}] Unable to copy: $backup_dir$file"
        else
            echo -e "[${GREEN}OKAY${RESET}] Backup restored for: $backup_dir$file"
        fi

    else
        echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
    fi
done < "$file_list"

echo -e "[${GREEN}OKAY${RESET}] Backups restored."
