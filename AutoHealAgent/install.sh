touch /usr/sbin/rockyraccoon
chmod +x /usr/sbin/rockyraccoon

cat > /usr/sbin/rockyraccoon << 'EOF'
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

if [ -z "$1" ]; then
    echo "Please enter the location of the records file [q to exit] : "
    read file_name
    if [ "$file_name" == "q" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Exiting"
        exit 0
    fi
    if [ -f "$file_name" ]; then
        echo -e "[${GREEN}OKAY${RESET}] Records list found..."
    else
        echo -e "[${RED}WARNING${RESET}] Records list '$file_name' not in file system... Exiting."
        exit 1
    fi
else
    file_name="$1"
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

exit 0
EOF
