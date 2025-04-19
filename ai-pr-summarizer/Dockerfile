FROM node:16

WORKDIR /github/workspace

RUN apt-get update && apt-get install -y jq

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
