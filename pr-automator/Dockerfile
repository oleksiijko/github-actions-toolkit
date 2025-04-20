FROM python:3.9-slim

RUN apt-get update && apt-get install -y \
    git \
    curl \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN pip install PyGithub gitpython mistletoe

COPY entrypoint.sh /entrypoint.sh
COPY entrypoint.py /entrypoint.py
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
