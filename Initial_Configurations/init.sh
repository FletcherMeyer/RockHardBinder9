#!/bin/bash

# Cute animation I wanted to use :3
loading() {
    local pid=$1
    local delay=0.2
    local spin='-\|/'
    i=0
    while kill -0 $pid 2>/dev/null; do
        for i in $(seq 0 3); do 
            echo -n "[${spin:i:1}]"
            sleep $delay
            echo -ne "\r"
        done
    done
    echo -ne "\rProcess Finished.\n"
}
echo -e "\033[36mDebian 10 DNS/NTP Configuration has begun.\n\n"

# Declare the files and their purpose.
# TODO: Replace with a JSON file or Map.
declare -a typeName=("Basic" "IPTable" "BIND9" "Chroot (Jail)")
declare -a fileName=("basicConf" "iptableConf" "bind9Conf" "chrootConf")
declare -i numOfScripts=${#fileName[@] - 1}

# Loop through the above lists
for i in $(seq 0 $numOfScripts); do
    echo -e "${typeName[i]} Configuration has begun..."
    bash ./${fileName[i]}.sh &
    loading $!
    wait $!
    echo -e "${typeName[i]} Configuration finished!"
done

echo -e "Configuration finished!\033[0m\n"
