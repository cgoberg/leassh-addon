# Debian base, deliberately hardcoded.
#
# The release binaries are dynamically linked against glibc
# (/lib64/ld-linux-x86-64.so.2). Supervisor injects
# BUILD_FROM=ghcr.io/home-assistant/base:latest when no build config is read,
# and that base is Alpine/musl, where the binary fails with
# "cannot execute: required file not found". Ignoring BUILD_FROM keeps the
# glibc runtime the binary actually needs.
#
# This also means bashio is unavailable, so run.sh uses jq on
# /data/options.json instead. build.yaml is deprecated and not read by
# current Supervisor; its parameters live here now.
FROM debian:bookworm-slim

ARG TARGETARCH
ARG LEASSH_VERSION=0.2.0

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates bash curl xz-utils jq \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /

RUN chmod a+x /run.sh \
 && mkdir -p /usr/local/bin \
 && if [ ! -x /usr/local/bin/leassh ]; then \
      case "$TARGETARCH" in \
        amd64) ASSET=leassh-server-linux-x64 ;; \
        arm64) ASSET=leassh-server-linux-arm64 ;; \
        *) echo "unsupported arch $TARGETARCH"; exit 1 ;; \
      esac; \
      curl -fsSL -o /tmp/leassh.tar.gz \
        "https://github.com/cgoberg/releases/releases/download/v${LEASSH_VERSION}/${ASSET}.tar.gz" \
      && tar xzf /tmp/leassh.tar.gz -C /tmp \
      && find /tmp -name leassh -type f -exec cp {} /usr/local/bin/leassh \; \
      && chmod a+x /usr/local/bin/leassh \
      && rm -rf /tmp/leassh*; \
    fi

CMD [ "/run.sh" ]
