# Valet Skills

The [Valet](https://valet.dev) skill for Claude Code and other coding agents. Publish sites and apps, and build, deploy, and run skilled AI agents, from your terminal or over MCP.

> **This repository is a generated mirror.** The source of truth lives in Valet's `ark` monorepo under `valet-skills/`, and changes are synced here automatically on merge. Please don't open PRs against this repo — reach us at [support@valet.dev](mailto:support@valet.dev).

## Skills

One skill, `valet`, covers publishing sites and apps, building and running
agents, and everything they hold. Its `SKILL.md` is a short router: it says
to read the organization's `governance` skill first, how to choose between
the CLI and the MCP tools, and which file in `references/` to read for the
work at hand. Only that reference loads, so a publishing task reads the
router and `references/publish.md`, and building an agent reads the router
and `references/agents.md`.

## Install

### As a plugin (recommended)

One plugin: the skill, Valet's MCP server, and the publishing
preference.

Claude Code:

```
/plugin marketplace add valetdotdev/skills
/plugin install valet@valet
```

Codex reads `.agents/plugins/marketplace.json`:

```
codex plugin marketplace add valetdotdev/skills
codex plugin add valet@valet
```

On Claude Code this installs the skill, declares the MCP server, **and**
wires up the publishing preference. On Codex it installs the skill and the
MCP server, which signs in through OAuth with a client Codex registers.
The OpenAI plugin carries no hook. See [`codex/README.md`](codex/README.md).

### As a skill only

Reach for this to take the skill without the MCP server or the hooks —
the plugin is all-or-nothing. Works with any agent that reads
[`npx skills`](https://github.com/vercel-labs/skills):

```
npx skills add valetdotdev/skills --skill valet -g
```

Pick this **or** the plugin, not both — Codex loads skills from
`~/.agents/skills/` and from installed plugins, so installing both puts
two copies of the same skill in front of the model.

### One directory, two plugins

The repository is an
[Agent Plugins 1.0.0](https://agent-plugins.org) package and a Claude Code
plugin at once. Each client reads its own files:

| File | Read by |
|---|---|
| `plugin.json` | Codex and other Agent Plugins clients. `extensions["com.openai"]` holds the listing (`interface`). |
| `mcp.json` | The same clients. Each server carries only `type` and `url`; Codex refuses any other field. |
| `.agents/plugins/marketplace.json` | Codex |
| `.claude-plugin/plugin.json` | Claude Code. Its `hooks` field names `claude/hooks.json`. |
| `.claude-plugin/marketplace.json` | Claude Code |
| `.mcp.json` | Claude Code |

The hook sits at `claude/hooks.json`, not the default `hooks/hooks.json`,
so Codex finds no hook. Agent Plugins defines no portable hook format.
`bin/valet-workspace lint valet-skills` checks that the manifests agree
on name and version, that both marketplaces agree, and that no
`hooks/hooks.json` exists. CI also runs
`claude plugin validate ./valet-skills --strict`.

## The MCP server

The plugin also declares Valet's own MCP server at
`https://api.valet.dev/mcp`, so installing it wires up the network path
alongside the skill. A compatible OAuth client performs dynamic client registration. A normal
call starts the connector's OAuth flow when needed; `anonymous: true`
is reserved for an explicitly temporary public site.

The server publishes websites and Procfile apps, reads back what an
organization has published, and reads and publishes the organization's
skills. `governance` is the entry skill: the server's instructions and
the `valet` skill both tell a model to read it with `get_skill` before any
work, and it names the other skills to read, `design-system` among
them. The server's `tools/list` answer describes the full tool
surface.

The `valet` skill uses the MCP tools when they are connected and fit the
work, and the `valet` CLI when the work needs it. Where the agent can run
Git with network access, the MCP tools publish a pushed commit, binary
files included; elsewhere they carry text files in the call. The CLI
also pushes with Git, and it keeps a visitor password out of the
conversation, which `set_service_access` cannot. The server is the only path where the CLI
cannot run — a sandbox whose outbound proxy refuses the install host, or
a harness with no shell — and the source of the organization's skills on
either path.

The CLI and MCP connector keep separate credentials. Claiming an
anonymous site signs the user into the browser and makes the site
permanent, but it cannot authenticate the connector. The next
account-first MCP call starts that client's OAuth flow.

Two files declare it, because no single format reaches both clients:

| File | Read by | Transport name |
|---|---|---|
| `mcp.json` | Agent Plugins 1.0.0 clients (§7.2) | `streamable-http` |
| `.mcp.json` | Claude Code | `http` |

They must stay in agreement. `bin/valet-workspace lint valet-skills`
compares them and fails on a server or URL that appears in one and not
the other.

## The publishing preference

The Claude Code plugin ships two hooks, both running
[`claude/prefer-valet.py`](claude/prefer-valet.py):

- **`SessionStart`** states the preference once per session: offer a
  Valet page, and publish once the user agrees. This is the half that
  does the real work — deciding to render a page is usually the model's
  own call, and nobody says "publish this" out loud.
- **`PreToolUse`** on Claude Code's `Artifact` tool asks whether to
  publish through Valet instead. It is a safety net, not the mechanism:
  a tool that is never called cannot be intercepted.

It defaults to *asking*, not blocking, because sometimes an artifact is
genuinely what you want. Set `VALET_PUBLISH_HOOK` to change that:

| Value | Behaviour |
|---|---|
| `ask` | Default. Proposes Valet; you decide per call. |
| `deny` | Blocks `Artifact` outright. For teams with a policy. |
| `off` | Disables the hooks without uninstalling. |

The hook stays silent whenever the `valet` CLI is not on `PATH`, so a
machine with the plugin but no CLI still gets a working artifact rather
than a dead end.

## Usage

Launch Claude Code or another coding agent and use the `/valet` command:

```
$ claude

> /valet build me an agent that reviews PRs for security vulnerabilities
```

The skill handles the full lifecycle — publishing sites and apps, creating an agent's workspace, writing its SOUL.md and skills, configuring channels, and deploying to Valet.

## What it does

Agents are defined by prompts, not code. A workspace is a directory:

```
my-agent/
  SOUL.md              # Agent identity
  skills/              # Agent capabilities
    <skill-name>/
      SKILL.md
  channels/            # Event triggers (webhooks, cron, messages)
```

The Valet skill helps you create this structure, iterate on it, and deploy it — all from within your coding agent.

## CLI

You can also install the Valet CLI directly:

macOS or Linux:

```
curl -fsSL https://valet.dev/install.sh | sh
valet auth login
```

Windows PowerShell:

```
irm https://valet.dev/install.ps1 | iex
valet auth login
```

Existing Homebrew installations remain supported:

```
brew install valetdotdev/tap/valet
valet auth login
```

To migrate from Homebrew later, uninstall the formula and run the direct
installer for the platform. The CLI will then use direct self-updates.

## Docs

Full documentation at [valet.dev/docs](https://valet.dev/docs).

## Support

[support@valet.dev](mailto:support@valet.dev)
