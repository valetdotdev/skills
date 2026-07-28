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
#
# The store is written by two programs: these scripts and
# valet-cli/internal/trial/store.go. Read that file before changing
# anything here — the on-disk shape is a contract between them, and
# every safety property this half has is one the Go half already
# states, comments, and tests.

set -euo pipefail

API_BASE="${VALET_API_URL:-https://api.valet.dev}"
RPC="$API_BASE/valet.api.v1.APIService"
CONFIG_DIR="${VALET_CONFIG_DIR:-$HOME/.config/valet}"
TRIALS_FILE="$CONFIG_DIR/trials.json"

# Writing the store is a read-modify-write of one JSON object holding
# every claim token on the machine, and two agents publishing at once
# is an ordinary thing for this skill to be asked to do. The Go twin
# gets atomicity from os.CreateTemp plus rename inside one process;
# the shell needs a lock as well, because two jq pipelines that both
# read before either writes lose one of the two tokens outright — and
# a claim token is minted exactly once, so what is lost is the only
# authority to update, delete, or claim a live public site.
#
# mkdir is the lock: it is an atomic test-and-set on every POSIX
# filesystem and needs no flock(1), which macOS does not ship.
LOCK_DIR="$TRIALS_FILE.lock"
LOCK_HELD=0
# How long to wait for another publish's write. The critical section
# is one jq and one rename, so a wait this long means something is
# broken rather than busy.
LOCK_WAIT_SECS=10
# How old a lock has to be before it is treated as abandoned. See
# break_stale_lock.
LOCK_STALE_MINS=1

# Temporary files to remove on the way out, whatever the exit path.
# Scripts add to this rather than installing their own EXIT trap: bash
# keeps one trap per signal, so a second `trap ... EXIT` anywhere would
# silently replace the lock release below.
TMPFILES=()

die() { echo "error: $*" >&2; exit 1; }

