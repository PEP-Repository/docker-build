ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive

COPY ./weblib.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && \
    apt-get install -y $(cat /tmp/weblib.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

RUN git clone --depth=1 https://github.com/emscripten-core/emsdk.git && \
    /emsdk/emsdk install latest && \
    /emsdk/emsdk activate latest && \
    echo '. /emsdk/emsdk_env.sh' >>~/.profile

ENV DEBIAN_FRONTEND=''
