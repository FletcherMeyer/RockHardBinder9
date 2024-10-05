#!/bin/bash
systemctl isolate multi-user.target
apt-get update
apt list --upgradable
apt-get upgrade