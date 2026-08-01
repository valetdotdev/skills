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

Create a live URL from any file or folder. Static hosting only, and no
Valet account needed. You do it by running the `valet` CLI through the
Bash tool.

Install or update this skill:
`npx skills add valetdotdev/skills --skill valet-publish -g`

**Communication style**: say what you are about to run and why before
you run it. Report the URL, the expiry, and the claim URL as soon as
you have them — the claim URL is printed once and cannot be recovered.
Confirm with the user before taking a site down.

## Supported platforms

**macOS with Homebrew** is the supported path, and the installation
below assumes it. A Linux machine that *already* has Homebrew works
too — the tap's formula carries Linux builds.

**Linux without Homebrew, and Windows, are not supported yet.** There
is no other installer. When the user is on one of those, say so before
you try anything:

> Publishing needs the Valet CLI, and Homebrew is the only way to
> install it right now — so macOS, or a Linux machine that already has
> Homebrew. Windows and Homebrew-less Linux aren't supported yet.

Then stop. Do not improvise a download, a package manager, or a build
from source.

## Installation

Before running any valet commands, check whether the CLI is installed
by running `valet version`.

If `valet` is not installed, **explain to the user why it is needed
before attempting installation**:

> The Valet CLI is what publishes files to a live URL. I'll install it
> for you now via Homebrew.

Then check whether Homebrew is available by running `brew --version`.

**If Homebrew is not installed**, ask the user whether they'd like to
install Homebrew first. If they agree, install it with the official
installer:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

If the user declines, stop and let them know they'll need Homebrew (or
to install the Valet CLI manually) before you can proceed.

**If Homebrew is installed**, install the Valet CLI:

```
brew install valetdotdev/tap/valet
```

**IMPORTANT — Homebrew failures**: If `brew install
valetdotdev/tap/valet` fails for any reason — tap errors, permission
issues, network problems, formula conflicts, or anything else — **do
not attempt to troubleshoot, retry, or work around the issue**.
Instead, inform the user:

> It looks like the Homebrew installation didn't succeed. Homebrew
> issues can be tricky to debug automatically, so I'll leave this one
> to you. Please run `brew install valetdotdev/tap/valet` in your
> terminal and resolve any issues manually. Once the CLI is installed,
> come back and we'll pick up where we left off.

Then **stop the current workflow**. Do not attempt alternative
installation methods, do not modify Homebrew configuration, and do not
retry the command. Wait for the user to confirm the CLI is installed
before continuing.

**An already-installed CLI can be too old.** `valet version` prints
`valet/<version> <os>-<arch> <go>`; anonymous publishing needs
**v0.1.75 or later**. If the version is older, or a command below
fails with `unknown flag: --anonymous`, upgrade it:

```
brew upgrade valetdotdev/tap/valet
```

If that fails, hand back to the user exactly as above rather than
working around it.

No `valet auth login` is needed for anything in this file. Publishing
anonymously never touches an account.

## Publish

Two commands, run in the directory that should become the site root:

```bash
cd path/to/site
valet sites create --anonymous
valet deploy
```

`valet sites create --anonymous` mints the site and prints the live URL,
the expiry, and the claim URL. `valet deploy` uploads the directory. The
URL serves 404 until that finishes.

**Before the deploy, list the directory and read what is in it.**
Everything there becomes public except `.git/`, `.valet/`, and
symlinks — that is the whole list, and it is shorter than people
expect (see "What is not uploaded" below). Move anything
credential-shaped out first, and say what you found.

**Publish the directory whose contents should be the site root** —
publish `my-site/`, not a parent containing it. There is no way to
publish a single file directly: put it in a directory of its own and
publish that.

```bash
mkdir -p report && cp ~/Downloads/q3.pdf report/
cd report
valet sites create --anonymous
valet deploy
```

An `index.html` at the root is served as the site. Without one,
visitors get a browsable listing of the files, so a folder of charts
or a single PDF is worth publishing as-is. Say so when there was no
`index.html`, and that adding one replaces the listing.

`valet sites create --anonymous` takes no site name — the server
generates one — and cannot be combined with `--org`.

### The three refusals

Each one is the right answer rather than an obstacle. Read the
message, do what it names, and do not reach for a flag to get past it.

- **You are signed in.** An anonymous site is public and lives in a
  shared incubator org, which is not where a signed-in user's content
  belongs. The permanent path is `valet sites create <name>` followed
  by `valet sites access <name> public` — their own org, and public
  only because they said so.
- **This directory already publishes an anonymous site.** Run `valet
  deploy` to update it. `--relink` starts a *new* site and overwrites
  the existing claim token, which is the only credential the current
  site has; only pass it when the user means to abandon that site.
- **This directory, or one above it, is already a Valet project.**
  Publish from a copy outside it, or run `valet deploy` to deploy the
  project that is there. `--relink` replaces a link in *this*
  directory only — it deliberately cannot reach one in a parent.

## Update

```bash
valet deploy
```

From the same directory. Only changed files upload, and the URL does
not change. Neither does the expiry: the 36 hours run from when the
site was created, not from the last deploy.

`valet deploy` asks the server where the site stands before it uploads
anything, which is how it copes with everything that can happen to a
site while nobody is looking:

- **Still unclaimed** — it publishes, and that is the ordinary case.
- **Claimed in a browser** — it says where the site went, rewrites the
  link to the new org and name, drops the spent claim token, and
  carries on to the permanent site. From that point the site is an
  ordinary Valet site: deploying to it needs `valet auth login` and
  membership in that org, and the `valet` skill covers the rest.
