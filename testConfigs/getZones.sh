#!/bin/bash

echo "Please enter where all the zones at : "
read zone_dir

if [ "$zone_dir" == "" ]; do
    zone_dir="/etc/bind/zones"
fi

find "$zone_dir" -type f -name "db*" -o -name "*db" -o -name "*zone" | while read -r zone_file; do
    echo "OKAY processing $zone_file"
    grep -E '^\s*\S+\s+IN\s+A\s+\S+' "$zone_file" | while read -r line; do
        domain=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $NF}')
        echo "$domain resolves to $ip"
    done
        grep -E '^\s*\S+\s+IN\s+AAAA\s+\S+' "$zone_file" | while read -r line; do
        domain=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $NF}')
        echo "$domain resolves to $ip"
    done
    grep -E '^\s*\S+\s+IN\s+NS\s+\S+' "$zone_file" | while read -r line; do
        domain=$(echo "$line" | awk '{print $1}')
        echo "$domain is a name server"
    done
done
    
