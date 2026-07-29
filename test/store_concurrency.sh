#!/usr/bin/env bash
#
# store_concurrency.sh — the trials.json token store survives
# concurrent writers.
#
# A claim token is minted exactly once and is the only authority to
# update, delete, or claim a live public site, so a lost write is an
# immortal site nobody can take down. Two agents publishing at once is
# an ordinary thing to ask this skill for, and the store is one JSON
# object rewritten whole, so the store's locking is the thing that has
# to be tested rather than assumed.
#
#   valet-skills/test/store_concurrency.sh
#
# Nothing here touches the network or the real config directory: it
# sources scripts/common.sh with VALET_CONFIG_DIR pointed at a
# temporary directory. Point VALET_PUBLISH_COMMON at another copy of
# common.sh to watch a version without the lock fail this.

set -euo pipefail

COMMON="${VALET_PUBLISH_COMMON:-$(cd "$(dirname "$0")/../skills/valet-publish/scripts" && pwd)/common.sh}"
WRITERS="${WRITERS:-24}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT
export VALET_CONFIG_DIR="$WORK/config"
STORE="$VALET_CONFIG_DIR/trials.json"

FAILED=0
check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected [$2], got [$3]"
    FAILED=1
  fi
}

# BSD and GNU stat spell this differently and neither accepts the
# other's flag.
mode_of() { stat -f '%Lp' "$1" 2>/dev/null || stat -c '%a' "$1" 2>/dev/null || echo "no-such-file"; }

save_one() { # save_one <n>
  bash -c '
    set -euo pipefail
    source "$1"
    save_anon "site-$2" "token-$2" "https://site-$2.try.valet.run" \
      "https://valet.dev/claim/token-$2" "2026-07-30T00:00:00Z" "/tmp/site-$2"
  ' _ "$COMMON" "$1"
}

forget_one() { # forget_one <n>
  bash -c '
    set -euo pipefail
    source "$1"
    forget_anon "site-$2"
  ' _ "$COMMON" "$1"
}

echo "=== $WRITERS concurrent save_anon"
PIDS=()
for i in $(seq 1 "$WRITERS"); do
  save_one "$i" &
  PIDS+=($!)
done
RC=0
for p in "${PIDS[@]}"; do wait "$p" || RC=1; done
check "every writer exited 0" 0 "$RC"
check "store holds every entry" "$WRITERS" "$(jq 'length' "$STORE")"

LOST=0
for i in $(seq 1 "$WRITERS"); do
  [ "$(jq -r --arg n "site-$i" '.[$n].claimToken // "MISSING"' "$STORE")" = "token-$i" ] ||
    LOST=$((LOST + 1))
done
check "every claim token survived" 0 "$LOST"
check "store is mode 0600" 600 "$(mode_of "$STORE")"
check "no lock left behind" 0 "$(find "$VALET_CONFIG_DIR" -maxdepth 1 -name 'trials.json.lock' | wc -l | tr -d ' ')"
check "no staging files left behind" 0 "$(find "$VALET_CONFIG_DIR" -maxdepth 1 -name 'trials.json.??????' | wc -l | tr -d ' ')"

echo "=== concurrent forget_anon over the same store"
PIDS=()
for i in $(seq 1 "$WRITERS"); do
  if [ $((i % 2)) -eq 0 ]; then forget_one "$i" & else save_one "$i" & fi
  PIDS+=($!)
done
RC=0
for p in "${PIDS[@]}"; do wait "$p" || RC=1; done
check "every writer exited 0" 0 "$RC"
check "half the entries remain" $((WRITERS / 2)) "$(jq 'length' "$STORE")"

LOST=0
for i in $(seq 1 "$WRITERS"); do
  if [ $((i % 2)) -eq 0 ]; then continue; fi
  [ "$(jq -r --arg n "site-$i" '.[$n].claimToken // "MISSING"' "$STORE")" = "token-$i" ] ||
    LOST=$((LOST + 1))
done
check "every surviving token is intact" 0 "$LOST"

echo "=== an unreadable store is never overwritten"
printf 'not json at all' > "$STORE"
BEFORE="$(cat "$STORE")"
set +e
save_one 99 >/dev/null 2>&1
SAVE_RC=$?
set -e
check "save_anon refuses" 1 "$SAVE_RC"
check "the damaged store is untouched" "$BEFORE" "$(cat "$STORE")"

set +e
bash -c 'set -euo pipefail; source "$1"; require_store_readable' _ "$COMMON" >/dev/null 2>&1
PREFLIGHT_RC=$?
set -e
check "require_store_readable refuses" 1 "$PREFLIGHT_RC"

echo "=== an empty store is never merged into"
: > "$STORE"
set +e
save_one 98 >/dev/null 2>&1
SAVE_RC=$?
set -e
check "save_anon writes the entry" 0 "$SAVE_RC"
check "the entry is there" "token-98" "$(jq -r '."site-98".claimToken' "$STORE")"

if [ "$FAILED" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILURES"
fi
exit "$FAILED"
