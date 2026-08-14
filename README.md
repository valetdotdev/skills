# Valet Skills

The [Valet](https://valet.dev) skill for Claude Code and other coding agents. Build, deploy, and run skilled AI agents from your terminal.

> **This repository is a generated mirror.** The source of truth lives in Valet's `ark` monorepo under `valet-skills/`, and changes are synced here automatically on merge. Please don't open PRs against this repo — reach us at [support@valet.dev](mailto:support@valet.dev).

## Skills

| Skill | What it does |
|-------|--------------|
| `valet` | Build, deploy, and run skilled AI agents from your terminal. |
| `valet-publish` | Publish files and folders to a live URL, account-first or explicitly anonymous. |

## Install

### As a plugin (recommended)

One plugin: both skills, Valet's MCP server, and the publishing
preference.

Claude Code:

```
/plugin marketplace add valetdotdev/skills
/plugin install valet@valet
```

Codex reads the same marketplace manifest:

```
codex plugin marketplace add valetdotdev/skills
codex plugin add valet@valet
```

The two skills stay separate inside it, each with its own triggers, so
only the one that fires pays its cost. The plugin adds ~510 tokens per
session for both descriptions.

On Claude Code this installs the skills, declares the MCP server, **and**
wires up the publishing preference.

On Codex it installs the skills and the MCP server, which is enough on
its own — Codex has retired plugin-delivered hooks (`codex features
list` reports `plugin_hooks` as `removed`), so the preference is an
optional manual step there. Installing it takes two things, not one:
writing the hook file *and* granting Codex's hook trust, or it is
skipped silently. See
[`codex/README.md`](codex/README.md).

### As a skill only

Reach for this to install **one** skill rather than both, or to take the
skills without the MCP server — the plugin is all-or-nothing. Works with
any agent that reads
[`npx skills`](https://github.com/vercel-labs/skills):

```
npx skills add valetdotdev/skills --skill valet-publish -g
npx skills add valetdotdev/skills --skill valet -g
```

Or both:

```
npx skills add valetdotdev/skills
```

Pick this **or** the plugin, not both — Codex loads skills from
`~/.agents/skills/` and from installed plugins, so installing both puts
two copies of the same skill in front of the model.

### Agent Plugins

The repository is also a conformant
[Agent Plugins 1.0.0](https://agent-plugins.org) package: `plugin.json`
at the root, skills in `skills/`, MCP servers in `mcp.json`. A client
implementing that specification can load it from a directory path with
no Valet-specific knowledge.

The hooks are a client extension and sit outside that specification,
which defines no portable hook format — so a conformant client gets the
skills and the MCP server, and the publishing preference only where its
own hook system is wired up.

## The MCP server

The plugin also declares Valet's own MCP server at
`https://api.valet.dev/mcp`, so installing it wires up the network path
alongside the skills. The server registers the client itself. A normal
publish starts the connector's OAuth flow when needed; `anonymous: true`
is reserved for an explicitly temporary public site.

The CLI and MCP connector keep separate credentials. Claiming an
anonymous site signs the user into the browser and makes the site
permanent, but it cannot authenticate the connector. The next
account-first MCP call starts that client's OAuth flow.

It is there as the fallback the skills already describe, not as the
main road. `valet-publish` drives the `valet` CLI, which publishes a
whole directory from disk, updates a site later from anywhere, sets
password access, and carries binary files — none of which the MCP
tools can do. The server matters where the CLI cannot run: a sandbox
whose outbound proxy refuses the install host, or a harness with no
shell. Before the plugin declared it, reaching that fallback meant
asking the user to add a connector by hand, mid-task, in a settings
screen. Now it is already there.

Two files declare it, because no single format reaches both clients:

| File | Read by | Transport name |
|---|---|---|
| `mcp.json` | Agent Plugins 1.0.0 clients (§7.2) | `streamable-http` |
| `.mcp.json` | Claude Code | `http` |

They must stay in agreement. `make lint-valet-skills` compares them and
fails on a server or URL that appears in one and not the other.

## The publishing preference

The `valet-publish` plugin ships two hooks, both running
[`hooks/prefer-valet-publish.py`](hooks/prefer-valet-publish.py):

- **`SessionStart`** states the preference once per session. This is the
  half that does the real work — deciding to render a page is usually
  the model's own call, and nobody says "publish this" out loud.
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

The skill handles the full agent lifecycle — creating the workspace, writing the SOUL.md and skills, configuring channels, and deploying to the Valet Cloud.

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
