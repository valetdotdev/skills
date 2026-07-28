#!/usr/bin/env bash
#
# publish.sh [dir-or-file] [--include-all] [--client NAME]
#
# Publishes a directory to a live URL with no account. Three steps:
# declare the manifest, upload the objects the server is missing,
# finalize. The site is not live until finalize succeeds, so a partial
# upload never serves.

source "$(dirname "$0")/common.sh"

TARGET="."
INCLUDE_ALL=0
while [ $# -gt 0 ]; do
  case "$1" in
    --include-all) INCLUDE_ALL=1; shift ;;
    --client) VALET_CLIENT="$2"; export VALET_CLIENT; shift 2 ;;
    -h|--help) sed -n '3,10p' "$0"; exit 0 ;;
    -*) die "unknown flag: $1" ;;
    *) TARGET="$1"; shift ;;
  esac
done

require_tools
[ -e "$TARGET" ] || die "no such file or directory: $TARGET"

# A single file publishes as a one-file site rather than as its parent
# directory, so `publish.sh report.pdf` does what it looks like.
SINGLE_FILE=""
if [ -f "$TARGET" ]; then
  SINGLE_FILE="$(basename "$TARGET")"
  TARGET="$(dirname "$TARGET")"
fi
cd "$TARGET"
ROOT="$(pwd)"

# The published URL is public, so the deny list is a correctness
# requirement rather than tidiness. deploysite skips .git/ and .valet/
# when *it* walks a tree, but here the client walks — publishing a
# working tree would otherwise ship git history, and with it every
# credential ever committed and later removed, to a public URL.
is_denied() {
  local p="$1"
  [ "$INCLUDE_ALL" = "1" ] && return 1
  case "$p" in
    .git|.git/*|*/.git|*/.git/*) return 0 ;;
    .valet|.valet/*|*/.valet|*/.valet/*) return 0 ;;
    node_modules|node_modules/*|*/node_modules/*) return 0 ;;
    .env|.env.*|*/.env|*/.env.*) return 0 ;;
    .DS_Store|*/.DS_Store) return 0 ;;
  esac
  # Respect .gitignore when git is available and this is a repo. A file
  # the author already told git to ignore is not one they meant to
  # publish to the open internet.
  if [ -d .git ] && command -v git >/dev/null 2>&1; then
    git check-ignore -q -- "$p" 2>/dev/null && return 0
  fi
  return 1
}

FILES=(); SKIPPED=()
if [ -n "$SINGLE_FILE" ]; then
  # The deny list applies here too. `publish this .env` and `publish
  # this .git/config` are things a user asks for in as many words, and
  # naming a file directly must not be a way past the one guard that
  # stands between a working tree and a public URL.
  if is_denied "$SINGLE_FILE"; then
    die "$SINGLE_FILE is excluded from publishing (.git, .valet, .env*, node_modules, .DS_Store, and .gitignore'd paths). Re-run with --include-all if you really mean to publish it to a public URL."
  fi
  FILES=("$SINGLE_FILE")
else
  # -type f, never -type l: a symlink pointing outside the published
  # directory would otherwise exfiltrate whatever it points at.
  while IFS= read -r -d '' f; do
    rel="${f#./}"
    if is_denied "$rel"; then SKIPPED+=("$rel"); else FILES+=("$rel"); fi
  done < <(find . -type f -print0 | sort -z)