cleanup_on_exit() {
  if [ ${#TMPFILES[@]} -gt 0 ]; then
    rm -f "${TMPFILES[@]}"
  fi
  unlock_store
  return 0
}

# mktemp_tracked [template] — creates a temporary file and registers it
# for removal on exit. The path comes back in LAST_TMPFILE rather than
# on stdout because `$(mktemp_tracked)` would run the function in a
# subshell, where the append to TMPFILES happens to a copy and the file
# is never cleaned up.
LAST_TMPFILE=""
mktemp_tracked() {
  LAST_TMPFILE="$(mktemp "$@")" || die "could not create a temporary file"
  TMPFILES+=("$LAST_TMPFILE")
}

# lock_store takes the store lock, waiting for a concurrent writer.
lock_store() {
  local deadline=$((SECONDS + LOCK_WAIT_SECS))
  mkdir -p "$CONFIG_DIR" || die "could not create $CONFIG_DIR"
  # 0700 first: mkdir -p made it at whatever the umask allows, and it
  # is about to hold every claim token on the machine. A directory we
  # own but cannot write is also reopened by this, which is the right
  # trade when the alternative is dropping a token.
  chmod 700 "$CONFIG_DIR" 2>/dev/null || true
  # Then asked directly, because a failing mkdir cannot say whether it
  # lost a race or hit a directory belonging to someone else — and
  # spending the whole wait on the second one would report contention
  # that never existed.
  [ -w "$CONFIG_DIR" ] || die "$CONFIG_DIR is not writable, so the claim token store cannot be updated"
  while ! mkdir "$LOCK_DIR" 2>/dev/null; do
    break_stale_lock
    if [ "$SECONDS" -ge "$deadline" ]; then
      die "timed out after ${LOCK_WAIT_SECS}s waiting for $LOCK_DIR. Another publish may still be writing the token store; if none is running, remove that directory."
    fi
    # Fractional sleep where the system has one. busybox's does not,
    # and a whole second of backoff is still correct, only slower.
    sleep 0.1 2>/dev/null || sleep 1
  done
  LOCK_HELD=1
}

# break_stale_lock removes a lock left behind by a script that died
# between mkdir and rmdir, which would otherwise wedge every later
# publish on this machine. The critical section is one jq and one
# rename — milliseconds — so a minute of slack is four orders of
# magnitude of headroom before this can steal a live lock. `find
# -mmin` reads the directory's age without GNU stat's non-portable -c.
break_stale_lock() {
  local doomed
  [ -d "$LOCK_DIR" ] || return 0
  [ -n "$(find "$LOCK_DIR" -maxdepth 0 -mmin "+$LOCK_STALE_MINS" 2>/dev/null)" ] || return 0
  # Renamed and then removed, rather than removed in place: rename is
  # atomic, so exactly one waiter breaks a given lock and the others
  # find it already gone. Two waiters both calling rmdir could
  # otherwise delete the lock a third had taken in between.
  doomed="$LOCK_DIR.stale.$$"
  if mv "$LOCK_DIR" "$doomed" 2>/dev/null; then
    rmdir "$doomed" 2>/dev/null || rm -rf "$doomed" 2>/dev/null || true
  fi
}

# unlock_store releases the lock, and only ever the one this process
# took: a caller that timed out waiting must not remove the lock the
# winner is still working under.
unlock_store() {
  if [ "$LOCK_HELD" = "1" ]; then
    LOCK_HELD=0
    rmdir "$LOCK_DIR" 2>/dev/null || true
  fi
}

# Installed after the functions they call, so a failure while this
# file is still being sourced does not run a trap that is not defined
# yet. A killed script must release the lock too: bash runs the EXIT
# trap for a signal only when that signal is trapped. Each handler
# exits with the conventional 128+signal status, which runs the EXIT
# trap once more — cleanup is idempotent.
trap cleanup_on_exit EXIT
trap 'cleanup_on_exit; exit 130' INT
trap 'cleanup_on_exit; exit 143' TERM
trap 'cleanup_on_exit; exit 129' HUP

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
# token in the body is the only credential, which is why the body goes
# in over stdin rather than as `-d <body>`: a process argument is
# readable from the process list by every other user on the machine,
# and the token is a bearer credential for a live public site.
rpc() {
  local method="$1" body="$2" out code
  out="$(printf '%s' "$body" | curl -sS -X POST "$RPC/$method" \
    -H 'Content-Type: application/json' \
    -H "X-Valet-Client: ${VALET_CLIENT:-valet-publish}" \
    --data-binary @- -w '\n%{http_code}')" || die "$method: request failed"
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
# corrupt cache should not block a publish. They take no lock — a
# writer installs the store by rename, so a reader sees either the
# whole old file or the whole new one.
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

# require_store_readable refuses to go on when the store exists but is
# not a JSON object.
#
# A publish discovers this either before it starts or after it has
# minted a claim token the server returns exactly once — and there is
# nowhere to put that token if the merge cannot happen. So the check
# runs first. It never repairs or replaces the file: it holds every
# other trial's token, and a wrong guess here is unrecoverable.
require_store_readable() {
  [ -f "$TRIALS_FILE" ] || return 0
  jq -e 'type == "object"' "$TRIALS_FILE" >/dev/null 2>&1 && return 0
  die "$TRIALS_FILE is not a readable JSON object. It holds the claim token for every trial published from this machine — repair it by hand rather than deleting it, because a trial whose token is gone can never be updated, deleted, or claimed."
}

# save_trial records one trial, replacing the store atomically.
#
# The token arrives through the environment rather than through `jq
# --arg` for the same reason rpc() uses stdin: process arguments are
# world-readable, and /proc/<pid>/environ is not.
save_trial() {
  local name="$1" token="$2" url="$3" claim_url="$4" expires="$5" dir="$6"
  local existing tmp
  lock_store
  # A store that exists and cannot be read is not the same fact as no
  # store at all, and merging into `{}` on a failed read would drop
  # every other trial's token. Only an absent or empty file starts
  # from nothing.
  existing='{}'
  if [ -f "$TRIALS_FILE" ]; then
    existing="$(cat "$TRIALS_FILE" 2>/dev/null)" ||
      die "could not read $TRIALS_FILE. It holds the claim token for every trial published from this machine; the claim token for $name was not saved."
    [ -n "$existing" ] || existing='{}'
  fi
  # A unique name, in the config directory: two concurrent publishes
  # writing one fixed `$TRIALS_FILE.tmp` clobber each other's staging
  # file, and a temp file elsewhere would make the rename a
  # cross-filesystem copy that leaves the tokens readable somewhere
  # world-traversable on the way.
  mktemp_tracked "$TRIALS_FILE.XXXXXX"; tmp="$LAST_TMPFILE"
  # The write is installed only if jq both succeeded and produced
  # something: jq exits 0 on empty input, and the previous version
  # renamed whatever landed in the temp file over the store — so one
  # unreadable byte zeroed every claim token on the machine.
  if ! printf '%s' "$existing" | VALET_CLAIM_TOKEN="$token" jq \
      --arg n "$name" --arg u "$url" \
      --arg c "$claim_url" --arg e "$expires" --arg d "$dir" \
      '.[$n] = {claimToken:env.VALET_CLAIM_TOKEN, url:$u, claimUrl:$c, expiresAt:$e, dir:$d}' \
      > "$tmp" || [ ! -s "$tmp" ]; then
    die "could not write $TRIALS_FILE. The existing store was left untouched, and the claim token for $name was not saved: keep the claim URL printed above, because it is now the only way to update, delete, or claim the site."
  fi
  install_store "$tmp"
}

# forget_trial drops one trial's entry. Same read-modify-write, same
# lock: a status --all pruning three expired trials while a publish
# saves a fourth is the ordinary case, not a corner one.
forget_trial() {
  local name="$1" tmp
  [ -f "$TRIALS_FILE" ] || return 0
  lock_store
  # Re-checked under the lock, because the test above is not.
  if [ ! -f "$TRIALS_FILE" ]; then unlock_store; return 0; fi
  mktemp_tracked "$TRIALS_FILE.XXXXXX"; tmp="$LAST_TMPFILE"
  if ! jq --arg n "$name" 'del(.[$n])' "$TRIALS_FILE" > "$tmp" || [ ! -s "$tmp" ]; then
    die "could not write $TRIALS_FILE while dropping $name. The existing store was left untouched."
  fi
  install_store "$tmp"
}

# install_store publishes a staged store under the real name and
# releases the lock. The caller must hold it.
install_store() {
  local tmp="$1"
  # 0600 before the rename rather than after. mktemp already creates
  # the file that way; saying so here keeps the guarantee stated where
  # the name is published, and the previous version's chmod-after-mv
  # left a file full of live bearer tokens at the umask default —
  # world-readable on most systems — for the width of two syscalls.
  chmod 600 "$tmp" 2>/dev/null || true
  # Flushed before the rename where the platform has a per-file sync,
  # as the Go twin's File.Sync does: a crash that makes the rename
  # durable and the contents not takes every other trial's claim token
  # with it. A bare sync(1) would flush the whole filesystem, which is
  # too blunt to spend on one small file, so on macOS and busybox —
  # where `sync <file>` does not exist — this is a no-op and that
  # window stands.
  sync "$tmp" 2>/dev/null || true
  mv "$tmp" "$TRIALS_FILE"
  unlock_store
}
