FROM ubuntu
ENV CLICOLOR_FORCE=1 DEBIAN_FRONTEND=noninteractive

RUN --mount=src=apt-cache/90pep-proxy,dst=/etc/apt/apt.conf.d/90pep-proxy \
    apt-get update \
    && apt-get upgrade -y --autoremove --purge \
    && apt-get install -y --no-install-recommends ca-certificates elfutils flatpak flatpak-builder git bzip2 jq \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

RUN flatpak remote-add flathub https://dl.flathub.org/repo/flathub.flatpakrepo \
    && flatpak install -y org.kde.Platform//6.8 \
    && flatpak install -y org.kde.Sdk//6.8

ENV DEBIAN_FRONTEND=''
