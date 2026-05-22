FROM debian:12-slim

RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    unzip \
    jq \
    && rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://install.iii.dev/iii/main/install.sh | sh

ENV PATH="/root/.iii/bin:/root/.local/bin:/usr/local/bin:${PATH}"

COPY config.yaml /app/config.yaml

WORKDIR /app

EXPOSE 49134 3111

CMD ["iii", "start", "--config", "/app/config.yaml"]