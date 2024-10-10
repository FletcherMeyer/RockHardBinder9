# !/bin/bash

# create initial named user and group.
groupadd named
useradd -g named -d /chroot/named -s /bin/true named
passwd -l named     "lock" the account

# Remove all the login-related trash under the newly-created home directory.
rm -rf /chroot/named

# Re-create the top level jail directory.
mkdir -p /chroot/named
cd /chroot/named

# Create the hierarchy.
mkdir dev
mkdir etc
mkdir logs
mkdir -p var/run
mkdir -p conf/secondaries

# Create the devices, but confirm the major/minor device.
# Cumbers with   "ls -lL /dev/zero /dev/null /dev/random"
mknod dev/null c 1 3
mknod dev/zero c 1 5
mknod dev/random c 1 8

# copy the timezone file
cp /etc/localtime etc

# Make symbolic link and copy over our named.conf file.
ln -s /chroot/named/etc/named.conf /etc/named.conf
cp ./conf_Files/named.conf /etc/named.conf

# Get our information using dig and send to our db.rootcache
dig +tcp @a.root-servers.net . ns > /chroot/named/conf/db.rootcache
cp ./conf_Files/db.localhost chroot/named/conf/db.localhost
cp ./conf_Files/db.127.0.0 chroot/named/conf/db.127.0.0

#   
#   Set the ownership and permissions on the named directory.
#

cd /chroot/named


# By default, root owns everything and only root can write, but dirs
# have to be executable too. Note that some platforms use a dot
# instead of a colon between user/group in the chown parameters}.

chown -R root:named .

find . -type f -print | xargs chmod u=rw,og=r     # regular files
find . -type d -print | xargs chmod u=rwx,og=rx   # directories

# The named.conf and rndc.conf must protect their keys.
chmod o= etc/*.conf

# The "secondaries" directory is where we park files from
# Master nameservers, and named needs to be able to update
# These files and create new ones.

touch conf/secondaries/.empty  # placeholder
find conf/secondaries/ -type f -print | xargs chown named:named
find conf/secondaries/ -type f -print | xargs chmod ug=r,o=

chown root:named conf/secondaries/
chmod ug=rwx,o=  conf/secondaries/

# The var/run business is for the PID file.
chown root:root  var/
chmod u=rwx,og=x var/

chown root:named  var/run/
chmod ug=rwx,o=rx var/run/

# Named has to be able to create logfiles.
chown root:named  logs/
chmod ug=rwx,o=rx logs/

sh -x /chroot/named.perms
# Something like this :
# + cd /chroot/named
# + chown -R root:named .
# + find . -type f -print
# + xargs chmod u=rw,og=r
# + find . -type d -print
# + xargs chmod u=rwx,og=rx
# + chmod o= etc/named.conf etc/rndc.conf
# + touch conf/secondaries/.empty
# + find conf/secondaries/ -type f -print
# + xargs chown named:named
# + find conf/secondaries/ -type f -print
# + xargs chmod ug=r,o=
# + chown root:named conf/secondaries/
# + chmod ug=rwx,o= conf/secondaries/
# + chown root:root var/
# + chmod u=rwx,og=x var/
# + chown root:named var/run/
# + chmod ug=rwx,o=rx var/run/

#
#   Start the name server up baby!
#

cd /chroot/named

# Make sure the debugging-output file is writable by named.
touch named.run
chown named:named named.run
chmod ug=rw,o=r   named.run

PATH=/usr/local/sbin:$PATH named  \
        -t /chroot/named \
        -u named \
        -c /etc/named.conf
