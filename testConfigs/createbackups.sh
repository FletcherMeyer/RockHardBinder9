#!/bin/bash
if [[ \$EUID -ne 0 ]]
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
    echo -e "[${YELLOW}WARNING${RESET}] Backup directory not in file system- creating..."
    mkdir -p "$backup_dir"
fi

# Define the file that contains the list of files to back up
file_list="./files.txt"

# Create the backup directory if it does not exist
mkdir -p "$backup_dir"

# Read the file list line by line
while IFS= read -r file; do
    # Check if the file exists before copying
    if [ -f "$file" ] || [ -d "$file" ]; then
        file_dir="$(dirname $file)"
        mkdir -p "$backup_dir$file_dir"
        cp -r "$file" "$backup_dir/$file"
        echo -e "[${GREEN}OKAY${RESET}] Backup made for: $file"
    else
        echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
    fi
done < "$file_list"

echo -e "[${GREEN}OKAY${RESET}] Backup completed."
