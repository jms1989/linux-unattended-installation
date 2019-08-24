FROM ubuntu:18.04
RUN apt-get update && apt-get install -y p7zip-full cpio gzip genisoimage whois pwgen wget fakeroot patch
ENV TZ=America/Chicago
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone
RUN useradd -ms /bin/bash user

# I want a to make a single file that will build the builder then start the iso builder script. This doesn't map to the right directory with the named build stage. Not sure how to chain them properly.
#FROM ubuntu-iso-builder
#COPY $HOME/.ssh /root/
#WORKDIR /build/
#COPY ./* .
#RUN ubuntu/18.04/build-iso.sh
#RUN chown 1000:1000 *.iso
#COPY *.iso .

# Just use the shell scripts for now.
