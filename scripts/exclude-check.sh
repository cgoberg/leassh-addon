#!/usr/bin/env bash
# Closed-tier exclude list — MANDATORY gate in every packaging step.
# Fails (exit 1) if any closed-tier asset appears in the artifact context.
set -euo pipefail
CTX="${1:-$(pwd)}"
fail=0
for name in family.html dashboard_users.json screen_time_data.json license_cache.json authorized_agents.json .env; do
  while IFS= read -r hit; do
    echo "EXCLUDE-LIST VIOLATION: $hit" >&2
    fail=1
  done < <(find "$CTX" -name "$name" 2>/dev/null || true)
done
[[ $fail -eq 0 ]] && echo "exclude-list: clean"
exit $fail
