FROM ubuntu:rolling
ENV CLICOLOR_FORCE=1 DEBIAN_FRONTEND=noninteractive

COPY ./ubuntu-common.apt ./ubuntu-rolling.apt /tmp/

# should be in one RUN command, to avoid huge caches between steps
RUN apt-get update && \
    apt-get upgrade -y --autoremove --purge && \
    apt-get install -y $(cat /tmp/ubuntu-common.apt /tmp/ubuntu-rolling.apt | cut -d'#' -f1) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# New Ubuntu does not allow installing system/user packages with pip, so we use pipx
# Profile is not loaded for docker runners (https://docs.gitlab.com/runner/shells/index.html#shell-profile-loading ),
# so we put binaries in /usr/local/bin instead of the default ~/.local/bin
ENV PIPX_BIN_DIR=/usr/local/bin
RUN pipx install 'conan>=2.1,==2.*'

# Install Docker: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list >/dev/null
RUN apt-get update \
    && apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV DEBIAN_FRONTEND='' CC=clang CXX=clang++
