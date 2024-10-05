# Function to check if a service is installed.
service_exists() {
    local n=$1
    if [[ $(systemctl list-units --all -t service --full --no-legend "$n.service" | sed 's/^\s*//g' | cut -f1 -d' ') == $n.service ]]; then
        return 0
    else
        return 1
    fi
}

if service_exists bind9; then
    # There is no need to download BIND9.
    echo "BIND9 SERVICE ALREADY INSTALLED."
    sudo systemctl start bind9
    sudoo systemctl enable bind9
else
    # BIND9 needs instalation.
    sudo apt install bind9 bind9utils bind9-doc
    sudo systemctl start bind9
    sudoo systemctl enable bind9
fi