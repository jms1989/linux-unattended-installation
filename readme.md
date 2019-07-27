# Linux Unattended Installation

This project provides all you need to create an unattended installation of a minimal setup of Linux, whereas *minimal* translates to the most lightweight setup - including an OpenSSH service and Python - which you can derive from the standard installer of a Linux distribution. The idea is, you will do all further deployment of your configurations and services with the help of Ansible or similar tools once you completed the minimal setup.

The `preseed.cfg` file currently auto installs openssh-server, nano, htop, screen, git, curl, and open-vm-tools to the machine.

## Ubuntu 16.04 LTS and 18.04 LTS

Use the `build-iso.sh` script to create an ISO file based on the netsetup image of Ubuntu.

Use the `build-disk.sh` script to create a cloneable preinstalled disk image based on the output of `build-iso.sh`.

### Features

* Fully automated installation procedure.
* Shutdown and power off when finished. We consider this a feature since it produces a defined and detectable state once the setup is complete. (disabled, re-enable in preseed file)
* Authentication based on SSH public key and not on a password.
* Setup ensures about 25% of free disk space in the LVM group. We consider this a feature since it enables you to use LVM snapshots; e.g., for backup purposes.
* Generates SSH server keys on first boot and not during setup stage. We consider this a feature since it enables you to use the installed image as a template for multiple machines.
* Prints IPv4 and IPv6 address of the device on screen once booted.
* Username is taken from the user running the script and password from `passwd` file.

### Prerequisites

Run `sudo apt-get install p7zip-full cpio gzip genisoimage whois pwgen wget fakeroot` to install software tools required by the `build-iso.sh` script.

Run `sudo apt-get install qemu-utils qemu-kvm` in addition to install software tools required by the `build-disk.sh` script.

Note: If using Ubuntu on the Windows Subsystem for Linux; do `sudo update-alternatives --set fakeroot /usr/bin/fakeroot-tcp` beforehand. Ran into a hickup with fakeroot.

### Usage

#### Build ISO images

You can run the `build-iso.sh` script as regular user. No root permissions required.

```sh
./ubuntu/<VERSION>/build-iso.sh <ssh-public-key-file> <target-iso-file> <password-file>
```

All parameters are optional.

| Parameter | Description | Default Value |
| :--- | :--- | :--- |
| `<ssh-public-key-file>` | The ssh public key to be placed in authorized_keys | `$HOME/.ssh/id_rsa.pub` |
| `<target-iso-file>` | The path of the ISO image created by this script | `ubuntu-<VERSION>-netboot-amd64-unattended.iso` |
| `<password-file>` | The path of the password file in plain text | `./passwd` |

A password file should be located in the repository root and called `passwd` with a plain text password. (I may try to make it so it must be hashed but for now, plain text will do. The password is hashed before it gets injected into the preseed file. :) )

Boot the created ISO image on the target VM or physical machine. Be aware the setup will start within 10 seconds automatically and will reset the disk of the target device completely. The setup tries to eject the ISO/CD during its final stage. It usually works on physical machines, and it works on VirtualBox. It might not function in certain KVM environments in case the managing environment is not aware of the *eject event*. In that case, you have to detach the ISO image manually to prevent an unintended reinstall.

Power-on the machine and log into it as root using your ssh key. The ssh host key will be generated on first boot.

#### Build disk images

(File has yet to be modified to match the iso builder)

You can run the `build-disk.sh` script as regular user. No root permissions required, if you are able to run `kvm` with your user account.

```sh
./ubuntu/<VERSION>/build-disk.sh <ram-size> <disk-size> <disk-format> <ssh-public-key-file> <disk-file>
```

All parameters are optional.

| Parameter | Description | Default Value |
| :--- | :--- | :--- |
| `<ram-size>` | The RAM size used during setup routine in MB (might affect size of swap partition) | `2048` |
| `<disk-size>` | The disk size of the disk image file to be created | `10G` |
| `<disk-format>` | The format of the disk image file to be created (qcow2 or raw) | `qcow2` |
| `<ssh-public-key-file>` | The ssh public key to be placed in authorized_keys | `$HOME/.ssh/id_rsa.pub` |
| `<disk-file>` | The path of the disk image created by this script | `ubuntu-<VERSION>-amd64-<ram-size>-<disk-size>.<disk-format>` |

Use the generated disk image as template image and create copies of it to deploy virtual or physical machines. Do not boot the template itself, since the ssh host key will be generated on first boot.

#### Credits

Scripts originally created by the [core-process](https://github.com/core-process/linux-unattended-installation) user on GitHub. Some bits of code were also copied from [netson](https://github.com/netson/ubuntu-unattended) user on Github as well.

Some files were modified and added by me.
