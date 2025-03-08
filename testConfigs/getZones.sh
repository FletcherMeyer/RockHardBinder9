#!/bin/bash

# Define the path where BIND9 zone files are typically stored
ZONE_DIR="/etc/bind/zones"  # Modify this based on your system

# Check if the zone directory exists
if [ ! -d "$ZONE_DIR" ]; then
    echo "Error: Directory $ZONE_DIR not found!"
    exit 1
fi

    # Loop through each zone file in the directory
    find "$ZONE_DIR" -type f \( -name "*.zone" -o -name "*.db" \) | while read -r zone_file; do
    echo "Processing zone file: $zone_file"
    
    # Extract A and AAAA records and print the domain and corresponding IP
    grep -E '^\s*\S+\s+IN\s+A\s+\S+' "$zone_file" | while read -r line; do
        # Extract domain and IP from the A record
        domain=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $NF}')
        echo "$domain -> $ip"
    done

    grep -E '^\s*\S+\s+IN\s+AAAA\s+\S+' "$zone_file" | while read -r line; do
        # Extract domain and IP from the AAAA record
        domain=$(echo "$line" | awk '{print $1}')
        ip=$(echo "$line" | awk '{print $NF}')
        echo "$domain -> $ip"
    done

done
