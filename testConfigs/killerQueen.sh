#!/bin/bash

# Define the approved ports (can be modified by the developer)
approved_ports=("53" "123")

# Log file location
log_file="/var/log/network_connections.log"

# Function to check if a port is approved
is_approved_port() {
    local port=$1
    for approved_port in "${approved_ports[@]}"; do
        if [[ "$approved_port" == "$port" ]]; then
            return 0  # Return 0 if the port is approved
        fi
    done
    return 1  # Return 1 if the port is not approved
}

# Get the network connections (using ss as an alternative to netstat)
ss -tulnp | grep -E 'ESTAB' | while read -r connection; do
    # Extract relevant details from the connection
    local local_address=$(echo $connection | awk '{print $5}' | cut -d':' -f2)
    local pid=$(echo $connection | awk '{print $6}' | cut -d',' -f1)
    
    # Get the process path and name using the PID
    local process_info=$(ps -p $pid -o pid,comm,etime,cmd)
    
    # Check if the process is running on an approved port
    if ! is_approved_port "$local_address"; then
        # Log the details of the process that is not on an approved port
        echo "Process ID: $pid, File: $process_info" >> "$log_file"

        # Kill the process and remove the file (if possible)
        echo "Killing process ID: $pid and removing files..."
        kill -9 "$pid"

        # Attempt to find and delete the associated file (if possible)
        local file_path=$(echo "$process_info" | awk '{print $4}')
        if [[ -f "$file_path" ]]; then
            echo "Deleting file: $file_path"
            rm -f "$file_path"
        fi
    else
        echo "Process running on approved port ($local_address): $pid, $process_info"
    fi
done

echo "Script completed. See $log_file for details."
