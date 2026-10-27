#!/usr/bin/with-contenv bashio
# Leassh server add-on entrypoint.
# - materializes fleet.yaml from options (persistent under /config/leassh)
# - mints a pairing api token (shown once in the log; reuse if present)
# - optionally installs the co-located HA integration into
#   /config/custom_components/leassh (auto-pairing)
set -euo pipefail

CONF_DIR="/config/leassh"
FLEET="$CONF_DIR/fleet.yaml"
TOKEN_FILE="$CONF_DIR/ha_api_token"
INTEGRATION_SRC="/opt/leassh-integration"
INTEGRATION_DST="/config/custom_components/leassh"

mkdir -p "$CONF_DIR"

license_token="$(bashio::config 'license_token')"
listen_port="$(bashio::config 'api_listen_port')"
auto_integration="$(bashio::config 'auto_install_integration')"

# --- pairing token: mint once, keep stable across restarts ---------------
if [[ ! -s "$TOKEN_FILE" ]]; then
  head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
fi
ha_token="$(cat "$TOKEN_FILE")"

# --- fleet.yaml from options ----------------------------------------------
nodes_block=""
count=$(bashio::config 'nodes|length')
for ((i = 0; i < count; i++)); do
  name="$(bashio::config "nodes[$i].name")"
  host="$(bashio::config "nodes[$i].host")"
  ssh="$(bashio::config "nodes[$i].ssh")"
  os="$(bashio::config "nodes[$i].os" 2>/dev/null || echo linux)"
  nodes_block+="  - name: ${name}
    host: ${host}
    ssh: ${ssh}
    os: ${os}
"
done

cat > "$FLEET" <<EOF
license_key: "${license_token}"
api:
  enabled: true
  listen: "0.0.0.0:${listen_port}"
  tokens:
    ha: "${ha_token}"
nodes:
${nodes_block:-: []}
EOF
chmod 600 "$FLEET"

# --- auto-pairing: install the co-located integration --------------------
if [[ "$auto_integration" == "true" && -d "$INTEGRATION_SRC" ]]; then
  mkdir -p /config/custom_components
  if [[ ! -d "$INTEGRATION_DST" ]]; then
    cp -r "$INTEGRATION_SRC" "$INTEGRATION_DST"
    bashio::log.info "Leassh HA integration installed to custom_components — add the 'Leassh' integration and pair with this token."
  fi
fi

bashio::log.info "Leassh server starting on port ${listen_port} (mDNS _leassh._tcp advertised)"
bashio::log.notice "HA pairing token: ${ha_token}"

exec /usr/local/bin/leassh "$FLEET"
