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
| `license_token` | Online `LSH-…` key or offline `LSH1.…` token. Free covers 2 nodes, Home Assistant, sensors, presence, notify, Assist, basic alerts and one `ha` token. Family 10, Pro 25, Unlimited contact. Get a Free key at <https://leassh.com/setup>. |
| `api_listen_port` | HTTP+WS API port (default 8790) |
| `nodes` | Fleet node list (name/host/ssh/os, optional reclamation opt-ins) |
| `auto_install_integration` | Keep the co-located integration installed (default on) |

## Free, Family, Pro and Home Assistant

Home Assistant is included on **every** plan, including Free.

- **Free:** 2 nodes, local dashboard, HA integration, sensors, binary sensors,
  presence, curated buttons, notify, Assist, basic alerts, exactly one `ha`
  API token. No card required.
- **Family:** 10 nodes, plus AI screen analysis, weekly reports, screen time,
  limits/enforcement, content alerts, and Telegram/email channels.
- **Pro:** 25 nodes, plus fleet dashboard, rules, webhooks, MQTT, SSH actuation,
  full REST API and OpenClaw.
- **Unlimited:** unlimited nodes, priority support, multi-site onboarding.

Using Home Assistant and OpenClaw at the same time requires Family or Pro
because Free carries one API token. A third node on Free is rejected with
`NODE_LIMIT_REACHED`; existing nodes keep reporting if a downgrade leaves the
fleet over the limit.

The add-on writes its working directory to `/config/leassh`, so
`data/license_cache.json` and `screen_time_data.json` survive restarts. It
generates exactly one `ha` API token and keeps it stable across restarts.

## Closed-tier boundary

This public repository and its images carry **no closed-tier assets**.
`scripts/exclude-check.sh` runs in every packaging step and fails the
build on any violation.

## Support

Issues: https://github.com/cgoberg/leassh-addon/issues ·
Integration: https://github.com/cgoberg/leassh-integration ·
Docs: https://leassh.com
