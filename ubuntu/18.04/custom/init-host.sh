#!/bin/bash
set -e

# set defaults
default_hostname="$(hostname)"
default_domain="sanlan"
tmp="/root/"
username="$(logname)"

clear

# check for root privilege
if [ "$(id -u)" != "0" ]; then
   echo " this script must be run as root" 1>&2
   echo
   exit 1
fi

# determine ubuntu version
ubuntu_version=$(lsb_release -cs)

# check for interactive shell
if ! grep -q "noninteractive" /proc/cmdline ; then
    stty sane

    # ask questions
    read -ep " please enter your preferred hostname: " -i "$default_hostname" hostname
    read -ep " please enter your preferred domain: " -i "$default_domain" domain

fi
# print status message
echo " preparing your server; this may take a few minutes ..."

# set fqdn
fqdn="$hostname.$domain"

# update hostname
echo "$hostname" > /etc/hostname
sed -i "s@ubuntu.ubuntu@$fqdn@g" /etc/hosts
sed -i "s@ubuntu@$hostname@g" /etc/hosts
hostname "$hostname"

# update repos
apt -y update
apt -y -o Dpkg::Options::="--force-confold" upgrade
apt -y autoremove
apt -y purge
apt -y install python3-pip python3-dev

# install The Fuck python package
pip3 install thefuck

# start user script
firstuser="$(getent passwd 1000 | cut -d: -f1)"
sudo -u "$firstuser" -i "./init-user-home.sh"

# remove myself to prevent any unintended changes at a later stage
sed -i '10,12d' /root/.profile
rm $0

# finish
echo " DONE; rebooting ... "

# reboot
reboot

