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

file_name=${1:/records.txt}
if [ -f "$file_name" ]; then
    echo -e "[${GREEN}OKAY${RESET}] Records file found..."
else
    echo -e "[${RED}FAILURE${RESET}] Records file not found. Exiting."
    # If it is a '2', we know it is something pertaining to the Auto Healing Agent that is broken.
    exit 2
fi

source file_name

echo -e "Checking domain resolving..."

for i in $(seq 0 $((${#DOMAIN_ARR[@]} - 1)));
do
		echo "${DOMAIN_ARR[i]} should resolve to ${RESOLVE_ARR[i]}..."
	IPADDR=$(nslookup ${DOMAIN_ARR[i]} localhost | grep 'Address:' | awk '{print $2}' | sed -n '2p')
	if [ "${RESOLVE_ARR[i]}" == "${IPADDR}" ]; then
    echo -e "[${GREEN}OKAY${RESET}] ${DOMAIN_ARR[i]} resolved!"
    # It will check for a '0' to determine success.
		exit 0;
	else
    echo -e "[${GREEN}RED${RESET}] ${DOMAIN_ARR[i]} did not resolve..."
    # It will check for a '0' to determine success.
		exit 1;
	fi
	echo "	${IPADDR}"
done
