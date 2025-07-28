# ubuntu-lts
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive

COPY ./builder/weblib.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat /tmp/weblib.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

RUN git clone --depth=1 https://github.com/emscripten-core/emsdk.git && \
    /emsdk/emsdk install latest && \
    /emsdk/emsdk activate latest && \
    echo '. /emsdk/emsdk_env.sh' >>~/.profile && \
    # tsc isn't installed by default but we need it for --emit-tsd, see related https://github.com/emscripten-core/emsdk/issues/1370
    bash --login -c 'cd /emsdk/upstream/emscripten/ && npm install typescript'

RUN pipx install websockify

ENV DEBIAN_FRONTEND=''
