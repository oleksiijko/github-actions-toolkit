FROM node:18-slim

WORKDIR /app

COPY entrypoint.sh /entrypoint.sh
COPY utils /app/utils
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
