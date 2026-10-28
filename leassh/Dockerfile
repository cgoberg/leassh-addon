# Debian bookworm: the release binaries are built on Ubuntu 22.04 and
# require glibc 2.35, which bookworm's 2.36 satisfies. The build verifies
# the version pin below and the integration manifest.
FROM debian:bookworm-slim

ARG TARGETARCH
ARG LEASSH_VERSION=0.2.1
# The HA integration is fetched from its own repository at a pinned tag.
# It used to be committed under rootfs/opt/leassh-integration, where it
# silently rotted at 0.1.0 while the integration repo was at 0.3.2.
ARG INTEGRATION_VERSION=0.3.6

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y --no-install-recommends \
      ca-certificates bash curl xz-utils jq \
    && rm -rf /var/lib/apt/lists/*

COPY rootfs /

RUN curl -fsSL -o /tmp/integration.tar.gz \
      "https://github.com/cgoberg/leassh-integration/archive/refs/tags/v${INTEGRATION_VERSION}.tar.gz" \
 && mkdir -p /opt/leassh-integration \
 && tar xzf /tmp/integration.tar.gz -C /tmp \
 && cp -r "/tmp/leassh-integration-${INTEGRATION_VERSION}/custom_components/leassh/." /opt/leassh-integration/ \
 && rm -rf /tmp/integration.tar.gz "/tmp/leassh-integration-${INTEGRATION_VERSION}" \
 && jq -e --arg v "$INTEGRATION_VERSION" '.version == $v' /opt/leassh-integration/manifest.json >/dev/null

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
