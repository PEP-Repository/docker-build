FROM ubuntu:rolling

COPY ./ubuntu-rolling.apt /tmp/requirements.apt

RUN apt-get update && DEBIAN_FRONTEND=noninteractive apt-get install -y $(cat /tmp/requirements.apt) && \
    apt-get clean && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

COPY ./python-requirements.txt /tmp/python-requirements.txt
RUN pip3 install --requirement /tmp/python-requirements.txt

# Install Docker: https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository
RUN curl -fsSL https://download.docker.com/linux/ubuntu/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
RUN echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
RUN apt-get update \
    && DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io \
    && apt-get clean \
    && rm -rf /var/cache/* /var/lib/{apt,dpkg,cache,log}/* /tmp/* /var/tmp/*

ENV CC=clang
ENV CXX=clang++
