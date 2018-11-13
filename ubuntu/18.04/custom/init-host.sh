#!/bin/bash
#set -e

# set defaults
default_hostname="`hostname -s`"
default_domain="`hostname -d`"
tmp="/root/"
username="`logname`"

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
apt-get -y update
apt-get -y -o Dpkg::Options::="--force-confold" upgrade
apt-get -y autoremove
apt-get -y purge
#apt-get -y install python3-pip python3-dev

# install The Fuck python package
#pip3 install thefuck

# Disable all Default Motd.d scripts except the header
# Default Scripts
# 00-header  10-help-text  50-motd-news  80-esm  80-livepatch  91-release-upgrade

chmod -x --quiet /etc/update-motd.d/{10..99}* 

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

