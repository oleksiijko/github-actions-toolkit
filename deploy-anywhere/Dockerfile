FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y \
    curl \
    wget \
    gnupg \
    lsb-release \
    git \
    python3 \
    python3-pip \
    nodejs \
    npm \
    jq \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install cloud CLIs
RUN pip3 install awscli && \
    curl -sL https://aka.ms/InstallAzureCLIDeb | bash && \
    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-410.0.0-linux-x86_64.tar.gz && \
    tar -xf google-cloud-cli-410.0.0-linux-x86_64.tar.gz && \
    ./google-cloud-sdk/install.sh --quiet && \
    npm install -g vercel netlify-cli

# Copy provider-specific scripts
COPY providers/ /providers/
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh
RUN chmod +x /providers/*.sh

ENTRYPOINT ["/entrypoint.sh"]