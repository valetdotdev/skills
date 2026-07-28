#!/usr/bin/env bash
#
# publish_walk.sh — what publish.sh decides to upload, and what it
# refuses to do, driven end to end against a mock API.
#
# The deny list is the one guard between a working tree and a public
# URL, and every part of it is a decision made locally before any RPC
# — so it is testable without the platform. The mock stands in for
# valet-api and the object store, records the manifest each publish
# declares, and lets the assertions be about paths rather than about
# what a live trial ended up serving.
#
#   valet-skills/test/publish_walk.sh
#
# Requires python3 (the mock), git, curl, and jq. Nothing here reaches
# the network: the mock listens on 127.0.0.1 and VALET_CONFIG_DIR
# points at a temporary directory.

set -euo pipefail

SCRIPTS="${VALET_PUBLISH_SCRIPTS:-$(cd "$(dirname "$0")/../skills/valet-publish/scripts" && pwd)}"
PUBLISH="$SCRIPTS/publish.sh"

command -v python3 >/dev/null 2>&1 || { echo "python3 is required"; exit 1; }
command -v git >/dev/null 2>&1 || { echo "git is required"; exit 1; }

WORK="$(mktemp -d)"
export VALET_CONFIG_DIR="$WORK/config"
REQUESTS="$WORK/requests.jsonl"
MOCK_PID=""
cleanup() {
  if [ -n "$MOCK_PID" ]; then
    kill "$MOCK_PID" 2>/dev/null || true
    wait "$MOCK_PID" 2>/dev/null || true
  fi
  rm -rf "$WORK"
}
trap cleanup EXIT

FAILED=0
check() { # check <description> <expected> <actual>
  if [ "$2" = "$3" ]; then
    echo "ok   $1"
  else
    echo "FAIL $1: expected [$2], got [$3]"
    FAILED=1
  fi
}

cat > "$WORK/mock.py" <<'PY'
"""A stand-in for valet-api's three trial RPCs and the object store.

Every request is appended to requests.jsonl as {"method","body"} so
the shell can assert on the manifest a publish declared. Uploads are
accepted and only their size recorded: what is under test is which
paths a publish chose, not what the object store does with them.
"""
import json, os, sys
from http.server import BaseHTTPRequestHandler, HTTPServer

WORK = sys.argv[1]
LOG = os.path.join(WORK, "requests.jsonl")


class Handler(BaseHTTPRequestHandler):
    def log_message(self, *args):
        pass

    def do_POST(self):
        length = int(self.headers.get("Content-Length") or 0)
        raw = self.rfile.read(length)
        method = self.path.rsplit("/", 1)[-1]
        entry = {"method": method}
        if method == "upload":
            entry["bytes"] = len(raw)
        else:
            entry["body"] = json.loads(raw.decode())
        with open(LOG, "a") as fh:
            fh.write(json.dumps(entry) + "\n")
        handler = getattr(self, "rpc_" + method, None)
        if handler is None:
            self.send_error(404)
            return
        self.reply(handler(entry.get("body", {})))

    def reply(self, payload):
        body = json.dumps(payload).encode()
        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def rpc_upload(self, _body):
        return {}

    def rpc_PublishTrialSite(self, body):
        base = "http://%s:%d" % self.server.server_address
        return {
            "siteName": "mock-site",
            "url": "https://mock-site.try.valet.run",
            "edgeStatus": "ready",
            "claimToken": "mock-claim-token",
            "claimUrl": "https://valet.dev/claim/mock-claim-token",
            "expiresAt": "2026-07-30T00:00:00Z",
            "uploadId": "mock-upload",
            "skippedCount": 0,
            "uploads": [
                {"path": f["path"], "sha256": f["sha256"],
                 "url": base + "/upload",
                 "fields": {"key": "objects/" + f["sha256"], "policy": "x"}}
                for f in body.get("files", [])
            ],
        }

    def rpc_FinalizeTrialSite(self, _body):
        return {"url": "https://mock-site.try.valet.run", "version": 1,
                "expiresAt": "2026-07-30T00:00:00Z"}


server = HTTPServer(("127.0.0.1", 0), Handler)
with open(os.path.join(WORK, "port"), "w") as fh:
    fh.write(str(server.server_address[1]))
server.serve_forever()
PY

python3 "$WORK/mock.py" "$WORK" &
MOCK_PID=$!
for _ in $(seq 1 100); do
  [ -s "$WORK/port" ] && break
  sleep 0.05
done
[ -s "$WORK/port" ] || { echo "mock did not start"; exit 1; }
VALET_API_URL="http://127.0.0.1:$(cat "$WORK/port")"
export VALET_API_URL

# declared — the manifest paths of the Nth PublishTrialSite call.
declared() { jq -r --argjson n "$1" \
  'select(.method=="PublishTrialSite")' "$REQUESTS" |
  jq -rs --argjson n "$1" '.[$n].body.files[].path' | sort | tr '\n' ' '; }

# A repository whose .gitignore lives at the root and whose site lives
# one level down. The old guard tested for a .git directory in the
# working directory, so publishing from here consulted no .gitignore
# at all.
REPO="$WORK/repo"
mkdir -p "$REPO/site/sub"
git -C "$REPO" init -q
printf 'secret.txt\n*.log\n' > "$REPO/.gitignore"
printf 'hello\n' > "$REPO/site/page.html"
printf 'keep\n' > "$REPO/site/sub/keep.txt"
printf 'API_KEY=live\n' > "$REPO/site/secret.txt"
printf 'noise\n' > "$REPO/site/debug.log"
printf 'API_KEY=live\n' > "$REPO/site/.env"

