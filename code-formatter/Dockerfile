FROM node:16

RUN apt-get update && apt-get install -y \
    curl \
    jq \
    python3 \
    python3-pip \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install required formatters
RUN npm install -g prettier eslint typescript eslint-config-prettier prettier-eslint \
    && npm install -g google-java-format \
    && npm install -g dotnet-format \
    && curl -L https://github.com/google/google-java-format/releases/download/v1.10.0/google-java-format-1.10.0-all-deps.jar -o google-java-format.jar

# Install Python tools
RUN pip3 install black isort flake8

# Install Go tools
RUN go install golang.org/x/tools/cmd/goimports@latest && \
    wget -qO- https://sh.rustup.rs | sh -s -- -y && \
    ~/.cargo/bin/rustup component add rustfmt

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
