# Publish

How to create, publish, update, and roll back a site, an app, or an
agent from this machine. Read `governance` first; it names `security`
and the skill that says how to build each kind.

## Create the service first

A publish changes a service that exists, and refuses a name that holds
none. Create a new one before its first publish:

- **MCP:** `create_service` with `kind` (`site`, `app`, or `agent`),
  `name`, and an `idempotency_key`. A site may omit `name` and get a
  generated one. Take the URL from the result.
- **CLI:** `valet sites create`, `valet apps create`, or
  `valet agents create`, from the service's directory. Each links the
  directory.

## Probe for Git

Over MCP, Git carries any file and only what changed. Probe once per
session, before the first read or publish:

1. Run `git --version`. Treat Git older than 2.32 as missing: it ignores
   `GIT_CONFIG_GLOBAL`, so the person's Git setup could change a commit.
2. Make a Git key (§ Make a Git key). Call `get_source` with `name`,
   `git: true`, and `key_sha256` on any published service from
   `list_services`. Then run the first three lines of the first command
   it returns, which define `vgit`, and `vgit ls-remote <url>`. If the
   organization has nothing published yet, probe the URL of the first
   push instead.
3. If it lists refs, use Git for the rest of the session.
4. If a sandbox blocks the network, as Codex's default sandbox does for
   shell commands, ask to run the Git command outside it; Codex puts
   that to the person. If you cannot ask, tell the person their client
   blocks the network for shell commands, and that allowing it lets you
   publish binary files.
5. If Git is missing, the host is unreachable, or the person declines,
   publish with `files` (§ Publish with files) for the rest of the
   session.

Probing a read URL creates nothing but a key that expires in an hour.

## Make a Git key

A Git URL from Valet carries no credential. You prove you hold a key you
made, and Valet never sees the key, only its SHA-256. Make the key
before you call `create_push`, or `get_source` or `get_skill` with
`git: true`. This script writes it to a mode-600 file outside any
repository, reuses the file if it exists, and prints the hash to pass as
`key_sha256`:

```sh
umask 077; export VALET_GIT_KEY_FILE="$HOME/.config/valet/git-key"; mkdir -p "${VALET_GIT_KEY_FILE%/*}"; [ -s "$VALET_GIT_KEY_FILE" ] || head -c 32 /dev/urandom | od -An -tx1 | tr -d ' \n' > "$VALET_GIT_KEY_FILE"; (sha256sum 2>/dev/null || shasum -a 256) < "$VALET_GIT_KEY_FILE" | cut -d' ' -f1
```

The key stays in that file. Never print it, put it in a command line,
a URL, `.git/config`, or a tool call, or ask the person to paste it.
Every recipe a tool returns reads it from the file through a credential
helper scoped to Valet's host. When you finish, delete the file:
`rm -f "$VALET_GIT_KEY_FILE"`.

## Publish with Git

Each publish is three calls tied by a push id:

1. `create_push` with `name`, `key_sha256`, and an `idempotency_key`.
   The result carries `push_id`, a `url` for the push's branch that
   holds no credential, the `branch`, `base_commit` (the service's
   source now), `active_commit`, `expires_at`, the size `limits`, the
   `author_name` and `author_email` to commit as, and `commands`: these
   recipes with every value filled in. Run those.
2. Commit on top of the branch and push it.
3. `publish_site`, `publish_app`, `publish_agent`, or `publish_skill`
   with `push: {id, commit}` in place of `files`, and the arguments the
   kind needs, such as `title` and `description`. `publish_skill` names
   the skill with `skill`.

A push lasts one hour. Your key writes only `draft/<push_id>`, and only
by fast-forward: Git refuses a force push and any other branch. Push as
often as you need before the publish; the publish deploys the commit
you name. A repeat of `create_push` with the same `idempotency_key`
returns the same push and replaces its key with the hash you send.

Change the service's own source. This is the default:

```sh
# Ignore the person's Git configuration, so no filter or hook changes a commit.
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export VALET_GIT_KEY_FILE="$HOME/.config/valet/git-key"
# vgit is git with a credential helper that reads the key file, for Valet's host only.
vgit() { git -c 'credential.<origin>.helper=!f() { echo username=valet; echo "password=$(cat "$VALET_GIT_KEY_FILE")"; }; f' "$@"; }

vgit clone --single-branch --branch draft/<push_id> '<url>' work
# ...edit files in work/...
git -C work add -A
git -C work -c user.name='<author_name>' -c user.email='<author_email>' commit -m "<message>"
vgit -C work push origin HEAD:draft/<push_id>
git -C work rev-parse HEAD   # the commit to publish
```