echo "=== publishing a subdirectory of a repository"
set +e
(cd "$REPO/site" && "$PUBLISH" >/dev/null 2>"$WORK/err1")
RC=$?
set -e
check "exits 0 on success" 0 "$RC"
check "uploads what is not ignored or denied" \
  "/index.html /page.html /sub/keep.txt " "$(declared 0)"
check "reports the skipped files" 1 \
  "$(grep -c 'publish_result.skipped=' "$WORK/err1" | tr -d ' ')"
check "says an index was generated" 1 \
  "$(grep -c 'publish_result.generated_index=true' "$WORK/err1" | tr -d ' ')"

echo "=== republishing the same directory"
set +e
(cd "$REPO/site" && "$PUBLISH" >/dev/null 2>"$WORK/err2")
RC=$?
set -e
check "exits 0" 0 "$RC"
check "sends the stored claim token" "mock-claim-token" \
  "$(jq -rs '[.[] | select(.method=="PublishTrialSite")] | .[1].body.claimToken' "$REQUESTS")"
check "keeps the trial link" "mock-site try" \
  "$(jq -r '[.agent, .org] | join(" ")' "$REPO/site/.valet/config.json")"

echo "=== naming an ignored file directly"
set +e
(cd "$REPO/site" && "$PUBLISH" secret.txt >/dev/null 2>"$WORK/err3")
RC=$?
set -e
check "refuses" 1 "$RC"
check "explains why" 1 "$(grep -c 'excluded from publishing' "$WORK/err3" | tr -d ' ')"

echo "=== --include-all overrides both halves of the deny list"
BEFORE="$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
set +e
(cd "$REPO/site" && "$PUBLISH" --include-all >/dev/null 2>&1)
RC=$?
set -e
check "exits 0" 0 "$RC"
# The link written by the first publish is in the tree by now, and
# --include-all means all: it turns off the static list and the
# .gitignore pass together.
check "publishes the ignored and denied files too" \
  "/.env /.valet/config.json /debug.log /index.html /page.html /secret.txt /sub/keep.txt " \
  "$(declared "$BEFORE")"

echo "=== publishing a directory git ignores"
# The build output is the case this skill exists for, and `dist/` is
# conventionally ignored. Inside such a root the rule is dropped
# wholesale — including for a file ignored on its own account — rather
# than skipping every file and refusing to publish anything.
mkdir -p "$REPO/dist"
printf 'dist/\n' >> "$REPO/.gitignore"
printf 'built\n' > "$REPO/dist/page.html"
printf 'noise\n' > "$REPO/dist/debug.log"
BEFORE="$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
set +e
(cd "$REPO/dist" && "$PUBLISH" >/dev/null 2>"$WORK/err5")
RC=$?
set -e
check "exits 0" 0 "$RC"
check "publishes the build output" "/debug.log /index.html /page.html " \
  "$(declared "$BEFORE")"
check "says .gitignore was not applied" 1 \
  "$(grep -c 'so .gitignore was not applied inside it' "$WORK/err5" | tr -d ' ')"

echo "=== a directory linked to another Valet project"
LINKED="$WORK/linked"
mkdir -p "$LINKED/.valet"
printf 'hello\n' > "$LINKED/index.html"
printf '{"version":1,"agent":"my-app","org":"acme"}\n' > "$LINKED/.valet/config.json"
BEFORE="$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
set +e
(cd "$LINKED" && "$PUBLISH" >/dev/null 2>"$WORK/err4")
RC=$?
set -e
check "refuses" 1 "$RC"
check "names the link it would have replaced" 1 \
  "$(grep -c 'already linked to a Valet project' "$WORK/err4" | tr -d ' ')"
check "makes no request" "$BEFORE" "$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
check "leaves the link alone" "my-app acme" \
  "$(jq -r '[.agent, .org] | join(" ")' "$LINKED/.valet/config.json")"

set +e
(cd "$LINKED" && "$PUBLISH" --relink >/dev/null 2>&1)
RC=$?
set -e
check "--relink publishes" 0 "$RC"
check "--relink repoints the link" "mock-site try" \
  "$(jq -r '[.agent, .org] | join(" ")' "$LINKED/.valet/config.json")"

echo "=== a token store that cannot be written"
# The site is live by the time the token is stored, so the claim URL —
# the only way back to it — has to be reported before the failure that
# loses the token, not after.
FRESH_DIR="$WORK/fresh"
mkdir -p "$FRESH_DIR"
printf 'hi\n' > "$FRESH_DIR/index.html"
# A config directory that cannot exist, rather than one this script
# would helpfully chmod back open.
printf 'x' > "$WORK/notadir"
set +e
(cd "$FRESH_DIR" && VALET_CONFIG_DIR="$WORK/notadir/config" "$PUBLISH" >/dev/null 2>"$WORK/err6")
RC=$?
set -e
check "refuses" 1 "$RC"
check "reports the claim URL first" 1 \
  "$(grep -c 'publish_result.claim_url=https://valet.dev/claim/' "$WORK/err6" | tr -d ' ')"
check "names the directory it could not create" 1 \
  "$(grep -c 'could not create' "$WORK/err6" | tr -d ' ')"

echo "=== a token store that cannot be parsed"
printf 'not json at all' > "$VALET_CONFIG_DIR/trials.json"
BEFORE="$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
set +e
(cd "$FRESH_DIR" && "$PUBLISH" >/dev/null 2>"$WORK/err7")
RC=$?
set -e
check "refuses" 1 "$RC"
check "makes no request" "$BEFORE" "$(grep -c PublishTrialSite "$REQUESTS" | tr -d ' ')"
check "says to repair it by hand" 1 \
  "$(grep -c 'repair it by hand' "$WORK/err7" | tr -d ' ')"

if [ "$FAILED" -eq 0 ]; then
  echo "PASS"
else
  echo "FAILURES"
fi
exit "$FAILED"
