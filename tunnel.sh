#!/bin/sh

if ! test -n "$TAILNET_ID"; then
  echo 'TAILNET_ID missing (e. g. tail123456)' 1>&2
  exit 1
fi
if ! test -n "$TAILSCALE_SERVICE"; then
  echo 'TAILSCALE_SERVICE missing' 1>&2
  exit 1
fi
if ! test -n "$TAILSCALE_AUTHKEY" && ! test -f "/run/secrets/TAILSCALE_AUTHKEY"; then
  echo 'TAILSCALE_AUHTKEY missing' 1>&2
  exit 1
fi

TAILSCALE_SERVICE_HOST="$TAILSCALE_SERVICE.$TAILNET_ID.ts.net"
TAILSCALE_HOSTNAME="${TAILSCALE_HOSTNAME:-$TAILSCALE_SERVICE-tunnel}"
LOCAL_PORT="${LOCAL_PORT:-80}"
REMOTE_PORT="${REMOTE_PORT:-80}"
test -n "$TAILSCALE_AUTHKEY" \
  || TAILSCALE_AUTHKEY="$(cat /run/secrets/TAILSCALE_AUTHKEY)"

trap 'kill -TERM $PID' TERM INT

echo "Starting Tailscale daemon"
tailscaled --tun=userspace-networking --socks5-server=127.0.0.1:1080 --state=mem: --no-logs-no-support &
PID=$!

echo "Authenticating to Tailscale as $TAILSCALE_HOSTNAME"
until tailscale up --authkey="$TAILSCALE_AUTHKEY" --hostname="$TAILSCALE_HOSTNAME"; do
    sleep 0.1
done

tailscale status

echo "Forwarding TCP traffic from :$LOCAL_PORT to $TAILSCALE_SERVICE_HOST:$REMOTE_PORT via Tailscale"
socat "tcp-listen:$LOCAL_PORT,fork,reuseaddr" "SOCKS5:127.0.0.1:$TAILSCALE_SERVICE_HOST:$REMOTE_PORT,socksport=1080" &

wait ${PID}
wait ${PID}
