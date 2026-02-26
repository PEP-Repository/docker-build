# ubuntu-lts
ARG BASE_IMAGE
FROM ${BASE_IMAGE}
ENV DEBIAN_FRONTEND=noninteractive

COPY ./builder/weblib.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && \
    apt-get install -y --no-install-recommends $(cat /tmp/weblib.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# When updating, also change in conan_profile_wasm32
ARG EMSDK_VERSION=4.0.22
RUN git clone --depth=1 https://github.com/emscripten-core/emsdk.git && \
    /emsdk/emsdk install "$EMSDK_VERSION" && \
    /emsdk/emsdk activate "$EMSDK_VERSION" && \
    echo '. /emsdk/emsdk_env.sh' >>~/.profile && \
    # tsc isn't installed by default as it's in devDependencies but we need it for --emit-tsd,
    # see related https://github.com/emscripten-core/emsdk/issues/1370
    bash --login -c 'cd /emsdk/upstream/emscripten/ && npm install --omit=dev --save-prod typescript' && \
    # Workaround for https://github.com/conan-io/conan/issues/19677
    bash --login -c 'emcc --version'

RUN pipx install websockify

ENV DEBIAN_FRONTEND=''
