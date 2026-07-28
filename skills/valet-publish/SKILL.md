---
name: valet-publish
description: >
  Publish files, folders, and artifacts to the web instantly. Static
  hosting for HTML sites, images, PDFs, reports, dashboards, and any file
  type. Use when asked to "publish this", "host this", "share this on the
  web", "make a website", "put this online", "upload to the web", "create
  a webpage", "share a link", "serve this site", "make an artifact",
  "publish this artifact", or "turn this into an artifact". Outputs a live
  URL at {name}.try.valet.run, free and with no account. For deploying an
  AI agent rather than static files, use the `valet` skill instead.
---

# valet-publish

Create a live URL from any file or folder. Static hosting only.

Install or update: `npx skills add valetdotdev/skills --skill valet-publish -g`

## Requirements

- `curl`, `jq`, and `sha256sum` or `shasum`
- No account, no API key, no CLI

## Publish

```bash
./scripts/publish.sh {file-or-dir}
```

Prints the live URL. Without a claim token this creates an **anonymous
site that expires in 36 hours**; claiming it makes it permanent.

Three steps under the hood: declare the manifest, upload missing
objects, finalize. The site is not live until finalize succeeds.

**File structure.** Publish the directory whose contents should be the
site root — publish `my-site/`, not a parent containing it. An
`index.html` at the root is served as the site. Without one the URL
shows a file listing with the README rendered underneath, so a folder
of charts or a single PDF is worth opening as-is — mention that when
there is no `index.html`, and that adding one replaces the listing.

**What is never uploaded.** The published URL is public, so the script
skips, without being asked: `.git/` (history contains every credential
ever committed and later removed), `.valet/`, `.env` and `.env.*`,
`node_modules/`, `.DS_Store`, and anything the directory's
`.gitignore` excludes. Symlinks are not followed — a link pointing
outside the published directory would otherwise exfiltrate whatever it
points at. The script prints what it skipped so the omission is never
silent, and `--include-all` overrides it for someone who genuinely
means to publish a dotfile.

Tell the user what was skipped when it is non-obvious. Publishing a
git working tree and silently shipping `.git` to a public URL is the
single worst thing this skill could do.

## Update

```bash
./scripts/publish.sh {file-or-dir}
```

From a directory that already has `.valet/config.json` with
`"org": "try"`, this republishes the same trial at the same URL. Only
changed files upload.

## Delete

```bash
./scripts/delete.sh [--slug {slug}]
```

Takes the site down immediately. Reads the claim token for the current
directory's site, calls `DeleteTrialSite`, and drops the entry from the
token store. With `--slug` it deletes any trial in the store, so a user
can clean up something published from elsewhere.

Use this without hesitation if the user says they published something
by mistake — do not wait for expiry.

## Status

```bash
./scripts/status.sh [--slug {slug}]     # one site
./scripts/status.sh --all               # everything in the token store
```

Calls `GetTrialClaim` and prints the live state, URL, and expiry. This
is the only correct way to answer "is it still up" or "when does it
expire" — never read those from the token store. `--all` prunes
entries the API reports as expired, deleted, or reaped.

## Claim

The publish output includes a claim URL. Opening it signs the user in
and moves the site into an organization, making it permanent. Claim
tokens are returned once and cannot be recovered — if the token is
gone, the trial cannot be updated, deleted, or claimed.

After a claim, the directory relinks itself on the next publish or
`valet deploy`, and the user is in the ordinary Valet product:

```
brew install valetdotdev/tap/valet
valet auth login
valet deploy
```

## State

- `.valet/config.json` in the published directory — the link, safe to
  commit, read by the Valet CLI.
- `$VALET_CONFIG_DIR/trials.json` (default `~/.config/valet/`, mode
  0600) — claim tokens keyed by site name, plus URL, claim URL,
  expiry, and source directory.

Never print the token store path as a URL, and never read expiry or
claim state from it — the API response is authoritative. Use
`./scripts/status.sh` to ask.

## What to tell the user

- Always: the live URL, that it expires in 36 hours, and the claim URL.
- If an index was generated: say so, and how to replace it.
- On claim: the new permanent URL, and that the old one redirects.
- Never present local file paths as URLs.

## Limits

| | Anonymous |
|---|---|
| Max file size | 250 MB |
| Max total size | 250 MB |
| Max files | 1000 |
| Expiry | 36 hours (permanent once claimed) |
| Rate limit | 5 publishes / hour / IP |

## API

Base URL `https://api.valet.dev`. Every call is a plain JSON POST and
needs no authorization header; the claim token authorizes the three
operations that take one.

```
POST /valet.api.v1.APIService/PublishTrialSite
  {"files":[{"path":"/index.html","sha256":"…","size":1234}],
   "client":"claude-code","claimToken":""}
  → {"siteName","url","edgeStatus","claimToken","claimUrl","expiresAt",
     "uploadId","uploads":[{"path","sha256","url","fields"}],
     "skippedCount"}

# One multipart POST per missing object. Every field from
# uploads[].fields must be sent before the file part:
curl -F key=… -F policy=… -F x-amz-signature=… \
     -F file=@local/path  <uploads[].url>

POST /valet.api.v1.APIService/FinalizeTrialSite
  {"claimToken":"…","uploadId":"…"}      → {"url","version","expiresAt"}

POST /valet.api.v1.APIService/GetTrialClaim
  {"claimToken":"…"}                     → {"url","state","expiresAt",…}

POST /valet.api.v1.APIService/DeleteTrialSite
  {"claimToken":"…"}                     → {}
```

Re-calling `PublishTrialSite` with the same manifest returns fresh
upload URLs for whatever is still missing — that is how to resume an
interrupted upload or refresh expired URLs.
