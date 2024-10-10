#!/bin/bash

# This script can be used for rebuilding our table if it is in some way compromised.
# Specific services may have a prompt attached to them in case the engineer wants to experiment.

# Empty all rules
iptables -t filter -F
iptables -t filter -X

# Block everything by default
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP
iptables -t filter -P OUTPUT DROP

# Authorize already established connections
# TODO: PROMPT YES OR NO AND FIGURE OUT IF THIS IS NECESSARY
iptables -A INPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT

# ICMP (Ping)
iptables -t filter -A INPUT -p icmp -j ACCEPT
iptables -t filter -A OUTPUT -p icmp -j ACCEPT

# DNS 
# (Important! This is what our service operates on. DNS Protocol uses either TCP or UDP. DNSSEC operates on the same port)
iptables -t filter -A OUTPUT -p tcp --dport 53 -j ACCEPT
iptables -t filter -A OUTPUT -p udp --dport 53 -j ACCEPT
iptables -t filter -A INPUT -p tcp --dport 53 -j ACCEPT
iptables -t filter -A INPUT -p udp --dport 53 -j ACCEPT

# HTTP/HTTPS 
# (If needed; We don't have a service operating on the port unless we specifically make a request so this could be disabled otherwise.)
iptables -t filter -A OUTPUT -p tcp --dport 80 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 443 -j ACCEPT

# NTP (Server time, if needed.)
iptables -t filter -A OUTPUT -p udp --dport 123 -j ACCEPT
iptables -t filter -A INPUT -p udp --dport 123 -j ACCEPT

# Splunk 
# For logging.
iptables -t filter -A OUTPUT -p tcp --dport 8000 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 9997 -j ACCEPT
iptables -t filter -A OUTPUT -p tcp --dport 8089 -j ACCEPT
