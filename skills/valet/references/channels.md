# Channels

A channel wakes an agent. Read the `channels` skill first: it owns
choosing the kind, what a person must finish in a browser, and who a
channel lets in. This file gives the commands and how to write a channel
file.

## Find and attach

```
valet channels catalog                       # MCP: list_catalog_channels
valet channels catalog get <entry>
valet channels --org <org>                   # MCP: list_channels
valet channels info <name>
valet channels attach <name> --agent <agent> [--as <alias>] [--events <types>]
                                             # MCP: attach_channel
valet channels detach <name> --agent <agent> # MCP: detach_channel
```

An organization webhook channel can serve several agents, each with its
own `--events` filter, `--events pull_request,issue_comment` for
example.

## Create

Over MCP, `create_channel` makes `cron`, `heartbeat`, `webhook`, and
`mcp` channels. On the CLI:

```
valet channels create <entry> --org <org> [--as <name>]   # from the catalog
valet channels create webhook [name] --agent <agent> [--verify <scheme>]
valet channels create cron [name] --agent <agent> --schedule "every day at 9am"
valet channels create cron [name] --agent <agent> --cron "0 9 * * *" [--timezone <zone>]
valet channels create heartbeat [name] --agent <agent> --every 5m
valet channels create mcp [name] --agent <agent>
valet channels create telegram [name] --agent <agent>
```

An agent's `valet.yaml` can also declare `cron`, `heartbeat`, and `mcp`
channels inline; see `references/agents.md`.

**Webhook.** `--verify` takes `hmac-sha256` (the default), `slack`,
`stripe`, `svix`, `static-token`, or `none`. `slack`, `stripe`, and
`svix` need `--secret-name`, naming a secret already set. A catalog
entry handles a service's signing for you. The command prints the
webhook URL, the signing secret, and the name of any managed secret.
Report the URL and the secret's name, never the secret itself; the
person copies it from their terminal. When your shell's output reaches
the conversation, prefer `--secret-name` with a secret the person set
themselves.

**MCP.** An `mcp` channel serves the agent as an MCP server. Mint a
bearer token for a client with
`valet channels token mint <channel> <token-name>`.

**Telegram.** The command prints a `t.me` link the person opens to
connect.

**Slack** takes two steps:

1. Once per organization, `valet channels create slack --org <org>`.
   The CLI asks for a Slack app configuration access token and refresh
   token, from api.slack.com/apps. Skip this when `valet channels --org
   <org>` already lists `slack`.
2. Once per agent, `valet channels create slack --agent <agent>
   --bot-name <display-name>`, or `valet channels attach slack --agent
   <agent> --bot-name <display-name>`. This makes the agent its own
   Slack app and opens a browser to install it.

Always pass `--bot-name`. Detaching an agent's Slack channel destroys
its bot, and destroying the organization's Slack channel destroys every
agent's bot. The CLI asks first; pass `--force` only after the person
confirms. `valet channels slack --help` covers how actively the bot
joins each conversation.

When an authorization lapses, `valet channels reauthorize <name>`, or
`reauthorize_channel`, gives the person a new link.

## Write a channel file

`channels/<name>.md` in the agent's source tells the agent what to do
when that channel fires. Write it as direct instructions to the agent.

A webhook's payload follows the file in the same message, so start every
webhook channel file with:

```
The JSON webhook payload is appended directly after these instructions
in the user message. Parse it inline — do not fetch, list, or search
for the payload elsewhere. Do NOT use tools to read the payload.
```

Then say what happened, which payload fields identify it, a scope
limited to those identifiers, and the steps:

```markdown
# New Email Received

<the payload instruction above>

You received a webhook for a single new email.

## Scope

Extract the `thread_id` from the payload. All actions are scoped to
this thread. Do not list, read, or act on any other threads.

## Steps

1. Extract `thread_id`, `from_`, `subject`, and `text` from the payload.
2. <the task's steps>
```

Publish the agent again after changing a channel file.
