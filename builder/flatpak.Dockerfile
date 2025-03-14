FROM ubuntu
ENV CLICOLOR_FORCE=1 DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
    && apt-get upgrade -y --autoremove --purge \
    && apt-get install -y flatpak flatpak-builder bzip2 jq \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

RUN flatpak --user remote-add flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak --user install -y org.kde.Platform//6.7 \
    && flatpak --user install -y org.kde.Sdk//6.7

ENV DEBIAN_FRONTEND=''