`<origin>` is the scheme and host of `<url>`. The result's `commands`
hold the same lines with it filled in.

Push a directory as it stands, on top of the base. No repository in it
changes:

```sh
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1 GIT_TERMINAL_PROMPT=0
export VALET_GIT_KEY_FILE="$HOME/.config/valet/git-key"
vgit() { git -c 'credential.<origin>.helper=!f() { echo username=valet; echo "password=$(cat "$VALET_GIT_KEY_FILE")"; }; f' "$@"; }

d=$(cd <dir> && pwd)
gd=$(mktemp -d)
g() { vgit --git-dir="$gd" --work-tree="$d" "$@"; }
g init -q && g fetch -q --depth 1 '<url>' draft/<push_id>
g update-ref HEAD FETCH_HEAD
(cd "$d" && find . -type f ! -name .git ! -name .valet ! -path '*/.git/*' ! -path '*/.valet/*' -print0) | g -C "$d" update-index --add -z --stdin
g -c user.name='<author_name>' -c user.email='<author_email>' commit -qm "<message>"
g push '<url>' HEAD:refs/heads/draft/<push_id> && g rev-parse HEAD
```

The directory recipe adds every regular file, ignored ones included, at
any depth. It skips symbolic links and anything named `.git` or
`.valet`. Build the service in a directory of its own, as § What a CLI
deploy uploads says.

A publish refuses symbolic links, submodules, paths under `.git` or
`.valet`, and Git LFS pointer files. Commit the real file, not its
pointer: if the directory came from a repository that uses LFS, fetch
the files there before you push.

## Reconcile a refused push

A site's or app's publish refuses with `deploy.source_moved` when
someone published it after your push was created. Nothing was deployed,
and your push stays open until it expires. Its message carries these
steps with the values filled in:

1. `create_push` again, with the same `key_sha256`. Its branch starts at
   the current source.
2. Fetch that branch into the repository you pushed from:
   `vgit -C work fetch '<new url>' draft/<new push_id>`.
3. Merge or rebase your commit onto `FETCH_HEAD`, and resolve any
   conflict so both changes survive. Pass the author with
   `-c user.name=<author_name> -c user.email=<author_email>`, as the
   recipes do.
4. Push with
   `vgit -C work push '<new url>' HEAD:refs/heads/draft/<new push_id>`,
   and publish the new commit with the new push id.

If you pushed a directory, run the directory recipe again against the
new push instead. An agent reconciles by itself.
`references/errors.md` lists the other push refusals and their next
steps.

## Publish with files

Without Git, every publish tool takes `files` as `[{path, content}]`.
It carries text only: HTML, CSS, JavaScript, Markdown, JSON, and SVG.
At the default limits, one call takes 50 files, 128 KiB per file, and
192 KiB in all; a refusal names the limit it broke. Images, PDFs, and
video need Git or the CLI. A push holds up to 500 files and 50 MB, with
at most 25 MB per file. Say so rather than publishing a page that
links to files you could not upload.

## What a CLI deploy uploads

`valet deploy` pushes with Git by itself and needs Git 2.32 or later. It
commits every regular file under the directory. It skips `.git/` and
`.valet/` at any depth and every symlink. It reads no `.gitignore`, and
it never touches a repository inside the directory. A site serves every
uploaded file except its root `valet.yaml`, and Valet refuses to serve
paths that look like secrets, such as `.env`. A refused path is still
uploaded, and every member can read it.

So never deploy a directory you have been working in. Build the service
in a directory of its own, then list it and read what is there:

```bash
mkdir -p ~/reports/migration-audit
cp audit.html ~/reports/migration-audit/index.html
cd ~/reports/migration-audit && ls -la
```

A deploy over the service's size limit is refused and names the file.

## Name the service

A service's name is the first label of its URL, so it must be DNS-safe.
Give a person something better to read:

- **CLI, site or app:** write `valet.yaml` at the root with `name`,
  `display_name`, and `description`. An app may add `emoji`, exactly one.
  Add nothing else; a `connectors` or `channels` block is refused.
- **MCP, site or app:** pass `title` and `description`. Valet writes the
  `valet.yaml` and refuses one in `files`.
