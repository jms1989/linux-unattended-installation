#!/bin/bash
username=`echo $USER`;
docker run -it -v "$HOME"/gitrepos/ubuntu-linux-automation:/build \
-v "$HOME"/.ssh:/home/user/.ssh -w /build -u `id -u` -e USER="$username" \
jms1989/ubuntu-iso-builder /build/ubuntu/18.04/build-iso.sh
exit
