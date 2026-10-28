#!/usr/bin/env bash
# Leassh server add-on entrypoint.
# - materializes fleet.yaml from options (persistent under /config/leassh)
# - mints a pairing api token (shown once in the log; reuse if present)
# - optionally installs the co-located HA integration into
#   /config/custom_components/leassh (auto-pairing)
#
# No bashio: this image is Debian (glibc) because the release binaries are
# dynamically linked. Options come from /data/options.json, which Supervisor
# writes for every add-on, read here with jq.
set -euo pipefail

CONF_DIR="/config/leassh"
FLEET="$CONF_DIR/fleet.yaml"
TOKEN_FILE="$CONF_DIR/ha_api_token"
INTEGRATION_SRC="/opt/leassh-integration"
INTEGRATION_DST="/config/custom_components/leassh"
OPTIONS="/data/options.json"

log_info() { echo "[$(date -u +%H:%M:%S)] INFO: $*"; }
log_notice() { echo "[$(date -u +%H:%M:%S)] NOTICE: $*"; }

mkdir -p "$CONF_DIR"

opt() { jq -r --arg k "$1" '.[$k] // empty' "$OPTIONS"; }

license_token="$(opt license_token)"
listen_port="$(opt api_listen_port)"
auto_integration="$(opt auto_install_integration)"

# --- pairing token: mint once, keep stable across restarts ---------------
if [[ ! -s "$TOKEN_FILE" ]]; then
  head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$TOKEN_FILE"
  chmod 600 "$TOKEN_FILE"
fi
ha_token="$(cat "$TOKEN_FILE")"

if [[ -z "$license_token" ]]; then
  log_notice "WARNING: license_token is empty. Get a Free key (2 nodes, Home Assistant included) at https://leassh.com/setup, then paste it here. The server will reject an empty license."
fi

# --- fleet.yaml from options ----------------------------------------------
nodes_block="$(jq -r '
  (.nodes // [])[]
  | "  - name: \(.name)\n    host: \(.host)\n    ssh: \(.ssh)\n    os: \(.os // "linux")\n"
' "$OPTIONS")"

cat > "$FLEET" <<EOF
license_key: "${license_token}"
api:
  enabled: true
  listen: "0.0.0.0:${listen_port}"
  tokens:
    ha: "${ha_token}"
nodes:
${nodes_block:-  []}
EOF
chmod 600 "$FLEET"

# --- auto-pairing: install or update the vendored integration ------------
# The integration is fetched at image build time (pinned tag), so the copy
# here is authoritative. Compare versions instead of only checking presence:
# an old install must be replaced, otherwise an upgrade keeps running stale
# code forever.
integration_version() {
  jq -r '.version // "unknown"' "$1/manifest.json" 2>/dev/null || echo unknown
}

if [[ "$auto_integration" == "true" && -d "$INTEGRATION_SRC" ]]; then
  mkdir -p /config/custom_components
  src_ver="$(integration_version "$INTEGRATION_SRC")"
  dst_ver=""
  [[ -f "$INTEGRATION_DST/manifest.json" ]] && dst_ver="$(integration_version "$INTEGRATION_DST")"
  if [[ "$src_ver" != "$dst_ver" ]]; then
    rm -rf "$INTEGRATION_DST"
    cp -r "$INTEGRATION_SRC" "$INTEGRATION_DST"
    log_info "Leassh HA integration ${dst_ver:-absent} -> ${src_ver} in custom_components; restart Home Assistant to load it, then pair with this token."
  else
    log_info "Leassh HA integration ${src_ver} already current in custom_components"
  fi
fi

log_info "Leassh server starting on port ${listen_port} (mDNS _leassh._tcp advertised)"
log_notice "HA pairing token: ${ha_token}"
log_info "Free plan: 2 nodes, local dashboard, Home Assistant, one ha token. Paid plans: Family 10, Pro 25, Unlimited contact."
log_info "Working directory persists at ${CONF_DIR} (license cache and screen-time data survive restarts)."

exec /usr/local/bin/leassh "$FLEET"