- **Agent, either path:** the agent's own `valet.yaml`, as
  `references/agents.md` describes.

`display_name` over the CLI is `title` over MCP. The `sites` skill says
how to write them. Update both when the content changes.

## Publish a site

**CLI.** From the site's directory:

```bash
valet sites create migration-audit --org acme   # prints the URL; links the directory
valet deploy
```

The URL serves 404 until the deploy finishes. Omit the name and the
server picks one. An `index.html` at the root is the page. Without one,
visitors get a list of the files. Say so when you publish that way.

**MCP.** `create_service` with `kind: site`, then `publish_site` with
`push` or `files`, `title`, `description`, and an `idempotency_key`.

## Publish an app

**CLI.** From the app's directory, with a `Procfile` at the root:

```bash
valet apps create inventory --org acme   # prints the URL and access; links the directory
valet deploy
```

`valet deploy` waits for every process, prints each change of state, and
exits 1 if one crashes. `--no-wait` prints the build's id and returns;
`valet builds show <id> -f` follows that build later, and without `-f`
it prints the build's log and status once.

**MCP.** `create_service` with `kind: app`, then `publish_app` with
`push` or `files`, `title`, `description`, and a new `idempotency_key`
for new source. Poll `get_build` until `deploy_state` is `up` or
`crashed`. A successful build is not yet live.

On a crash, read the reason, fix it, and publish again. A web process
that had a running release keeps serving it, so a working URL does not
prove the new release is live.

Attach resources and set variables after the first publish, once the
build is `up`; `references/resources.md` and `references/env.md` say how.

## Publish an agent

**CLI.** `valet agents create` from a directory with `SOUL.md` creates,
links, and deploys the agent. Later, `valet deploy` publishes changes.
See `references/agents.md`.

**MCP.** `create_service` with `kind: agent`, then `publish_agent` with
`push` or `files`; the source holds `SOUL.md` and `valet.yaml` at the
root. When the manifest names something the organization lacks, nothing
deploys and the answer lists what to set up; do that and publish the
same source again.

## Update a service later

A publish or a deploy replaces every file of the service, so a file you
leave out is deleted. Start from the current source, change it, and
publish the whole of it again.

| Path | Read the current source | Publish |
|---|---|---|
| MCP with Git | Clone through a new push (the first recipe). Its branch starts at the current source. | `publish_*` with `push` |
| MCP with files | `get_source` lists the files; with `path` it reads one. | `publish_*` with `files`, naming the service |
| CLI, site | In the linked directory, nothing to read. Elsewhere, `valet sites download <name>`, which fetches the files and links the new directory. | `valet deploy` |
| CLI, app or agent | In the linked directory, nothing to read. Elsewhere, clone with `get_source`'s read URL, using a Git key, then `valet apps link <name>` or `valet agents link <name>`. | `valet deploy` |

Never link an empty or partial directory and deploy it. The deploy
replaces the service with what the directory holds.

`get_source`'s files are text only; it lists binary files without them.
Never republish a service that holds binary files with `files`: they
would be lost. Use Git or the CLI.

## Roll back

`list_releases` gives each release's version. `get_source` with
`release` and `git: true` gives that release's `commit`. Create a push,
clone it with the first recipe, restore that commit's files, push, and
publish:

```sh
git -C work restore --source=<commit> --staged --worktree -- .
git -C work -c user.name=<author_name> -c user.email=<author_email> commit -m "Roll back to release <version>"
git -C work push origin HEAD:draft/<push_id>
```

A push only moves forward, so a rollback is a new commit holding the old
files. Without Git, read the release's files with `get_source` and
`release`, and publish them again.

## Confirm it

- **Site:** open the URL and read what came back.
- **App:** follow the build to `up`, then open the URL.
- **Agent:** `get_service`, or `valet agents info`, says whether it runs.

If you cannot open the URL, check `get_service` or `valet sites info`,
and tell the person you could not load the page.

## What to tell the person

Say what `governance` lists. For a publish, also:

- Never present a local file path as the URL.
- Take who can open it from the result: `publish_site` reports the
  access, and for an app read `get_service` or the `Access` line
  `valet apps create` printed. Do not assume an app is public or
  private; it depends on the installation.
- Pass through any notice the CLI prints as it stands, such as the
  forwarding notice from `valet sites share`.

A refusal names its next step. `references/errors.md` lists the codes.
