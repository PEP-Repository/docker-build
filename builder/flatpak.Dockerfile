FROM ubuntu:22.04
ENV CLICOLOR_FORCE=1

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y flatpak flatpak-builder bzip2 jq \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

RUN flatpak --user remote-add flathub https://dl.flathub.org/repo/flathub.flatpakrepo
RUN flatpak --user install -y org.kde.Platform//6.6
RUN flatpak --user install -y org.kde.Sdk//6.6
