#!/usr/bin/env bash
# QA-3 (owner, 2026-11-20): CI package installs that cannot hang a job. Ubuntu's
# mirror has refused connections (#524) and hung `apt-get update` until the
# 90-minute job limit (#528). Each attempt is capped and retried a few times.
#   tools/ci_retry.sh apt <packages...>   install system packages
#   tools/ci_retry.sh playwright          Chromium and its system libraries
set -uo pipefail
ATTEMPTS=3
LIMIT=300 # seconds per attempt
retry() {
	for attempt in $(seq 1 "$ATTEMPTS"); do
		if timeout --kill-after=20 "$LIMIT" "$@"; then return 0; fi
		echo "ci_retry: attempt $attempt of $ATTEMPTS failed or timed out: $*" >&2
		sleep $((attempt * 10))
	done
	return 1
}
APT=(-o Acquire::Retries=2 -o Acquire::http::Timeout=20 -o Acquire::https::Timeout=20 -o DPkg::Lock::Timeout=60)
case "${1:-}" in
	apt)
		shift
		# A failed index (one mirror down) still leaves the main archive usable.
		retry sudo apt-get update -qq "${APT[@]}" || echo "ci_retry: apt-get update incomplete; installing from the indexes on hand" >&2
		retry sudo apt-get install -y -qq "${APT[@]}" "$@"
		;;
	playwright)
		cd "$(dirname "$0")/../tests/web" || exit 1
		# Chromium first (from Playwright's CDN), then its libraries through apt.
		retry npx playwright install chromium || exit 1
		if ! retry npx playwright install-deps chromium; then
			echo "ci_retry: Chromium's system libraries could not be installed; trying the runner's own" >&2
		fi
		;;
	*)
		echo "usage: tools/ci_retry.sh apt <packages...> | playwright" >&2
		exit 2
		;;
esac
