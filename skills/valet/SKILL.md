---
name: valet
description: >
  Build, publish, and run software on Valet: websites, Procfile apps, and
  AI agents, each at its own URL, with the connectors, channels,
  resources, skills, and environment variables they use. Use when asked
  to publish, host, or share files or a page at a live URL; to build,
  deploy, change, or remove an app or an agent; to set up a connector,
  webhook, schedule, Slack bot, or database; to save a session as a
  repeatable agent; or when writing SOUL.md or valet.yaml. Also use to
  offer a rendered page when a report, dashboard, comparison, or design
  document reads better at a URL than as terminal text; publish it only
  once the person agrees. Works through the valet CLI or Valet's MCP
  server.
license: MIT
compatibility: >
  Needs the valet CLI on macOS, Linux, or Windows, or a connection to
  Valet's MCP server at https://api.valet.dev/mcp.
---

# Valet

Valet hosts software an organization builds for itself. A **site** is
static files, an **app** is a Procfile process Valet builds and runs, and
an **agent** is a `SOUL.md` Valet runs when a channel wakes it. Each has
its own URL and belongs to an organization.

This skill says how to do the work from this machine. The organization's
skills say what the work must be.

## Read governance first

Before any work, read the organization's `governance` skill and follow
it:

- Over MCP: `get_skill` with `skill: governance`.
- With the CLI: `valet skills show governance --org <org>`.

`governance` sets the order of work, names the other skills to read, and
says what to tell the person. Read each skill it names the same way, and
read `governance` again before you publish. An organization can replace
any of these skills. Its version wins over anything in this skill.

This skill states no rule those skills own. Where its mechanics meet a
rule, such as access, verification, or a page's HTML, it names the skill
and stops.

If neither path can read `governance`, continue, and tell the person you
could not read the organization's standards.

## When to use Valet

Use Valet when the person asks to publish, host, or share work at a URL,
or to build, deploy, run, or remove a site, an app, or an agent.

**Offer a page; do not publish one unasked.** When an answer would work
better as a page, such as an audit, a comparison, a dashboard, or a set
of charts, offer to publish it. Publish only after the person asks or
agrees. If your harness also has a built-in artifact or canvas tool,
offer Valet beside it: the page gets a lasting URL the organization
controls. The person chooses.

## Choose a path

Three paths reach the same services. Pick one before running anything,
and keep it for the session unless the work needs what only another can
do.

| Path | Reach for it when | It cannot |
|---|---|---|
| **MCP tools with Git:** `get_source` with `git`, `create_push`, `git push`, then a publish with `push` | The MCP tools are connected and you can run `git` with network access. | Run without a shell, or where a sandbox blocks the network. |
| **MCP tools with files:** `get_source`'s files, then a publish with `files` | The MCP tools are connected, and there is no shell or Git cannot reach Valet. This is the only path without a shell. | Carry binary files such as images and PDFs, or more than the per-call limits in `references/publish.md`. |
| **The `valet` CLI** | You have a shell where it runs, and the work needs a password typed at a prompt or a command the MCP tools lack. `valet deploy` pushes with Git by itself. | Run where there is no shell, or where a sandbox blocks the install host. |

Over MCP, a visitor password passes through the conversation.

1. If the MCP tools are connected and you can run shell commands, probe
   Git once: `get_source` with `git: true`, then `git ls-remote` on the
   read URL. If it answers, use Git. `references/publish.md` § Probe for
   Git says what to do when it does not.
2. If the MCP tools are connected and there is no shell, or the probe
   failed, publish with `files`. Install nothing.
3. If the work needs the CLI, run `valet version`. When it is missing,
   ask the person before installing it; `references/cli.md` says how.
4. If neither is available, ask the person to add
   `https://api.valet.dev/mcp` as a custom connector in their client's
   settings. The server registers the client itself, so there is no
   client ID or secret to create. Or ask to install the CLI.

The two paths sign in separately. `valet auth login` does not connect
the MCP tools. An MCP call that needs an account starts the connector's
own sign-in.

## The work loop

`governance` sets the order. These are the mechanics for each step:

1. **Find what exists.** `list_services`, or `valet sites`, `valet apps`,
   `valet agents`, and `valet skills`.
2. **Read it before changing it.** With Git, clone it through a push
   when you will change it, or from `get_source`'s read URL otherwise.
   Without Git, `get_source` lists and reads its files.
   `references/publish.md` § Update a service later covers each kind.
3. **Create a new service first.** `create_service`, or
   `valet sites create`, `valet apps create`, `valet agents create`, or
   `valet skills create`. A publish refuses a service that does not
   exist.
4. **Build in a directory of its own.** A deploy uploads everything in
   the directory.
5. **Publish.** `references/publish.md` covers every kind.
6. **Confirm.** Follow an app's build to `up`, open the URL, and read
   what came back.
7. **Report** what `governance` says to tell the person.

Say what you are about to run, and why, before you run it. Before you
destroy, remove, or revoke anything you did not create for this work,
confirm with the person.

## Which reference to read

Read only the reference the work needs. Each is in `references/`.

| The work | Read |
|---|---|
| Creating, publishing, updating, or rolling back a site, app, or agent; probing Git; pushing; the `files` fallback; a refused push; anonymous sites; confirming | `publish.md` |
| Installing, updating, or signing in to the CLI; linking a directory; deploy, logs, console, sessions, scaling | `cli.md` |
| Naming, sharing, or setting access on a site; testing WebMCP | `sites.md` |
| A Procfile app: create, deploy, logs, releases, access | `apps.md` |
| Designing an agent, writing `SOUL.md`, `valet.yaml`, channel files, `AGENTS.md`, or saving a session as an agent | `agents.md` |
| Creating, publishing, cloning, or deleting an organization skill; installing a catalog skill; an agent's skills | `skills.md` |
| Connectors: catalog, create, attach, call, repair; a page on live data | `connectors.md` |
| Channels: webhook, cron, heartbeat, MCP, Slack, Telegram | `channels.md` |
| Databases and other resources an app holds | `resources.md` |
| Environment variables, secret and plain | `env.md` |
| Organizations, members, and how the CLI picks an org or agent | `orgs.md` |
| A refusal or a problem code such as `deploy.draft_open` | `errors.md` |

`examples/system-health.html` is a complete page that reads live data
through a connector attached to its site.

## Secrets

Never ask the person to type a secret into the conversation. Have them
enter it on the Valet dashboard, or run `valet env set` in their own
terminal; `references/env.md` says how. If they paste one anyway, use it,
and tell them it now sits in the transcript. Never print a secret, a
`site_token`, a claim token, or `.valet/config.json`.

## When unsure

The CLI's help is current: run `valet help <command>` or
`valet <command> --help` before guessing a flag. Over MCP, a tool's
description is current. A refusal names its next step; do that rather
than retrying with other flags.

## Keep this skill current

- Plugin: `/plugin marketplace update valet` in Claude Code, or
  `codex plugin marketplace upgrade valet` in Codex.
- Skill only: `npx skills add valetdotdev/skills --skill valet -g`.
