FROM ubuntu:22.04

# should be on one line, to avoid huge caches between steps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y openssl xxd libboost-atomic1.74.0 libboost-chrono1.74.0 libboost-date-time1.74.0 libboost-filesystem1.74.0 libboost-iostreams1.74.0 libboost-log1.74.0 libboost-random1.74.0 libboost-regex1.74.0 libboost-system1.74.0 libboost-thread1.74.0 zlib1g libbz2-1.0 libsqlite3-0 libunwind8 libevent-2.1-7 libevent-pthreads-2.1-7 libqt6core6 libqt6network6 libqt6gui6 libqt6printsupport6 libqt6widgets6 libqt6networkauth6 libqt6svg6 ca-certificates rsyslog rsyslog-gnutls logrotate pkg-config bash-completion zsh && apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*
