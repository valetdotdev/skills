---
name: valet
display_name: Valet CLI
version: "1.0"
description: Use when the user wants to manage Valet agents,
  channels, connectors, or members via the valet CLI.
prompt_type: system
---

# Valet CLI Skill

Use this skill when the user wants to create, deploy, or manage Valet agents, connectors, channels, or members.

## Installation

```bash
brew install valetdotdev/tap/valet
```

## Authentication

```bash
valet auth login      # log in
valet auth whoami     # check current user
```

## Agents

### Create and deploy an agent

The current directory must contain a `SOUL.md` file:

```bash
valet agents create [name]
```

Create from a local path, Git URL, or catalog reference:

```bash
valet agents create my-reviewer --from catalog:code-reviewer --org acme
```

Attach org-scoped connectors and channels before the first deploy:

```bash
valet agents create my-bot --org acme \
  --attach-connector github \
  --attach-channel gh-webhook
```

`--attach-connector` and `--attach-channel` are repeatable. The resources are attached after agent creation and before the first release is deployed, so the container starts with them already wired.

For the full flag list: `valet agents create --help`

### Other agent commands

```bash
valet agents                        # list agents
valet agents deploy [-a <name>]     # deploy a new release
valet agents link <name>            # link directory to existing agent
valet agents destroy <name>         # permanently remove agent
```

## Connectors

### Add a connector from the catalog

```bash
valet connectors add <catalog-entry> [-a <agent>] [--org <org>]
```

Provisions an org-scoped connector from the Valet catalog. If a `valet.yaml` manifest exists in the current directory, the catalog entry is automatically added to it.

### Create a custom connector

```bash
# stdio
valet connectors create <name> \
  --transport stdio \
  --command npx \
  --args -y,@modelcontextprotocol/server-slack \
  --env SLACK_BOT_TOKEN=xoxb-...

# remote (streamable-http or sse)
valet connectors create <name> \
  --transport streamable-http \
  --url https://mcp.example.com/mcp
```

When run inside a linked agent directory, the connector is automatically attached and a new release is deployed.

### Other connector commands

```bash
valet connectors                          # list
valet connectors info <name>              # details
valet connectors attach <name> [-a agent] # attach to agent
valet connectors detach <name> [-a agent] # detach from agent
valet connectors destroy <name>           # remove
```

For full options: `valet connectors --help`

## Channels

### Add a channel from the catalog

```bash
valet channels add <catalog-entry> [--agent <agent>] [--org <org>] [--as <name>]
```

Provisions a channel (agent-scoped or org-scoped) from the Valet catalog. If a `valet.yaml` manifest exists in the current directory, the catalog entry is automatically added to it.

### Attach/detach org channels to agents

Org-scoped channels must be attached to an agent before messages are routed to it:

```bash
# attach
valet channels attach <channel-name> [-a <agent>] [--as <alias>] [--events push,pull_request]

# detach
valet channels detach <alias> [-a <agent>]
```

`--as` gives the attachment a custom alias (useful when attaching the same channel to multiple agents). `--events` filters which event types are routed.

### Create channels directly

```bash
valet channels create webhook [name] --agent <agent>
valet channels create cron [name] --agent <agent> --schedule "every day at 9am"
valet channels create heartbeat [name] --agent <agent> --every 5m
valet channels create telegram [name] --agent <agent>
```

For the full flag list: `valet channels create --help`

### Other channel commands

```bash
valet channels [--agent <agent>] [--org <org>]    # list
valet channels info <name> [--agent <a>]          # details
valet channels destroy <name> [--agent <a>]       # remove
```

## Members

```bash
valet members <agent>                   # list
valet members invite <agent> <email>    # invite (7-day code)
valet members join <code>               # accept invite
valet members remove <agent> <email>    # remove
valet members revoke <agent> <email>    # revoke pending invite
```

## Orgs

```bash
valet orgs                     # list orgs
valet orgs default [name]      # get or set default org
```

## Help index

```bash
valet help                     # top-level help
valet help <command>           # command help
valet topics                   # list help guides
valet topics <name>            # read a guide
valet <command> --help         # subcommand flags
```

## Common multi-step workflow

```bash
# 1. Create agent (attaches org connector + channel before deploy)
valet agents create my-bot --org acme \
  --attach-connector github \
  --attach-channel gh-webhook

# 2. Deploy after editing SOUL.md or channel files
valet agents deploy

# 3. Tear down (channels and connectors first)
valet channels destroy my-channel
valet connectors destroy my-connector
valet agents destroy my-agent
```