fi
[ ${#FILES[@]} -gt 0 ] || die "nothing to publish in $ROOT"

# Without an index.html the URL would 404 at the root, which is wrong
# for the case this attracts: publish this report, share these charts.
# The generated page is an ordinary file in the site — visible in
# `valet sites download`, editable, and replaced the moment the author
# adds their own index.html.
#
# Filenames are attacker-controlled — a repository takes them from
# whoever contributed the file — and this page is an ordinary uploaded
# object, so it carries none of the gateway viewer's script-free
# Content-Security-Policy. Every interpolation is therefore escaped:
# @html for text, @uri for the href, both via jq, which the script
# already requires.
GENERATED_INDEX=""
if ! printf '%s\n' "${FILES[@]}" | grep -qx "index.html"; then
  GENERATED_INDEX="$(mktemp)"
  cleanup() { [ -n "$GENERATED_INDEX" ] && rm -f "$GENERATED_INDEX"; }
  # Armed the moment the file exists: every `die` between here and the
  # end of the script would otherwise leak it.
  trap cleanup EXIT
  html_escape() { jq -rn --arg s "$1" '$s|@html'; }
  # Per segment, so the path separators survive: @uri over the whole
  # string would encode every `/` and flatten the href.
  uri_escape() { jq -rn --arg s "$1" '$s|split("/")|map(@uri)|join("/")'; }
  {
    printf '<!doctype html><meta charset="utf-8">'
    printf '<meta name="viewport" content="width=device-width,initial-scale=1">'
    printf '<title>%s</title>' "$(html_escape "$(basename "$ROOT")")"
    printf '<style>body{font:16px/1.6 ui-sans-serif,system-ui,sans-serif;'
    printf 'max-width:52rem;margin:3rem auto;padding:0 1.5rem;color:#1C1410;'
    printf 'background:#F4EDE4}h1{font:600 1.4rem/1.2 Georgia,serif}'
    printf 'ul{list-style:none;padding:0}li{padding:.4rem 0;'
    printf 'border-bottom:1px solid rgba(28,20,16,.08)}'
    printf 'a{color:#4878A0;text-decoration:none}a:hover{text-decoration:underline}'
    printf 'code{font-family:ui-monospace,monospace;font-size:.9em}</style>'
    printf '<h1>%s</h1><ul>' "$(html_escape "$(basename "$ROOT")")"
    for f in "${FILES[@]}"; do
      printf '<li><a href="/%s"><code>%s</code></a></li>' \
        "$(uri_escape "$f")" "$(html_escape "$f")"
    done
    printf '</ul>'
  } > "$GENERATED_INDEX"
  FILES+=("index.html")
fi
path_on_disk() {
  if [ "$1" = "index.html" ] && [ -n "$GENERATED_INDEX" ]; then
    printf '%s' "$GENERATED_INDEX"
  else printf '%s' "$1"; fi
}

# Step 1 — declare. Contents never travel over the RPC; the server gets
# paths, hashes, and sizes, and derives content types from the paths.
MANIFEST="$(
  for f in "${FILES[@]}"; do
    d="$(path_on_disk "$f")"
    jq -n --arg p "/$f" --arg s "$(sha256_of "$d")" \
      --argjson z "$(wc -c < "$d" | tr -d ' ')" \
      '{path:$p, sha256:$s, size:$z}'
  done | jq -s .
)"

NAME="$(read_link_name)"; ORG="$(read_link_org)"
TOKEN=""
if [ "$ORG" = "try" ] && [ -n "$NAME" ]; then
  TOKEN="$(read_token "$NAME")"
  [ -n "$TOKEN" ] || die "this directory is a trial site ($NAME) but its claim token is not in $TRIALS_FILE. Without it the trial cannot be updated, deleted, or claimed. Publish a fresh one with --include-all in a new directory, or claim the original from the link you were given."
fi

RESP="$(rpc PublishTrialSite "$(jq -n \
  --argjson f "$MANIFEST" --arg c "${VALET_CLIENT:-valet-publish}" --arg t "$TOKEN" \
  '{files:$f, client:$c, claimToken:$t}')")"

SITE_NAME="$(printf '%s' "$RESP" | jq -r '.siteName')"
URL="$(printf '%s' "$RESP" | jq -r '.url')"
UPLOAD_ID="$(printf '%s' "$RESP" | jq -r '.uploadId')"
EDGE="$(printf '%s' "$RESP" | jq -r '.edgeStatus // "ready"')"
SKIPPED_N="$(printf '%s' "$RESP" | jq -r '.skippedCount // 0')"
N_UP="$(printf '%s' "$RESP" | jq '.uploads // [] | length')"

# Step 2 — upload. Presigned POST, not PUT: the policy carries a
# content-length-range the storage service enforces, which on an
# anonymous endpoint is the whole abuse control. Every field the server
# returned must be submitted before the file part.
[ "$N_UP" -gt 0 ] && echo "uploading $N_UP file(s) ($SKIPPED_N unchanged)..." >&2
for i in $(seq 0 $((N_UP - 1))); do
  [ "$N_UP" -eq 0 ] && break
  up="$(printf '%s' "$RESP" | jq ".uploads[$i]")"
  up_url="$(printf '%s' "$up" | jq -r '.url')"
  up_path="$(printf '%s' "$up" | jq -r '.path')"
  # The response names which paths to upload, and it decides which
  # local file is read. Only a path this client declared is honoured:
  # otherwise a hostile or misconfigured VALET_API_URL asks for
  # `/../../etc/passwd` and gets it. The Go client applies the same
  # guard for the same reason (valet-cli/internal/trial/publish.go).
  declared=0
  for f in "${FILES[@]}"; do
    [ "/$f" = "$up_path" ] && { declared=1; break; }
  done
  [ "$declared" = "1" ] || die "server requested an upload for undeclared path $up_path"
  disk="$(path_on_disk "${up_path#/}")"
  args=()
  # --form-string, never -F: curl reads a leading `@` in an -F value as
  # "upload this local file" and `<` as "inline its contents", so a
  # policy field the server controls would otherwise exfiltrate a file.
  while IFS=$'\t' read -r k v; do args+=(--form-string "$k=$v"); done < <(
    printf '%s' "$up" | jq -r '.fields // {} | to_entries[] | [.key,.value] | @tsv')
  # The quoted-filename form, because curl splits an unquoted @path on
  # commas and reads `;` as the start of a type/filename modifier — so
  # a file named `a,b.txt` or `a;b.txt` otherwise fails the upload.
  code="$(curl -sS -o /dev/null -w '%{http_code}' -X POST "${args[@]}" \
    -F "file=@\"${disk//\"/\\\"}\"" "$up_url")" || die "upload failed for $up_path"
  case "$code" in 2*) ;; *) die "upload failed for $up_path (HTTP $code)" ;; esac
