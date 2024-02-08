FROM ubuntu:22.04

COPY ./ubuntu-2204.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $(cat /tmp/ubuntu-2204.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*
