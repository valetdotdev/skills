# Skills

Two kinds of skill live on Valet. An organization's skill is a service,
like a website, an app, or an agent: `list_services` lists it, and the
service tools create, rename, and destroy it.

- **The organization's skills** tell coding agents, you included, how
  the organization works, for any work done for it, not only work on
  Valet. `governance` is the first of them, and the organization can add
  its own. When a task might be covered by how the organization works,
  list them and read a matching skill before starting.
- **An agent's skills** are bundles a Valet agent loads at deploy.

## Read the organization's skills

| Task | MCP | CLI |
|---|---|---|
| Read one | `get_skill` with `skill` | `valet skills show <name> --org <org>` |
| Read a skill's supporting file | `get_skill` with `skill` and `path` | `valet skills show <name> --path <file> --org <org>` |
| Read an earlier release | `get_skill` with `skill` and `release` (a version from `list_releases`) | `valet skills show <name> --release <n> --org <org>` |
| Read a whole skill in one call | `get_skill` with `skill` and `all_files` | `valet skills clone <name> [dir]` |
| List them | `list_skills` | `valet skills --org <org>`, then `valet skills info <name>` |

`all_files` returns `SKILL.md` and every other text file in one answer.
To install the result, write each file to its path under
`~/.claude/skills/<name>/` or `~/.agents/skills/<name>/`. Binary files
are listed with their sizes, and a skill over 50 files or 192 KiB of
text is refused; clone it with `get_skill` and `git` instead.

The answer says whether you hold the organization's version or Valet's
default. `valet skills show` prints the `SKILL.md`, or with `--path` the
supporting file, to standard output and its source to standard error.

## Create and publish an organization skill

Create the skill first, with `create_service` and `kind: skill`. A
publish refuses a name that does not exist.
To share a skill with the team, such as one the person keeps locally,
create it and publish it; every member's agent can then read it.

| Task | MCP | CLI |
|---|---|---|
| Create an empty skill | `create_service` with `kind: skill` and `name` | None; the CLI creates from a directory |
| Create a skill from a directory | `create_service`, then publish | `valet skills create <dir>` |
| Install a catalog skill | `create_service` with `kind: skill`, `name`, and `catalog` | `valet skills create --from catalog:<name>` |
| Clone the latest version | `get_skill` with `git` | `valet skills clone <name> [dir]` |
| Publish a version | `create_push` with `name`, `git push`, then `publish_skill` with `push` | `valet skills publish [dir]` |
| Change some files | `publish_skill` with `skill`, `edits`, and `base_version` | None; clone, change, and publish |
| See its releases | `list_releases`, then `get_source` or `get_skill` with `release` | `valet skills info <name>` |
| See who holds it | `get_service` | `valet skills info <name>` |
| Rename one | `rename_service` with `name` and `new_name` | `valet skills rename <name> <new-name>` |
| Delete one | `destroy_service` with `name` and `kind: skill` | `valet skills destroy <name>` |

`valet skills create <dir>` creates the skill that the directory's
`SKILL.md` names and publishes the directory as `v1`.

Publish from a push when you can run Git with network access.
`references/publish.md` § Probe for Git says how to check. Push a
directory or a clone, then pass `push: {id, commit}` to `publish_skill`.
A push carries every file, binary files included. `valet skills
publish` pushes by itself and removes files the directory lacks.

Without Git, `publish_skill` takes `edits` or `files`, each as
`[{path, content}]` text, within the limits `references/publish.md`
§ Publish with files gives. `edits` replaces or adds the files it names
and keeps every other file, binary files included. `files` replaces the
whole skill and drops every file it leaves out. Prefer `edits` to change
an existing skill, and say so rather than dropping a script or an image.

Pass `base_version`, the version `get_skill` reported, so a teammate's
publish in between is not overwritten. `get_skill` with `git` reports
the version of the commit it names, so a push can pass it too. `edits` requires it. A stale base
publishes nothing: read the skill again and redo the change.

Pass an `idempotency_key` to `create_service` and `publish_skill`, so a
retry after a lost answer returns the first result. Publishing identical
content creates no version. A skill holds up to
500 files and 50 MB, with at most 25 MB per file. Every kind of source
shares these limits.

A catalog skill is a template. An install copies it into a skill the
organization owns, under the name you give, which does not change when
Valet updates the catalog. An organization that installed it before gets
its existing copy back, whatever its name, and the answer says so.

Renaming a skill keeps its releases and the agents that hold it. It
publishes a release whose `SKILL.md` names the new name, and each
holding agent picks the name up on its own. A skill named for a
built-in keeps its name. Deleting a skill refuses while an agent holds
it; detach it from each agent first.

Publishing `governance` or `design-system` changes what every agent in
the organization reads. Do it only when the person asked to change how
the organization works, and show them the content first. Deleting a
skill named for a built-in brings back Valet's default.

## Give an agent a skill

A skill only one agent needs lives in its source at
`skills/<name>/SKILL.md`. A skill several agents share is attached:

| Source | Means |
|---|---|
| `catalog:<name>` | A skill from Valet's curated catalog; the first attach installs an org copy and reuses it after |
| `org:<name>` | A skill the organization published; over MCP, a bare name works too |

An attached skill always follows its newest release. Skills no longer
pin a version: a source with `@vN` attaches the newest release, and the
answer says the pin was ignored.

```
valet skills catalog                                   # browse
valet skills attach catalog:research --agent assistant # MCP: attach_skill
valet skills detach catalog:research --agent assistant # MCP: detach_skill
valet skills --agent assistant                         # what it holds
```

An agent's `valet.yaml` can name catalog skills too, as
`references/agents.md` describes.
