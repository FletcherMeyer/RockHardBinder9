CHROOT_DIR=/var/bind9/chroot

#
#   Manage Logging
#

mkdir -p ${CHROOT_DIR}/tmp/logs/

touch ${CHROOT_DIR}/tmp/logs/dns_queries.msgs
touch ${CHROOT_DIR}/tmp/logs/dns_debug.msgs
touch ${CHROOT_DIR}/tmp/logs/dns_errors.msgs
touch ${CHROOT_DIR}/tmp/logs/dns_critical.msgs

chown bind:bind ${CHROOT_DIR}/tmp/logs/{dns_queries.msgs,dns_debug.msgs,dns_errors.msgs,dns_critical.msgs}
chmod 775 ${CHROOT_DIR}/tmp/logs/{dns_queries.msgs,dns_debug.msgs,dns_errors.msgs,dns_critical.msgs}
chgrp bind ${CHROOT_DIR}/tmp/logs/{dns_queries.msgs,dns_debug.msgs,dns_errors.msgs,dns_critical.msgs}

cat <<-EOF > $CHROOT_DIR/etc/bind/named.conf.logging
logging {
    // Syslog logging for general information.
    channel my_syslog {
        syslog daemon;
        severity info;
        print-time yes;
    };

    // All queries sent to our service.
    channel dns_queries {
        file "/tmp/dns_queries.msgs";
        severity info;
        print-time yes;
    };

    // Level 5 debug messages.
    channel dns_debug {
        file "/tmp/dns_debug.msgs";
        severity debug 5;
        print-time yes;
    };

    // Error messages.
    channel dns_errors {
        file "/tmp/dns_errors.msgs";
        severity error;
        print-time yes;
    };

    // Critical messages.
    channel dns_critical {
        file "/tmp/dns_critical.msgs";
        severity error;
        print-time yes;
    };

    // Throwaway
    channel null {
        null;
    };

    category general { 
        dns_critical; 
        dns_debug;
        dns_errors; 
    };

    category queries { dns_queries; };
};
EOF


cat <<-EOF > $CHROOT_DIR/etc/bind/named.conf.options

options {
    directory "/var/cache/bind";

    auth-nxdomain no;

    recursion no;

    fetch-glue no;

    blackhole {
        null;
    };

    forwarders {
        208.67.220.220;
        208.67.222.222;
    };

    transfers-per-ns 1;
    transfers-in 2;

    allow-recursion {
        localhost;
        172.20.240.0/24;
        172.20.241.0/24;
    };
    allow-transfer {
        localhost;
        172.20.240.0/24;
        172.20.241.0/24;
    };
    allow-query {
        localhost;
        172.20.240.0/24;
        172.20.241.0/24;
    };

    dnssec-validation auto;

    listen-on-v6 { none; };

    use-id-pool yes;

    forward only;

    version "9.3.6-P1+deb9u8-Debian";

    rrset-order {order cyclic;};
};
EOF 

cat <<-EOF > $CHROOT_DIR/etc/bind/named.conf

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
include "/etc/bind/named.conf.logging";

EOF
