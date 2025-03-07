if [[ "$EUID" -ne 0 ]]
then
    printf 'Must be run as root, exiting!\n'
    exit 1
fi

GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
RESET="\e[0m"

curr=$(dirname "$0")

bash "$curr/RockyValidate.sh"

touch "$curr/rocky.log"
mkdir "$curr/ammo"

if [ $? == '0' ]; then
    echo "[${$GREEN}SUCCESS${$RESET}] $(date | awk '{print $4}'| cut -d ':' -f3) Rocky Raccoon validated DNS."
    bash "$curr/RockyBackup.sh" $curr/ammo $curr/records.txt
    exit(0);
else
    echo "[${$RED}FAILURE${$RESET}] $(date | awk '{print $4}'| cut -d ':' -f3) Rocky Raccoon was unable to validate DNS." 
    bash "$curr/RockyLoad.sh" $curr/ammo $curr/records.txt
fi

