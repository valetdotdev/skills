#!/usr/bin/env bash
#
# status.sh [--slug NAME] [--all]
#
# Asks the API for a trial's live state. This is the only correct way
# to answer "is it still up" or "when does it expire" — the local token
# store is a cache, and the API response is the source of truth.

source "$(dirname "$0")/common.sh"

SLUG=""; ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --slug) SLUG="$2"; shift 2 ;;
    --all) ALL=1; shift ;;
    -h|--help) sed -n '3,9p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
require_tools

report() {
  local name="$1" token="$2" resp state
  # Through the environment, never `jq --arg`: a process argument is
  # readable from the process list by any other user on the machine.
  resp="$(rpc GetTrialClaim "$(VALET_CLAIM_TOKEN="$token" jq -n \
    '{claimToken:env.VALET_CLAIM_TOKEN}')" 2>/dev/null || true)"
  if [ -z "$resp" ]; then
    printf '%-28s %s\n' "$name" "unknown (token rejected)"
    return
  fi
  state="$(printf '%s' "$resp" | jq -r '.state // "unknown"' | sed 's/^TRIAL_CLAIM_STATE_//' | tr 'A-Z' 'a-z')"
  printf '%-28s %-10s %s\n' "$name" "$state" \
    "$(printf '%s' "$resp" | jq -r 'if .claimedUrl != "" and .claimedUrl != null then .claimedUrl else (.url + "  expires " + (.expiresAt // "?")) end')"
  # Prune what the server says is gone; keeping it would make the
  # store lie about what exists.
  case "$state" in expired|reaped|deleted) forget_trial "$name" ;; esac
}

if [ "$ALL" = "1" ]; then
  [ -f "$TRIALS_FILE" ] || { echo "no trials published from this machine" >&2; exit 0; }
  while IFS=$'\t' read -r n t; do report "$n" "$t"; done < <(
    jq -r 'to_entries[] | [.key, .value.claimToken] | @tsv' "$TRIALS_FILE")
  exit 0
fi

[ -n "$SLUG" ] || SLUG="$(read_link_name)"
[ -n "$SLUG" ] || die "no site given and this directory is not linked; pass --slug or --all"
TOKEN="$(read_token "$SLUG")"
[ -n "$TOKEN" ] || die "no claim token for $SLUG in $TRIALS_FILE"
report "$SLUG" "$TOKEN"
