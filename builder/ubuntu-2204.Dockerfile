ARG CONCURRENCY_LIMIT

FROM ubuntu:22.04

COPY ./ubuntu-common.apt ./ubuntu-2204.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $(cat /tmp/ubuntu-common.apt /tmp/ubuntu-2204.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# Profile is not loaded for docker runners (https://docs.gitlab.com/runner/shells/index.html#shell-profile-loading ),
# so we put binaries in /usr/local/bin instead of the default ~/.local/bin
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install 'conan>=2.1,==2.*'

# Install Docker: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
# Install apptainer: adapted from https://apptainer.org/docs/admin/main/installation.html#install-ubuntu-packages
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN add-apt-repository -y ppa:apptainer/ppa \
    && apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io apptainer \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV CC=clang
ENV CXX=clang++

# Install dependencies with Conan
COPY ./conan/conan_install.sh /tmp/
RUN /tmp/conan_install.sh "${CONCURRENCY_LIMIT}" && rm -rf /tmp/*
