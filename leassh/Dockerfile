# Built by the private release pipeline (multi-arch binaries compiled in
# CI and copied in). Local build uses build.yaml against GitHub Releases.
ARG BUILD_FROM=debian:bookworm-slim
FROM ${BUILD_FROM}
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates bash curl \
    && rm -rf /var/lib/apt/lists/*
COPY rootfs /
RUN chmod a+x /run.sh
CMD [ "/run.sh" ]
