#!/bin/bash

# Set Default to CLI
# TODO: Prompt the engineer if they wish to do this.
systemctl isolate multi-user.target

# Update and upgrade.
# TODO: Include necessary packages the engineer may use for an inject or security configuration.
# BIND9 is not included. It is in a separate script.

# debootstrap is an important package we will be using to 'jail' our BIND9 service.
# If there does seem to be a vulnurability through BIND9, this serves to mitigate any damage done to exclusively the service.
apt install debootstrap


apt-get update
apt-get upgrade
