#!/bin/bash

touch "/usr/sbin/backup"
chmod +x "/usr/sbin/backup"

cat <<-EOF > /usr/sbin/rockyraccoon
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

if [ -z $1 ]; then
    echo "Please enter the location of the backup directory [q to exit] : "
    read backup_dir
    if [ "$backup_dir" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 1
    fi
    if [ -d "$backup_dir" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Backup found..."
    else
        echo -e "[${YELLOW}WARNING${RESET}] Backup directory '$backup_dir' not in file system. Creating..."
        mkdir -p "$backup_dir"
    fi
else
    backup_dir="$1"
fi

# Define the file that contains the list of files to back up
if [ -z $2 ]; then
    echo "Please enter the location of the file list [q to exit] : "
    read file_list
    if [ "$file_list" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 0
    fi
    if [ -f "$file_list" ]; then
        echo -e "[${GREEN}OKAY${RESET}] File list found..."
    else
        echo -e "[${RED}FAILURE${RESET}] File list not found. Exiting with 2."
        exit 2
    fi
else
    file_list="$2"
fi

# Read the file list line by line
while IFS= read -r file; do
    # Check if the file exists before copying
    if [ -f "$file" ] || [ -d "$file" ]; then
        file_dir="$(dirname $file)"
        mkdir -p "$backup_dir$file_dir"
        cp -r "$file" "$backup_dir$file"
        if [ $? -ne 0 ]; then
            echo -e "[${RED}FAILURE${RESET}] Unable to backup: $file"
        else
            echo -e "[${GREEN}OKAY${RESET}] Backup made for: $file"
        fi

    else
        echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
    fi
done < "$file_list"

echo -e "[${GREEN}OKAY${RESET}] Backup completed."
exit 0

EOF