- **Expired, deleted, or reaped** — it says which, names the stale
  link file to remove when there is nothing left to authorize, and
  offers a fresh publish. Do not try to revive it; publishing to an
  expired anonymous site is refused server-side.

## Status

```bash
valet sites info
```

From the directory the site was published from, with no site name.
Prints the URL, the state (`unclaimed`, `claimed`, `expired`,
`deleted`, or `reaped`), and either the expiry or — once claimed —
where the site went.

This is the only correct way to answer "is it still up" or "when does
it go away". Never infer either from the link file on disk; it cannot
know what happened in a browser.

## Take it down

```bash
valet sites destroy
```

From the same directory, with no site name. The server is asked first,
and `.valet/config.json` is removed only after the site is confirmed
gone.

Use this without hesitation if the user says they published something
by mistake — do not wait for the expiry. A site that has already been
claimed is refused here: it belongs to an org now, and taking it down
is `valet sites destroy <name>` with an account.

## Claim

An anonymous site expires 36 hours after it is created, unless it is
claimed, and is removed shortly after that. Claiming moves it into an
organization and makes it permanent; the anonymous URL keeps working
and redirects to the new one.

**The claim URL printed at creation is the route for someone with no
account.** Opening it signs them in — or signs them up — and can
create the org at the same time.

**When they already have an account and belong to an org**, claiming
works from the publishing directory:

```bash
valet sites claim --org <org>
```

`--name <name>` renames the site on the way in. `--org` is required
and must name an org that already exists: this command never creates
one, because an org name is reserved permanently. Run `valet orgs
create <org>` first, or use the claim URL, which does both at once.

A claimed site **stays public** — anyone with the link can still view
it, which is the point of the link the publisher already shared.
`valet sites access <name> private` changes that.

The claim token is returned once, at creation, and after that it lives
only in `.valet/config.json`. If both it and the claim URL are gone,
the site cannot be updated, taken down, or claimed by anyone, and it
will be removed when its window closes.

## State

One file: `.valet/config.json` in the published directory, mode 0600.
It holds the link — the site's name and the `try` org — and the claim
token.

**Tell the user it should not be committed.** The claim token is a
bearer credential: whoever holds it can update, take down, or claim
the site. The file otherwise looks like ordinary project
configuration, which is exactly what `git add .` sweeps up.

You never need to read the token yourself — every command above finds
it. Do not print the file, and do not copy the token into a message, a
commit, or an issue.

Nothing else on the machine knows about the site: no token store, no
lock file, and nothing written into the Valet config directory, which
anonymous publishing never touches. So an anonymous site can only be
managed from the directory it was published from — from anywhere else,
the claim URL is the only handle.

## What is not uploaded

`.git/`, `.valet/`, and symlinks. That is the whole list, and it is
the same list before and after a claim, so nothing about what the site
serves changes when its ownership does.

The two directories are not on the list because of what they tend to
contain. `.git` is *history* rather than directory contents —
publishing it serves every version of every file the working tree no
longer shows. `.valet` carries the claim token, and a site must not
serve the one credential that controls it.

**Everything else in the directory is published**, including dotfiles,
`.env` files, `node_modules/`, and anything the project's `.gitignore`
ignores. Publish a directory and you publish that directory — there is
no second, invisible rule about what counts as its contents.

So look at what is in the directory before you run `valet deploy`, and
move anything that should not be on a public URL somewhere else first.
`valet deploy` prints a skipped count for every path it passes over,
counting a whole `.git/` or `.valet/` as one path rather than as the
files inside it — so the line tells you *that* something was skipped,
never how much.

## Limits

| | Anonymous |
|---|---|
| Max file size | 250 MB |
| Max total size | 250 MB |
| Max files | 1000 |
| Expiry | 36 hours after creation, unless claimed |

## What to tell the user

- Always: the live URL, the expiry, and the claim URL.
- That `.valet/config.json` now holds the site's only credential and
  should not be committed.
- If the root had no `index.html`: that visitors see a file listing,
  and that adding an `index.html` replaces it.
- On claim: the new permanent URL, that the anonymous URL redirects to
  it, and that the site stays public.
- Never present a local file path as a URL.

**Say the expiry the way the CLI says it.** The CLI leads with how
long is left, because that is the question a reader actually has, and
keeps the absolute time in parentheses so a deadline can be written
down:

- Quoting what the CLI printed: `Expires in 1d 11h (2026-08-02 12:27
  UTC)`. Pass that line through as it stands — the timestamp names
  its zone, and a duration you recompute goes stale as you print it.
- Speaking generally, before there is a timestamp: an anonymous site
  expires 36 hours after it is created, unless it is claimed. Claim
  it to keep it.
- Once the deadline has passed: `This anonymous site is past its
  expiry and may be removed at any time.` Do not offer to claim it —
  claiming an expired anonymous site is refused server-side.

Expiry and removal are separate moments, and the gap only matters for
a site sitting right on the line. Expiry ends the site's mutability;
the reaper ends its visibility, a grace window and up to one sweep
later. So a site just past its deadline may well still be serving,
and still cannot be updated or claimed.

## When something goes wrong

The CLI's own output is authoritative, and every refusal it prints
names the command that resolves it. Run that command rather than
guessing, and use the built-in help for anything this file does not
cover:

```
valet sites create --help
valet sites info --help
valet sites destroy --help
valet sites claim --help
```

Do not retry a failed publish with different flags hoping one works.

For a permanent site in the user's own org, an account, or an AI
agent, use the `valet` skill instead.
