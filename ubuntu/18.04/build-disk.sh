#!/bin/bash
set -e

if ! vbox="$(hash -p "$vboxmanage")" || [[ -z $vbox ]]; then
        echo "Virtualbox is not installed"
        echo "exiting..."
        exit 1
fi

# get parameters
RAM_SIZE=${1:-"1024"}
DISK_SIZE=${2:-"8096"} # In Megabytes
DISK_FORMAT=${3:-"vmdk"} # VDI|VMDK|VHD
SSH_PUBLIC_KEY_FILE=${4:-"$HOME/.ssh/authorized_keys"}
DISK_FILE=${5:-"ubuntu-18.04-amd64-$RAM_SIZE-$DISK_SIZE.$DISK_FORMAT"}
OS="Ubuntu_18"

# create iso
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
TMP_ISO_DIR="/home/michael/vm" #"`mktemp -d`"

if [ ! -d "$TMP_ISO_DIR" ]; then
	mkdir "$TMP_ISO_DIR"
fi

if [ -f "$TMP_ISO_DIR/ubuntu-18.04-netboot-amd64-unattended.iso" ]; then
	echo "ISO file exists. Continuing..."
else
	eval "$SCRIPT_DIR/build-iso.sh" "$SSH_PUBLIC_KEY_FILE" "$TMP_ISO_DIR/ubuntu-18.04-netboot-amd64-unattended.iso"
fi

# create image and run installer
#qemu-img create "$DISK_FILE" -f "$DISK_FORMAT" "$DISK_SIZE"
#kvm -m "$RAM_SIZE" -cdrom "$TMP_ISO_DIR/ubuntu-18.04-netboot-amd64-unattended.iso" -boot once=d "$DISK_FILE"
if [ -d "$TMP_ISO_DIR"/"$OS" ]; then
        echo "VirtualBox image is already created"
else
vboxmanage createvm --name "$OS" --ostype "Ubuntu_64" --basefolder "$TMP_ISO_DIR" --register
vboxmanage createhd --filename "$TMP_ISO_DIR"/"$OS"/"$DISK_FILE" --format "$DISK_FORMAT" --size "$DISK_SIZE"
vboxmanage storagectl "$OS" --name "SATA Controller" --add sata --name "SATA Controller" --add sata
vboxmanage storageattach "$OS" --storagectl "SATA Controller" --port 0 --device 0 --type hdd --medium "$TMP_ISO_DIR"/"$OS"/"$DISK_FILE"
vboxmanage storagectl "$OS" --name "IDE Controller" --add ide
vboxmanage storageattach "$OS" --storagectl "IDE Controller" --port 0 --device 0 --type dvddrive --medium "$TMP_ISO_DIR"/ubuntu-18.04-netboot-amd64-unattended.iso
vboxmanage modifyvm "$OS" --ioapic on
vboxmanage modifyvm "$OS" --boot1 dvd --boot2 disk --boot3 none --boot4 none
vboxmanage modifyvm "$OS" --memory "$RAM_SIZE" --vram 32
vboxmanage modifyvm "$OS" --nic1 bridged --bridgeadapter1 e1000g0
vboxmanage unregistervm "$OS"
fi

# remove tmp
#rm -r -f "$TMP_ISO_DIR"

# done
echo "Next steps: deploy image, login via root, adjust the authorized keys, set a root password (if you want to), deploy via ansible (if applicable), enjoy!"
