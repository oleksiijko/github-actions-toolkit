FROM ubuntu:22.04

RUN apt-get update && apt-get install -y \
    curl \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    openjdk-11-jdk \
    && rm -rf /var/lib/apt/lists/*

# Install test frameworks and runners
RUN npm install -g jest mocha && \
    pip3 install pytest pytest-cov && \
    npm install -g mocha && \
    go install gotest.tools/gotestsum@latest && \
    npm install -g junit-xml

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
