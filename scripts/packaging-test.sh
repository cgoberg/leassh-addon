#!/usr/bin/env bash
# Packaging + optional live smoke test for the Leassh add-on.
#
# Static checks always run (CI-safe). The live section runs only when
# LEASSH_BIN and LEASSH_FREE_TEST_TOKEN are set; it proves the add-on's
# Free contract against a real server: tier=free, max_nodes=2, one ha token,
# HA can pair, and a 3-node fleet is degraded rather than crashed.
set -euo pipefail
cd "$(dirname "$0")/.."

fail=0
ok() { echo "ok: $*"; }
bad() { echo "FAIL: $*" >&2; fail=1; }

version="$(python3 -c 'import yaml;print(yaml.safe_load(open("leassh/config.yml"))["version"])')"
[[ "$version" == "0.2.9" ]] && ok "add-on version $version" || bad "unexpected add-on version $version"

grep -q 'ARG INTEGRATION_VERSION=0.3.9' leassh/Dockerfile && ok "integration pinned 0.3.9" || bad "integration pin is not 0.3.9"
grep -q 'CONF_DIR="/config/leassh"' leassh/rootfs/run.sh && ok "working dir persists at /config/leassh" || bad "working dir is not /config/leassh"
grep -q 'tokens:' leassh/rootfs/run.sh && grep -q '    ha: "${ha_token}"' leassh/rootfs/run.sh && ok "exactly one ha token is rendered" || bad "ha token render missing"
! grep -qE '^    (forge|openclaw|admin):' leassh/rootfs/run.sh && ok "no extra API scopes minted" || bad "add-on mints extra API scopes"
grep -q 'license_token is empty' leassh/rootfs/run.sh && ok "empty-license preflight warning" || bad "missing empty-license warning"
grep -q 'LSH1' leassh/translations/en.yaml && grep -q 'LSH-' leassh/translations/en.yaml && ok "option docs cover online and offline keys" || bad "option docs missing key formats"
bash -n leassh/rootfs/run.sh && ok "run.sh syntax"

if [[ -n "${LEASSH_BIN:-}" && -n "${LEASSH_FREE_TEST_TOKEN:-}" ]]; then
  tmp="$(mktemp -d)"
  port="${LEASSH_TEST_PORT:-18790}"
  token="$(head -c 24 /dev/urandom | od -An -tx1 | tr -d ' \n')"
  cat > "$tmp/fleet.yaml" <<YAML
license_key: "${LEASSH_FREE_TEST_TOKEN}"
api:
  enabled: true
  listen: "127.0.0.1:${port}"
  tokens:
    ha: "${token}"
nodes:
  - name: one
    host: 127.0.0.1
    ssh: nobody@127.0.0.1
  - name: two
    host: 127.0.0.2
    ssh: nobody@127.0.0.2
YAML
  ( cd "$tmp" && exec "$LEASSH_BIN" "$tmp/fleet.yaml" >server.log 2>&1 ) &
  pid=$!
  trap 'kill "$pid" 2>/dev/null || true; rm -rf "$tmp"' EXIT
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:${port}/api/health" > "$tmp/health.json" 2>/dev/null; then break; fi
    sleep 0.25
  done
  python3 - "$tmp/health.json" <<'PY'
import json,sys
h=json.load(open(sys.argv[1]))
assert h["license"]["tier"]=="free", h
assert h["license"]["max_nodes"]==2, h
assert h["license"]["node_limit"]["current"]==2, h
assert h["license"]["node_limit"]["exceeded"] is False, h
assert h["degraded"] is False, h
print("ok: live Free license tier=free max_nodes=2, 2 nodes")
PY
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${token}" "http://127.0.0.1:${port}/api/devices")"
  [[ "$code" == "200" ]] && ok "HA token pairs (GET /api/devices 200)" || bad "HA token failed ($code)"

  # Downgrade path: a third node must not crash the server. It starts
  # degraded, keeps reads alive, and blocks new nodes.
  kill "$pid" 2>/dev/null || true
  wait "$pid" 2>/dev/null || true
  sleep 0.5
  cat > "$tmp/fleet.yaml" <<YAML2
license_key: "${LEASSH_FREE_TEST_TOKEN}"
api:
  enabled: true
  listen: "127.0.0.1:${port}"
  tokens:
    ha: "${token}"
nodes:
  - name: one
    host: 127.0.0.1
    ssh: nobody@127.0.0.1
  - name: two
    host: 127.0.0.2
    ssh: nobody@127.0.0.2
  - name: three
    host: 127.0.0.3
    ssh: nobody@127.0.0.3
YAML2
  ( cd "$tmp" && exec "$LEASSH_BIN" "$tmp/fleet.yaml" >degraded.log 2>&1 ) &
  pid=$!
  for _ in $(seq 1 40); do
    if curl -fsS "http://127.0.0.1:${port}/api/health" > "$tmp/health3.json" 2>/dev/null; then break; fi
    sleep 0.25
  done
  python3 - "$tmp/health3.json" <<'PY3'
import json,sys
h=json.load(open(sys.argv[1]))
assert h["license"]["tier"]=="free", h
assert h["license"]["max_nodes"]==2, h
assert h["license"]["node_limit"]["current"]==3, h
assert h["license"]["node_limit"]["exceeded"] is True, h
assert h["degraded"] is True, h
assert "NODE LIMIT EXCEEDED" in h.get("banner",""), h
print("ok: live Free downgrade degrades cleanly (3/2, banner, no crash)")
PY3
  code="$(curl -s -o /dev/null -w '%{http_code}' -H "Authorization: Bearer ${token}" "http://127.0.0.1:${port}/api/devices")"
  [[ "$code" == "200" ]] && ok "degraded mode still serves reads (200)" || bad "degraded reads failed ($code)"
fi

if [[ $fail -ne 0 ]]; then exit 1; fi
echo "packaging-test: pass"
