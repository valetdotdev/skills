# Valet Skills

The [Valet](https://valet.dev) skill for Claude Code and other coding agents. Build, deploy, and run skilled AI agents from your terminal.

> **This repository is a generated mirror.** The source of truth lives in Valet's `ark` monorepo under `valet-skills/`, and changes are synced here automatically on merge. Please don't open PRs against this repo — reach us at [support@valet.dev](mailto:support@valet.dev).

## Skills

| Skill | What it does |
|-------|--------------|
| `valet` | Build, deploy, and run skilled AI agents from your terminal. |
| `valet-publish` | Publish files and folders to a live URL — no account, no CLI. |

## Install

Both skills:

```
npx skills add valetdotdev/skills
```

Or one of them:

```
npx skills add valetdotdev/skills --skill valet -g
npx skills add valetdotdev/skills --skill valet-publish -g
```

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

```
brew install valetdotdev/tap/valet
valet auth login
```

## Docs

Full documentation at [valet.dev/docs](https://valet.dev/docs).

## Support

[support@valet.dev](mailto:support@valet.dev)
