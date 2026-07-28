# Shared helpers for the valet-publish scripts. Sourced, not executed.
#
# Two pieces of local state, deliberately in different places:
#
#   .valet/config.json          the link, in the published directory.
#                               This is the Valet CLI's own file, so a
#                               directory published by this skill is
#                               already linked the moment someone
#                               installs the CLI. It is meant to be
#                               committed.
#
#   $VALET_CONFIG_DIR/trials.json   claim tokens, mode 0600, next to
#                               the CLI's credentials.json. A claim
#                               token authorizes republishing and
#                               deleting, so it must never land in a
#                               directory whose whole point is to be
#                               committed.

set -euo pipefail

API_BASE="${VALET_API_URL:-https://api.valet.dev}"
RPC="$API_BASE/valet.api.v1.APIService"
CONFIG_DIR="${VALET_CONFIG_DIR:-$HOME/.config/valet}"
TRIALS_FILE="$CONFIG_DIR/trials.json"

die() { echo "error: $*" >&2; exit 1; }

require_tools() {
  local missing=()
  command -v curl >/dev/null 2>&1 || missing+=(curl)
  command -v jq >/dev/null 2>&1 || missing+=(jq)
  if ! command -v sha256sum >/dev/null 2>&1 && ! command -v shasum >/dev/null 2>&1; then
    missing+=("sha256sum or shasum")
  fi
  [ ${#missing[@]} -eq 0 ] || die "missing required tools: ${missing[*]}"
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | cut -d' ' -f1
  else
    shasum -a 256 "$1" | cut -d' ' -f1
  fi
}

# rpc <Method> <json-body> — every trial procedure is a public unary
# ConnectRPC call, so this needs no authorization header. The claim
# token in the body is the only credential.
rpc() {
  local method="$1" body="$2" out code
  out="$(curl -sS -X POST "$RPC/$method" \
    -H 'Content-Type: application/json' \
    -H "X-Valet-Client: ${VALET_CLIENT:-valet-publish}" \
    -d "$body" -w '\n%{http_code}')" || die "$method: request failed"
  code="$(printf '%s' "$out" | tail -n1)"
  body="$(printf '%s' "$out" | sed '$d')"
  if [ "$code" != "200" ]; then
    local msg
    msg="$(printf '%s' "$body" | jq -r '.message // empty' 2>/dev/null || true)"
    die "${msg:-$method failed with HTTP $code}"
  fi
  printf '%s' "$body"
}

# Local state. Reads tolerate a missing or malformed file: the API
# response is always the source of truth for state and expiry, and a
# corrupt cache should not block a publish.
read_link_org()  { jq -r '.org   // empty' .valet/config.json 2>/dev/null || true; }
read_link_name() { jq -r '.agent // empty' .valet/config.json 2>/dev/null || true; }

write_link() {
  mkdir -p .valet
  jq -n --arg a "$1" --arg o "$2" \
    '{version:1, agent:$a, org:$o}' > .valet/config.json
}

read_token() {
  [ -f "$TRIALS_FILE" ] || return 0
  jq -r --arg n "$1" '.[$n].claimToken // empty' "$TRIALS_FILE" 2>/dev/null || true
}

save_trial() {
  local name="$1" token="$2" url="$3" claim_url="$4" expires="$5" dir="$6"
  mkdir -p "$CONFIG_DIR"; chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  local existing='{}'
  [ -f "$TRIALS_FILE" ] && existing="$(cat "$TRIALS_FILE" 2>/dev/null || echo '{}')"
  printf '%s' "$existing" | jq \
    --arg n "$name" --arg t "$token" --arg u "$url" \
    --arg c "$claim_url" --arg e "$expires" --arg d "$dir" \
    '.[$n] = {claimToken:$t, url:$u, claimUrl:$c, expiresAt:$e, dir:$d}' \
    > "$TRIALS_FILE.tmp"
  mv "$TRIALS_FILE.tmp" "$TRIALS_FILE"
  chmod 600 "$TRIALS_FILE"
}

forget_trial() {
  [ -f "$TRIALS_FILE" ] || return 0
  jq --arg n "$1" 'del(.[$n])' "$TRIALS_FILE" > "$TRIALS_FILE.tmp"
  mv "$TRIALS_FILE.tmp" "$TRIALS_FILE"
  chmod 600 "$TRIALS_FILE"
}
