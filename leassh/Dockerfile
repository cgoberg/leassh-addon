# Built by Supervisor on device when a prebuilt CI image is not configured.
#
# Base is the Home Assistant app base. run.sh depends on bashio and
# with-contenv, which only exist there — an earlier Debian base could not
# have worked at runtime.
#
# build.yaml is deprecated and, on current Supervisor, not read at all: the
# builder silently fell back to this same base while the Dockerfile still
# assumed Debian, so `apt-get` failed with exit 127. The parameters now live
# here, which is what the deprecation asks for.
ARG BUILD_FROM=ghcr.io/home-assistant/base:latest
FROM ${BUILD_FROM}

ARG TARGETARCH
ARG LEASSH_VERSION=0.2.0

RUN apk add --no-cache ca-certificates bash curl xz

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
