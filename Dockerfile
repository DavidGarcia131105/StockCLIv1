FROM ubuntu:24.04

RUN apt-get update && apt-get install -y \
    bash \
    curl \
    jq \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY app/stockcli.sh /app/stockcli.sh

RUN chmod +x /app/stockcli.sh

ENTRYPOINT [ "/app/stockcli.sh" ]