#!/bin/bash

sudo mkdir /var/named/chroot
sudo rsync -av /etc/bind /var/named/chroot

sudo named-checkconf
sudo systemctl status bind9
sudo systemctl start bind9
