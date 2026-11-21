FROM debian:bookworm-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
      bash procps lsof coreutils \
    && rm -rf /var/lib/apt/lists/*

COPY agent.sh /usr/local/bin/agent.sh
RUN chmod +x /usr/local/bin/agent.sh

ENTRYPOINT ["/usr/local/bin/agent.sh"]