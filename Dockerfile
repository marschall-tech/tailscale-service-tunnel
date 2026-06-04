ARG TAILSCALE_VERSION=stable
ARG SOCAT_VERSION=latest

FROM tailscale/tailscale:${TAILSCALE_VERSION} AS tailscale
FROM alpine/socat:${SOCAT_VERSION} AS socat


FROM alpine AS tunnel

LABEL org.opencontainers.image.title="tailscale-service-tunnel" \
      org.opencontainers.image.authors="marschall.tech <development@marschall.tech>" \
      org.opencontainers.image.source="https://github.com/marschall-tech/tailscale-service-tunnel" \
      org.opencontainers.image.licenses="MIT"

COPY --from=tailscale /usr/local/bin/tailscaled /usr/local/bin/tailscaled
COPY --from=tailscale /usr/local/bin/tailscale /usr/local/bin/tailscale

RUN apk -U --no-cache upgrade \
    && apk --no-cache add socat

WORKDIR /srv

ADD tunnel.sh /srv/tunnel.sh
ENTRYPOINT ["/srv/tunnel.sh"]

HEALTHCHECK --start-period=1s --start-interval=1s \
  CMD ps ax | grep -q socat
