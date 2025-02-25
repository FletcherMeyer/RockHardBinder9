#!/bin/bash

source records.txt

# Recovery files will be in /etc/fudruckers


	echo -e "\033[33mChecking domain resolving...\033[0m"
	for i in $(seq 0 $((${#DOMAIN_ARR[@]} - 1)));
	do
    		echo "${DOMAIN_ARR[i]} should resolve to ${RESOLVE_ARR[i]}..."
		IPADDR=$(nslookup ${DOMAIN_ARR[i]} localhost | grep 'Address:' | awk '{print $2}' | sed -n '2p')
		if [ "${RESOLVE_ARR[i]}" == "${IPADDR}" ]; then
			echo -e "	\033[32m${DOMAIN_ARR[i]} resolved!\033[0m"
		else
			echo -e "	\033[31m${DOMAIN_ARR[i]} did not resolve... Fixing!\033[0m"
		fi
		echo "	${IPADDR}"
	done
