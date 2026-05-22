FROM node:20-slim

WORKDIR /app

COPY workers/caller-worker/package*.json ./
RUN npm install

COPY workers/caller-worker/ .
RUN npm run build

ENV III_URL=ws://localhost:49134

CMD ["node", "dist/worker.js"]