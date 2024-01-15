FROM ubuntu:22.04

COPY ./ubuntu-2204.apt /tmp/requirements.apt

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $(cat /tmp/requirements.apt) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*
