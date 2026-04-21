FROM ubuntu
# CLICOLOR_FORCE: Colored output for e.g. Conan & Ninja (otherwise -fcolor-diagnostics still won't work)
# CMAKE_COLOR_DIAGNOSTICS: Let CMake pass -fcolor-diagnostics
ENV CLICOLOR_FORCE=1 CMAKE_COLOR_DIAGNOSTICS=ON DEBIAN_FRONTEND=noninteractive

COPY ./builder/ubuntu-common.apt ./builder/ubuntu-lts.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN --mount=src=apt-cache/90pep-proxy,dst=/etc/apt/apt.conf.d/90pep-proxy \
    apt-get update && \
    apt-get upgrade -y --autoremove --purge && \
    apt-get install -y --no-install-recommends $(cat /tmp/ubuntu-common.apt /tmp/ubuntu-lts.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# New Ubuntu does not allow installing system/user packages with pip, so we use pipx
# Profile is not loaded for docker runners (https://docs.gitlab.com/runner/shells/index.html#shell-profile-loading ),
# so we put binaries in /usr/local/bin instead of the default ~/.local/bin
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install 'conan>=2.1,==2.*'

ENV GOPATH="/usr/local/go"
ENV PATH="${GOPATH}/bin:${PATH}"
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@latest

# Install Docker: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Install apptainer: adapted from https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
RUN --mount=src=apt-cache/90pep-proxy,dst=/etc/apt/apt.conf.d/90pep-proxy \
    add-apt-repository -y ppa:apptainer/ppa \
    && apt-get update \
    && apt-get install -y --no-install-recommends docker-ce docker-ce-cli docker-buildx-plugin docker-compose-plugin containerd.io apptainer \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# Install infer for SAST, mkdir the man/man1 directory due to Debian bug #863199
RUN mkdir -p /usr/share/man/man1 \
    && INFER_VERSION="v1.2.0" \
    && ARCHIVE="infer-linux-x86_64-${INFER_VERSION}.tar.xz" \
    && curl -fL "https://github.com/facebook/infer/releases/download/${INFER_VERSION}/${ARCHIVE}" | tar -xJ -C /opt \
    && ln -sfn "/opt/infer-linux-x86_64-${INFER_VERSION}" /infer

ENV PATH="/infer/bin:${PATH}"

ENV DEBIAN_FRONTEND='' CC=clang CXX=clang++
