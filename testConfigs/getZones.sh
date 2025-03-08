  # Extract domains for name servers from A records
  name_servers=$(awk '/\s+IN\s+A\s+/ {print $1}' "$zone_file" | sort | uniq)

  # Loop through A and AAAA records to exclude name servers
  awk '!/ IN\s+NS\s+/ {print}' "$zone_file" | \
  
  # Extract A records and print the domain and corresponding IP, excluding name servers
  grep -E '^\s*\S+\s+IN\s+A\s+\S+' | while read -r line; do
    domain=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | awk '{print $NF}')
    
    # Exclude name servers from the output
    if ! echo "$name_servers" | grep -qx "$domain"; then
      echo "$domain -> $ip"
    fi
  done
