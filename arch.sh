#!/bin/sh
VERSION=`date +%Y.%m`.01
wget -c http://mirror.nl.leaseweb.net/archlinux/iso/$VERSION/archlinux-bootstrap-$VERSION-x86_64.tar.gz
sudo tar -xzpf archlinux-bootstrap-$VERSION-x86_64.tar.gz
(cd root.x86_64/; sudo tar -cypf ../archlinux.tar.bz2 .)
sudo rm -rf root.x86_64
docker build --rm=true -f Dockerfile -t "bitpowder/archlinux" . && docker push bitpowder/archlinux
