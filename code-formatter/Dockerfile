FROM node:16

RUN apt-get update && apt-get install -y git python3-pip curl

COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
