FROM node:18-slim

WORKDIR /app

RUN npm install gh-badges

COPY entrypoint.js /entrypoint.js
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
