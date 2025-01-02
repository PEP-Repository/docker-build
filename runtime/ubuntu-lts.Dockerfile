FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

COPY ./ubuntu-lts.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && \
    apt-get upgrade -y --autoremove --purge && \
    apt-get install -y $(cat /tmp/ubuntu-lts.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV DEBIAN_FRONTEND=''
