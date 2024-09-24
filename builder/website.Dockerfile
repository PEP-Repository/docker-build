FROM ubuntu:22.04
ENV CLICOLOR_FORCE=1 DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y --autoremove --purge \
    && apt-get install -y make sassc libjpeg-turbo-progs pngcrush cpio openssh-client g++ \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV DEBIAN_FRONTEND=''
