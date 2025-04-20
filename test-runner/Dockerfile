FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    ca-certificates \
    tar \
    npm \
    unzip \
    openjdk-11-jdk \
    jq \
    bc \
    && rm -rf /var/lib/apt/lists/*

ENV GOLANG_VERSION 1.20.12
RUN curl -fsSL "https://golang.org/dl/go${GOLANG_VERSION}.linux-amd64.tar.gz" -o go.tar.gz \
    && tar -C /usr/local -xzf go.tar.gz \
    && rm go.tar.gz
ENV PATH="/usr/local/go/bin:${PATH}"

RUN npm install -g jest vitest ava mocha jest-junit \
    && pip3 install pytest pytest-cov nose

RUN node -v && npm -v && python3 -V && go version

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
