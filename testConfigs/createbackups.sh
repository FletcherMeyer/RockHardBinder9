#!/bin/bash
echo "Please enter the location of the backup directory [q to exit] : "
read backup_dir
if [ "$backup_dir" == "q" ]; then
    echo "Exiting..."
    exit 0
fi
if [ -d "$backup_dir" ]; then
else
    echo "Backup not found..."
    exit 0
fi

# Define the file that contains the list of files to back up
file_list="./files.txt"

# Create the backup directory if it does not exist
mkdir -p "$backup_dir"

# Read the file list line by line
while IFS= read -r file; do
    # Check if the file exists before copying
    if [ -f "$file" ]; then
        cp "$file" "$backup_dir"
        echo "Copied: $file"
    else
        echo "File not found: $file"
    fi
done < "$file_list"

echo "Backup completed."
