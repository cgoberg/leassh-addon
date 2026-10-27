# Local-build variant (supervisor builds on device). The multi-arch CI
# image (private GHCR until visibility flips) copies a prebuilt binary
# into rootfs/usr/local/bin instead; both paths ship the same artifact.
ARG BUILD_FROM=debian:bookworm-slim
FROM ${BUILD_FROM}
ARG TARGETARCH
ARG LEASSH_VERSION=0.2.0
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates bash curl xz-utils \
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
        "https://github.com/cgoberg/leassh/releases/download/v${LEASSH_VERSION}/${ASSET}.tar.gz" \
      && tar xzf /tmp/leassh.tar.gz -C /tmp \
      && find /tmp -name leassh -type f -exec cp {} /usr/local/bin/leassh \; \
      && chmod a+x /usr/local/bin/leassh \
      && rm -rf /tmp/leassh*; \
    fi
CMD [ "/run.sh" ]