done

# Step 3 — finalize. Nothing serves until this succeeds.
FIN="$(rpc FinalizeTrialSite "$(jq -n --arg t "${TOKEN:-$(printf '%s' "$RESP" | jq -r '.claimToken')}" \
  --arg u "$UPLOAD_ID" '{claimToken:$t, uploadId:$u}')")"
VERSION="$(printf '%s' "$FIN" | jq -r '.version // 1')"
EXPIRES="$(printf '%s' "$FIN" | jq -r '.expiresAt // empty')"

if [ -z "$TOKEN" ]; then
  TOKEN="$(printf '%s' "$RESP" | jq -r '.claimToken')"
  CLAIM_URL="$(printf '%s' "$RESP" | jq -r '.claimUrl')"
  write_link "$SITE_NAME" "try"
  save_trial "$SITE_NAME" "$TOKEN" "$URL" "$CLAIM_URL" "$EXPIRES" "$ROOT"
else
  CLAIM_URL="$(jq -r --arg n "$SITE_NAME" '.[$n].claimUrl // empty' "$TRIALS_FILE" 2>/dev/null || true)"
  save_trial "$SITE_NAME" "$TOKEN" "$URL" "$CLAIM_URL" "$EXPIRES" "$ROOT"
fi

echo "$URL"
# `if`, not `test && echo`: a trailing AND-list whose test fails
# returns 1, and as the script's last statement that made every
# successful publish exit non-zero — reported to the calling agent as a
# failed publish, on the one path that always succeeds.
{
  echo "publish_result.site_url=$URL"
  echo "publish_result.site_name=$SITE_NAME"
  echo "publish_result.version=$VERSION"
  echo "publish_result.expires_at=$EXPIRES"
  echo "publish_result.edge_status=$EDGE"
  echo "publish_result.claim_url=$CLAIM_URL"
  echo "publish_result.generated_index=$([ -n "$GENERATED_INDEX" ] && echo true || echo false)"
  if [ ${#SKIPPED[@]} -gt 0 ]; then
    echo "publish_result.skipped=${SKIPPED[*]}"
  fi
  if [ "$EDGE" != "ready" ]; then
    echo "publish_result.note=edge still provisioning; the URL may not resolve for a few minutes"
  fi
} >&2
