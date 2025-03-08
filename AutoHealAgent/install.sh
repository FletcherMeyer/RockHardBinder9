# !/bin/bash

# For logs
touch "/tmp/rocky.log"

# For the main service
touch "/usr/sbin/rockyraccoon"
chmod +x "/usr/sbin/rockyraccoon"

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

curr=$(dirname "$0")


# touch "$curr/rocky.log"

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
        exit 1
    fi
    if [ -f "$file_list" ]; then
        echo -e "[${GREEN}OKAY${RESET}] File list found..."
    else
        echo -e "[${RED}FAILURE${RESET}] File list not found. Exiting."
        exit 1
    fi
else
    file_list="$2"
fi
# Create the backup directory if it does not exist
mkdir -p "$backup_dir"

if [ -z $2 ]; then
    echo "Please enter the location of the domain records [q to exit] : "
    read domain_records
    if [ "$domain_records" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 1
    fi
    if [ -f "$domain_records" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Domain records found..."
    else
        echo -e "[${RED}FAILURE${RESET}] Domain records not found. Exiting."
        exit 1
    fi
else
    domain_records="$3"
fi

bash "$curr/RockyValidate.sh $domain_records"

if [ $? == '0' ]; then
    echo "[${$GREEN}SUCCESS${$RESET}] $(date) Rocky Raccoon validated DNS."
    exit 0
else
    echo "[${$RED}FAILURE${$RESET}] $(date) Rocky Raccoon was unable to validate DNS." 
    load $backup_dir $file_list
    # Run it again or some shit
    validatename $domain_records
    if [ $? == '0' ]; then
        echo "[${$GREEN}SUCCESS${$RESET}] $(date) Rocky Raccoon restored DNS."
        exit 1
    else
    echo "[${$RED}FAILURE${$RESET}] $(date) Rocky Raccoon was unable to restore DNS." 
    fi
    exit 1
fi
EOF

touch /usr/sbin/validatename
chmod +x /usr/sbin/validatename
cat <<-EOF > /usr/sbin/validatename
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

file_name=${1:-"./records.txt"}
if [ -f "$file_name" ]; then
    echo -e "[${GREEN}OKAY${RESET}] Records file found..."
else
    echo -e "[${RED}FAILURE${RESET}] Records file not found. Exiting."
    # If it is a '2', we know it is something pertaining to the Auto Healing Agent that is broken.
    exit 1
fi
source "$file_name"

echo -e "Checking domain resolving..."

for i in $(seq 0 $((${#DOMAIN_ARR[@]} - 1)));
do
	timeout 5s nslookup  "${DOMAIN_ARR[i]} localhost"
    if [ $? -eq 124 ]; then
    echo -e "[${GREEN}RED${RESET}] ${DOMAIN_ARR[i]} did not resolve... (Command timed out)"        
        exit 1
    fi
    echo "${DOMAIN_ARR[i]} should resolve to ${RESOLVE_ARR[i]}..."
	IPADDR=$(nslookup ${DOMAIN_ARR[i]} localhost | grep 'Address:' | awk '{print $2}' | sed -n '2p')
	if [ "${RESOLVE_ARR[i]}" == "${IPADDR}" ]; then
    echo -e "[${GREEN}OKAY${RESET}] ${DOMAIN_ARR[i]} resolved!"
    # It will check for a '0' to determine success.
	else
    echo -e "[${GREEN}RED${RESET}] ${DOMAIN_ARR[i]} did not resolve..."
        # It will check for a '0' to determine success.
		exit 1;
	fi
	echo "	${IPADDR}"
done

exit 0;
EOF

touch /usr/sbin/backup
chmod +x /usr/sbin/backup
cat <<-EOF > /usr/sbin/backup
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

systemctl stop bind9

if [ -z "$1" ]; then
    echo "Please enter the location of the backup directory [q to exit] : "
    read backup_dir
    if [ "$backup_dir" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 0
    fi
    if [ -d "$backup_dir" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Backup found..."
    else
        echo -e "[${RED}WARNING${RESET}] Backup directory '$backup_dir' not in file system... Exiting."
        exit 1
    fi
else
    backup_dir="$1"
fi

# Define the file that contains the list of files to back up
if [ -z "$2" ]; then
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
        exit 1
    fi
else
    file_list="$2"
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
            echo -e "[${GREEN}OKAY${RESET}] Backup loaded for: $backup_dir$file"
        fis
    else
        echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
    fi
done < "$file_list"

echo -e "[${GREEN}OKAY${RESET}] Backups loaded."

systemctl start bind9
systemctl daemon-reload

if systemctl is-active --quiet bind9; then
    echo -e "[${GREEN}OKAY${RESET}] Bind9 Service Successfully started. Exiting with 1."
    exit 0
else
    echo "-e [${RED}FAILURE${RESET}] Failed to start Bind9 service. Exiting with 0."
    exit 1
fi

exit 2
EOF

touch /usr/sbin/load
chmod +x /usr/sbin/load
cat <<-EOF > /usr/sbin/load
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

systemctl stop bind9

if [ -z "$1" ]; then
    echo "Please enter the location of the backup directory [q to exit] : "
    read backup_dir
    if [ "$backup_dir" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 0
    fi
    if [ -d "$backup_dir" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Backup found..."
    else
        echo -e "[${RED}WARNING${RESET}] Backup directory '$backup_dir' not in file system... Exiting."
        exit 1
    fi
else
    backup_dir="$1"
fi

# Define the file that contains the list of files to back up
if [ -z "$2" ]; then
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
        exit 1
    fi
else
    file_list="$2"
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
            echo -e "[${GREEN}OKAY${RESET}] Backup loaded for: $backup_dir$file"
        fis
    else
        echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
    fi
done < "$file_list"

echo -e "[${GREEN}OKAY${RESET}] Backups loaded."

systemctl start bind9
systemctl daemon-reload

if systemctl is-active --quiet bind9; then
    echo -e "[${GREEN}OKAY${RESET}] Bind9 Service Successfully started. Exiting with 1."
    exit 0
else
    echo "-e [${RED}FAILURE${RESET}] Failed to start Bind9 service. Exiting with 0."
    exit 1
fi

exit 2
EOF

cat <<-EOF > /etc/systemd/system/RockyRaccoon.timer
[Unit]
Description=https://en.wikipedia.org/wiki/Rocky_Raccoon

[Timer]
OnBootSec=1sec
OnUnitActiveSec=5min

[Install]
WantedBy=timers.target
EOF

cat <<-EOF > /etc/systemd/system/RockyRaccoon.service
[Unit]
Description=https://en.wikipedia.org/wiki/Rocky_Raccoon
[Service]
ExecStart=/usr/sbin/RockyRaccoon
User=root  # Change if needed
StandardOutput=/tmp/rocky.log
StandardError=/tmp/rocky.log
[Install]
WantedBy=multi-user.target
EOF


systemctl start RockyRaccoon.service
systemctl enable RockyRaccoon.service

systemctl start RockyRaccoon.timer
systemctl enable RockyRaccoon.timer
