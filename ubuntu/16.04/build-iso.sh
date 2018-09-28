#!/bin/bash
set -e

# get parameters
SSH_PUBLIC_KEY_FILE=${1:-"$HOME/.ssh/authorized_keys"}
TARGET_ISO=${2:-"`pwd`/ubuntu-16.04-netboot-amd64-unattended.iso"}
hostname="ubuntu"
username="$USER"

# check if ssh key exists
if [ ! -f "$SSH_PUBLIC_KEY_FILE" ];
then
    echo "Error: public SSH key $SSH_PUBLIC_KEY_FILE not found!"
    exit 1
fi

# get directories
CURRENT_DIR="`pwd`"
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_DOWNLOAD_DIR="`mktemp -d`"
TMP_DISC_DIR="`mktemp -d`"
TMP_INITRD_DIR="`mktemp -d`"

# Password file
passwdfile=${3:-"$CURRENT_DIR/passwd"}

# download and extract netboot iso
SOURCE_ISO_URL="http://mirror.lstn.net/ubuntu/dists/xenial/main/installer-amd64/current/images/netboot/mini.iso"
cd "$TMP_DOWNLOAD_DIR"
wget -4 "$SOURCE_ISO_URL" -O "./netboot.iso"
7z x "./netboot.iso" "-o$TMP_DISC_DIR"

# patch boot menu
cd "$TMP_DISC_DIR"
patch -p1 -i "$SCRIPT_DIR/custom/boot-menu.patch"

# prepare assets
cd "$TMP_INITRD_DIR"
mkdir "./custom"
cp "$SCRIPT_DIR/custom/preseed.cfg" "./preseed.cfg"
cp "$SSH_PUBLIC_KEY_FILE" "./custom/userkey.pub"
cp "$SCRIPT_DIR/custom/ssh-host-keygen.service" "./custom/ssh-host-keygen.service"
cp "$SCRIPT_DIR/custom/init-user-home.sh" "./custom/init-user-home.sh"
cp "$SCRIPT_DIR/custom/init-host.sh" "./custom/init-host.sh"

# do some timezone stuff
if [ -f /etc/timezone ]; then
  timezone=`cat /etc/timezone`
elif [ -h /etc/localtime]; then
  timezone=`readlink /etc/localtime | sed "s/\/usr\/share\/zoneinfo\///"`
else
  checksum=`md5sum /etc/localtime | cut -d' ' -f1`
  timezone=`find /usr/share/zoneinfo/ -type f -exec md5sum {} \; | grep "^$checksum" | sed "s/.*\/usr\/share\/zoneinfo\///" | head -n 1`
fi

# Read password file and if it doesn't exist, ask for one.
if [[ -f "$passwdfile" && -s "$passwdfile" ]]; then
        password=$(<$passwdfile)
else
        read -sp " please enter your preferred password: " password
        printf "\n"
        read -sp " confirm your preferred password: " password2

        # check if the passwords match to prevent headaches
        if [[ "$password" != "$password2" ]]; then
            echo " your passwords do not match; please restart the script and try again"
            echo
            exit
        fi
fi

# ask the user questions about his/her preferences
#read -ep " please enter your preferred timezone: " -i "${timezone}" timezone
#read -ep " Make ISO bootable via USB: " -i "no" bootable
echo;

# generate the password hash
pwhash=$(echo $password | mkpasswd -s -m sha-512)

# update the seed file to reflect the users' choices
# the normal separator for sed is /, but both the password and the timezone may contain it
# so instead, I am using @
sed -i "s@{{username}}@$username@g" "./preseed.cfg"
sed -i "s@{{pwhash}}@$pwhash@g" "./preseed.cfg"
sed -i "s@{{hostname}}@$hostname@g" "./preseed.cfg"

# append assets to initrd image
cd "$TMP_INITRD_DIR"
cat "$TMP_DISC_DIR/initrd.gz" | gzip -d > "./initrd"
echo "./preseed.cfg" | fakeroot cpio -o -H newc -A -F "./initrd"
find "./custom" | fakeroot cpio -o -H newc -A -F "./initrd"
cat "./initrd" | gzip -9c > "$TMP_DISC_DIR/initrd.gz"

# build iso
cd "$TMP_DISC_DIR"
rm -r '[BOOT]'
mkisofs -r -V "ubuntu 16.04 netboot unattended" -cache-inodes -J -l -b isolinux.bin -c boot.cat -no-emul-boot -boot-load-size 4 -boot-info-table -input-charset utf-8 -o "$TARGET_ISO" ./

# go back to initial directory
cd "$CURRENT_DIR"

# delete all temporary directories
rm -r "$TMP_DOWNLOAD_DIR"
rm -r "$TMP_DISC_DIR"
rm -r "$TMP_INITRD_DIR"

# done
echo "Next steps: install system, login via root, follow on-screen instructions, let it process and reboot, login as regular user with preconfigure keys, profit!"
