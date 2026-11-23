# AxonHub for Railway: official image pinned by version and digest.
FROM looplj/axonhub:v1.0.0-rc.4@sha256:86b5be6baf7517c7574976ed9c319ba1e6cea2c9a07bd749c678757ad2dfe6ed

COPY start.sh /usr/local/bin/axonhub-start
RUN chmod 0755 /usr/local/bin/axonhub-start

EXPOSE 8090
ENTRYPOINT ["/usr/local/bin/axonhub-start"]
