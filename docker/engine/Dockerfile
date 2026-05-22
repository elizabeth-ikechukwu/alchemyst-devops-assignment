FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://install.iii.dev | sh

COPY config.yaml /app/config.yaml

WORKDIR /app

EXPOSE 49134 3111

CMD ["iii", "--config", "config.yaml"]