#!/bin/bash

prompt_for_directory() {
    echo "Please enter the location of the backup directory [q to exit] : "
    read backup_dir

    if [ "$backup_dir" == "exit" ]; then
        echo "Exiting..."
        exit 0
    fi

    if [ -d "$backup_dir" ]; then
        echo "Backup directory exists. Copying content."
    else
        echo "Directory does not exist... Creating directory."
        mkdir -p "$backup_dir"
    fi
    return 0;
}

echo "Please enter the directory to be backed up [q to exit] : " 
read to_backup
if [ "$to_backup" == "exit" ]; then
    echo "Exiting..."
    exit 0
fi

while true; do
    prompt_for_directory
    if [ $? -eq 0 ]; then
        # If directory is valid, perform the backup
        cp -r "$to_backup" "$backup_dir"

        if [ $? -eq 0 ]; then
            echo "Backup successfully made."
        else
            echo "An error may have occured in this process..."
        fi
        
        break
    fi
done
