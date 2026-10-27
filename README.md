# Leassh Home Assistant Add-on

The [Leassh](https://leassh.com) server — SSH fleet monitoring and family
safety — packaged as a Home Assistant OS add-on. This is the
single-box tier: one click for homes without a separate server machine.

**Pairing is automatic by design:**

1. Add this repository in *Settings → Add-ons → Add-on Store → ⋮ →
   Repositories* (`https://github.com/cgoberg/leassh-addon`).
2. Install **Leassh**, open its configuration, set your license token and
   nodes.
3. Start it. The add-on:
   - runs the Leassh server on port 8790 (host network),
   - advertises `_leassh._tcp` via mDNS,
   - **installs the Leassh integration** into `custom_components` for you,
   - prints a pairing token in its log (also kept in `/config/leassh/`).
4. *Settings → Devices & Services → Add Integration → **Leassh*** — it
   discovers the co-located server (`http://localhost:8790`); paste the
   pairing token. Devices appear.

No shell, no YAML editing on the host.

## Options

| Option | Meaning |
|---|---|
| `license_token` | Offline license token (LSH1.…). Free tier: 2 nodes. |
| `api_listen_port` | HTTP+WS API port (default 8790) |
| `nodes` | Fleet node list (name/host/ssh/os, optional reclamation opt-ins) |
| `auto_install_integration` | Keep the co-located integration installed (default on) |

## Closed-tier boundary

This public repository and its images carry **no closed-tier assets**.
`scripts/exclude-check.sh` runs in every packaging step and fails the
build on any violation. The free tier includes monitoring, sensors,
basic actions, Assist exposure, notifications, and one API token.

## Support

Issues: https://github.com/cgoberg/leassh-addon/issues ·
Integration: https://github.com/cgoberg/leassh-hacs ·
Docs: https://leassh.com
