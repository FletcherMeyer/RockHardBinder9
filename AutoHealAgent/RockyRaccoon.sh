if [[ "$EUID" -ne 0 ]]
then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

domain_records=""
backup_dir=""
file_list=""

function validate(){
    source "$domain_records"
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
}

function load(){
    # Read the file list line by line
    while IFS= read -r file; do
        # Check if the file exists before copying
        if [ -f "$backup_dir$file" ] || [ -d "$backup_dir$file" ]; then
            cp -r "$file" "$backup_dir$file"

            if [ $? -ne 0 ]; then
                echo -e "[${RED}FAILURE${RESET}] Unable to copy: $backup_dir$file"
            else
                echo -e "[${GREEN}OKAY${RESET}] Backup loaded for: $backup_dir$file"
            fi

        else
            echo -e "[${RED}FAILURE${RESET}] File or Directory not found: $file"
        fi
    done < "$file_list"

    echo -e "[${GREEN}OKAY${RESET}] Backups loaded."

    systemctl start bind9
    systemctl daemon-reload

    if systemctl is-active --quiet bind9; then
        echo -e "[${GREEN}OKAY${RESET}] Bind9 Service Successfully started."
        exit 0
    else
        echo "-e [${RED}FAILURE${RESET}] Failed to start bind9 service."
        exit 1
    fi
}

function backup(){
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
}

function main(){
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

    if [ -z $3 ]; then
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
        bash "$curr/RockyLoad.sh" $backup_dir $file_list
        # Run it again or some shit
        bash "$curr/RockyValidate.sh $domain_records"
        if [ $? == '0' ]; then
            echo "[${$GREEN}SUCCESS${$RESET}] $(date) Rocky Raccoon restored DNS."
            exit 1
        else
        echo "[${$RED}FAILURE${$RESET}] $(date) Rocky Raccoon was unable to restore DNS." 
        fi
        exit 1
    fi
}

function service(){
    touch "/tmp/rocky.log"
    curr=$(dirname "$0")

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
    ExecStart=${"$curr/RockyRaccoon.sh"}
    User=root  # Change if needed
    StandardOutput=/tmp/rocky.log
    StandardError=journal

    [Install]
    WantedBy=multi-user.target
EOF


    systemctl start RockyRaccoon.service
    systemctl enable RockyRaccoon.service

    systemctl start RockyRaccoon.timer
    systemctl enable RockyRaccoon.timer
}

service();
main();
