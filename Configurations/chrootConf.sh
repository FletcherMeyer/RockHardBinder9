# Stopping BIND
service bind9 stop

# Creation of the chroot jail under /var/lib/bind
mkdir -p /var/lib/bind/{dev,etc,var,var/run/named,var/cache/bind}
mknod /var/lib/bind/dev/null c 1 3
mknod /var/lib/bind/dev/random c 1 8
chmod 666 /var/lib/bind/dev/{null,random}

# Backup of the BIND files (optional)
[ -d /var/local/backups ] || mkdir /var/local/backups
cp -a /etc/bind /var/local/backups/etc_bind.orig

# Copy of the files to the chroot jail
cp /etc/localtime /var/lib/bind/etc/
cp -a /etc/bind /var/lib/bind/etc/
cp -a /var/cache/bind/* /var/lib/bind/var/cache/bind/

# Modification of file permissions and owners
chgrp bind /var/lib/bind/{var/cache/bind,var/run/named}
chmod g+w /var/lib/bind/{var/cache/bind,var/run/named}
chgrp bind /var/lib/bind
chmod 750 /var/lib/bind

# Configuration of rsyslog
cat <<'_EOD_' > /etc/rsyslog.d/bind-chroot.conf
$AddUnixListenSocket /var/lib/bind/dev/log
_EOD_
service rsyslog restart

# Adding the option -t to named to specify the chroot
sed -i \
-e 's|OPTIONS="-u bind"|OPTIONS="-u bind -t /var/lib/bind"|' \
/etc/default/bind9
service bind9 restart

if systemctl is-active --quiet bind9; then
    # Because everything is operating normally on our chrooted system, we can delete the original files to clear any clutter.
    rm -rf /etc/bind/* /var/cache/bind/*

    # Optional operation to ease the access to BIND files for admins
    rmdir /etc/bind
    ln -s /var/lib/bind/etc/bind /etc/bind

    echo "Jailing BIND9 was successful!"
else
    echo "Something is wrong! The BIND9 service was unable to be jailed..."
fi
