# Purpse
RockHardBinder9 is meant to create a protected Master DNS Server on a Debian 10 Buster. 

# What does it do?
- Basic security configurations for the operating system
  - chroot jail system
  - iptables
  - auditd
  - Minimal priveleges, services
  - Root account migration
The end goal of the binder is to create a rock hard system.

# Future
Redundancy. Check if the service has failed in the chroot environment, before automatically restarting it and validating zone files.
