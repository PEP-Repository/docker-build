FROM ubuntu:rolling

RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y clang ninja-build golang golang-goprotobuf-dev ccache distcc git cmake valgrind libboost-all-dev zlib1g-dev libbz2-dev libsqlite3-dev libcurl4-openssl-dev curl libpam0g-dev libssl-dev libreadline-dev patch flex qt6-base-dev qt6-networkauth-dev qt6-svg-dev qt6-tools-dev qt6-tools-dev-tools libunwind-dev libc6-dev libc6-dev-i386 software-properties-common python-is-python3 unzip zip jq gnupg \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

# Install Docker: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV CC=clang
ENV CXX=clang++