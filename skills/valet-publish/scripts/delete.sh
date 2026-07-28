#!/usr/bin/env bash
#
# delete.sh [--slug NAME]
#
# Takes a trial site down immediately. Use this without hesitation when
# someone says they published something by mistake — do not wait for
# the 36-hour expiry.

source "$(dirname "$0")/common.sh"

SLUG=""
while [ $# -gt 0 ]; do
  case "$1" in
    --slug) SLUG="$2"; shift 2 ;;
    -h|--help) sed -n '3,9p' "$0"; exit 0 ;;
    *) die "unknown argument: $1" ;;
  esac
done
require_tools

[ -n "$SLUG" ] || SLUG="$(read_link_name)"
[ -n "$SLUG" ] || die "no site given and this directory is not linked; pass --slug"
TOKEN="$(read_token "$SLUG")"
[ -n "$TOKEN" ] || die "no claim token for $SLUG in $TRIALS_FILE; it cannot be deleted from this machine"

# Through the environment, never `jq --arg`: a process argument is
# readable from the process list by any other user on the machine, and
# this token is what authorizes taking the site down.
rpc DeleteTrialSite "$(VALET_CLAIM_TOKEN="$TOKEN" jq -n \
  '{claimToken:env.VALET_CLAIM_TOKEN}')" >/dev/null
forget_trial "$SLUG"
echo "deleted $SLUG" >&2
