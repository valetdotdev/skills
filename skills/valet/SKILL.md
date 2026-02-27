---
name: valet
description: Use when the user wants to manage Valet agents, channels, connectors, organizations, or secrets via the valet CLI. Handles creation, deployment, linking, teardown, and all multi-step workflows. Also use when asked to "create an agent", "deploy an agent", "create a connector", "set up a webhook", or anything involving the Valet platform or any request to create and deploy AI agents.
---

You are an expert at using the Valet CLI to manage AI agents on the Valet platform. You execute `valet` commands via the Bash tool to accomplish tasks. Always confirm destructive actions (destroy, remove, revoke) with the user before running them.

## Installation

If `valet` is not installed, install it with:

```
brew install valetdotdev/tap/valet-cli
```

## Prerequisites

The user must be logged in before any other command will work:

```
valet auth login
```

Check auth status with `valet auth whoami`.

## Core Concepts

- **Agent**: An AI agent defined by a `SOUL.md` file in a project directory. Agents are deployed as versioned releases.
- **Connector**: An MCP (Model Context Protocol) server that provides tools to agents. Transports: `stdio`, `sse`, `streamable-http`.
- **Channel**: A message entry point (e.g., webhook) that routes external messages to agents via bindings.
- **Binding**: Connects a channel to an agent with a session strategy and a prompt path (defaults to `channels/<binding-name>.md`).
- **Session strategy**: `per_invocation` (new session per message, the default) or `persistent` (maintains state across messages).
- **Channel prompt file**: A markdown file at `channels/<binding-name>.md` inside the agent project that tells the agent how to handle messages arriving on that binding.
- **Organization**: A shared workspace for teams. Agents, connectors, and secrets can be scoped to an org using the `--org <org-name>` flag. When the user is working within an org context, pass `--org` to agent, connector, and secrets commands.
- **Default org**: A persistent preference stored in `config.json`. When set, `agents create` and `connectors create` automatically target the default org unless `--personal` is passed.

## Agent Lifecycle

### Create an agent

The current directory must contain a `SOUL.md` file. This creates the agent, links the directory, and deploys v1:

```
valet agents create [name] [--org <org-name>] [--personal]
```

Name is optional; the server generates one if omitted. Use `--org` to create within a specific organization, or `--personal` to create in your personal workspace even when a default org is set.

When a default org is configured, `agents create` automatically targets it. Pass `--personal` to bypass the default org.

### Link a directory to an existing agent

```
valet agents link <name>
```

Creates `.valet/config.json` so subsequent commands auto-detect the agent.

### Deploy a new release

After editing `SOUL.md` or other files, deploy the changes:

```
valet agents deploy [name]
```

If no name is given, uses the linked agent from the current directory.

### List agents

```
valet agents
```

Output is grouped: `== personal` first, then each org alphabetically. Every agent belongs to exactly one group.

### Destroy an agent

```
valet agents destroy [name]
```

Permanently removes the agent and all releases. Cannot be undone.

## Connectors (MCP Tool Access)

### Create a stdio connector (local command)

```
valet connectors create <name> [--org <org-name>] [--personal] \
  --transport stdio \
  --command <cmd> \
  --args <comma-separated-args> \
  --env KEY=VAL
```

Example — Slack MCP server:
```
valet connectors create slack-server \
  --transport stdio \
  --command npx \
  --args -y,@modelcontextprotocol/server-slack \
  --env SLACK_BOT_TOKEN=secret:SLACK_BOT_TOKEN \
  --env SLACK_TEAM_ID=secret:SLACK_TEAM_ID
```

**Important**: `--args` takes comma-separated values, not space-separated. Multiple `--env` flags for multiple environment variables. Use `--personal` to create in your personal workspace when a default org is set.

### Create a remote connector (SSE or streamable-http)

```
valet connectors create <name> [--org <org-name>] [--personal] \
  --transport streamable-http \
  --url https://mcp.example.com/mcp
```

For SSE:
```
valet connectors create <name> [--org <org-name>] [--personal] \
  --transport sse \
  --url https://mcp.example.com/sse
```

Use `--header KEY=VAL` for auth headers if needed.

### Auto-attach behavior

When you run `valet connectors create` inside a linked agent directory, the connector is automatically attached to that agent and a new release is deployed.

### Manually attach/detach

```
valet connectors attach <connector-name> [agent-name]
valet connectors detach <connector-name> [agent-name]
```

### Inspect and list

```
valet connectors
valet connectors info <name> [--org <org-name>]
```

Output is grouped: `== personal` first, then each org alphabetically.

### Destroy a connector

```
valet connectors destroy <name> [--org <org-name>]
```

Detaches from all agents. Cannot be undone.

## Channels (Message Entry Points)

### Create a webhook channel

```
valet channels create webhook [name] \
  --agent <agent-name> \
  --as <binding-name> \
  --session-strategy per_invocation \
  --signature-header X-Hub-Signature-256
```

Flags:
- `--agent` or `-a`: Agent to bind to (uses linked agent if omitted)
- `--as`: Binding name (defaults to channel name). This determines the channel prompt file path: `channels/<binding-name>.md`
- `--session-strategy` or `-s`: `per_invocation` (default) or `persistent`
- `--signature-header`: Header name for HMAC verification (default: `X-Webhook-Signature`)
- `--no-secret`: Skip secret generation
- `--prompt`: Override prompt path (default: `channels/<binding>.md`)

The command outputs:
- **Webhook URL**: The endpoint external services send messages to
- **Webhook secret**: The HMAC-SHA256 signing secret
- **Binding details**: Which agent, prompt path, and session strategy

### Attach/detach agents

```
valet channels attach <channel-name> --agent <agent-name> --as <binding-name>
valet channels detach <channel-name> --agent <agent-name>
```

### Inspect and list

```
valet channels [--agent <agent-name>]
valet channels info <name>
```

### Destroy a channel

```
valet channels destroy <name>
```

Removes the channel and all its bindings. Cannot be undone.

## Organizations

### List your organizations

```
valet orgs
```

The current default org is marked with `(default)` in the output.

### Create an organization

```
valet orgs create <name>
```

Automatically sets the new org as the default org.

### Set the default org

Show, set, or clear the default org:

```
valet orgs default            # show current default org
valet orgs default <name>     # set default org
valet orgs default --clear    # clear the default org
```

The default org is stored in `config.json` and is auto-set when you create or join an org, and auto-cleared when you leave or destroy the matching org. When set, `agents create` and `connectors create` target it automatically.

### Destroy an organization

```
valet orgs destroy <name>
```

Permanently removes the org. Cannot be undone. Clears the default org if it matched.

### Organization info

```
valet orgs info <name>
```

### Invite a member to an org

```
valet orgs invite <name> <email>
```

Generates an invitation code.

### Join an org via invitation

```
valet orgs join <code>
```

Automatically sets the joined org as the default org.

### Leave an organization

```
valet orgs leave <name>
```

Clears the default org if it matched.

### List org members

```
valet orgs members <name>
```

Shows members and pending invitations.

### Remove a member from an org

```
valet orgs remove <name> <email>
```

### Revoke a pending org invitation

```
valet orgs revoke <name> <email>
```

## Secrets

Secrets keep sensitive values (API keys, tokens) outside the LLM context. Connectors reference secrets using the `secret:NAME` syntax in `--env` values.

### List secrets

```
valet secrets [--agent <name> | --org <name>]
```

### Set secrets

```
valet secrets set <NAME=VALUE>... [--agent <name> | --org <name>]
```

### Remove a secret

```
valet secrets unset <NAME> [--agent <name> | --org <name>] [--force]
```

### Critical: Handling secrets safely

**NEVER ask the user for secret values within the LLM session.** Instead:

1. Tell the user what secrets they need to configure.
2. Direct them to run `valet secrets set NAME=VALUE` in their terminal (outside the LLM). Include `--org <org-name>` when working in an org context, or `--agent <name>` if not in a linked directory.
3. Wait for the user to confirm they have set the secrets before proceeding.

When creating connectors that need secrets, reference them with `secret:NAME` in `--env` flags:

```
valet connectors create my-connector \
  --transport stdio \
  --command npx \
  --args -y,@some/mcp-server \
  --env API_KEY=secret:API_KEY
```

## Log Drains

### List log drains

```
valet drains [--agent <name>]
```

### Create a log drain

```
valet drains create <endpoint> [--agent <name>] [--header Key=Value]
```

Logs are delivered as OTLP JSON via HTTP POST.

### Destroy a log drain

```
valet drains destroy <endpoint> [--agent <name>]
```

### Inspect a log drain

```
valet drains info <endpoint> [--agent <name>]
```

## Process Management

### List processes

```
valet ps [name]
```

Lists processes for a deployed agent.

### Restart processes

```
valet ps restart [name]
```

Restarts all processes. Picks up env/secret changes without redeploying.

## Run

Send a single prompt to an agent and stream the response:

```
valet run <agent> <prompt> [--json] [--timeout duration]
```

Useful for testing agents without starting an interactive console session.

## Logs

Stream live logs from a deployed agent:

```
valet logs [name]
```

Press Ctrl+C to stop streaming.

## Interactive Console

Start a REPL session with an agent:

```
valet console [name]
```

Uses the linked agent if no name is provided.

## Common Multi-Step Workflows

### Full agent setup with connectors and webhook

1. Create the agent from a directory with `SOUL.md`:
   ```
   cd my-agent-project
   valet agents create my-agent
   ```

2. Direct the user to set any needed secrets in their terminal (outside the LLM):
   ```
   valet secrets set GITHUB_TOKEN=ghp_...
   ```

3. Create MCP connectors referencing secrets (auto-attaches if in linked directory):
   ```
   valet connectors create github-server \
     --transport stdio \
     --command npx \
     --args -y,@modelcontextprotocol/server-github \
     --env GITHUB_PERSONAL_ACCESS_TOKEN=secret:GITHUB_TOKEN
   ```

4. Create a webhook channel with a binding:
   ```
   valet channels create webhook \
     --as my-binding \
     --signature-header X-Hub-Signature-256
   ```

5. Create the channel prompt file at `channels/my-binding.md` that tells the agent how to process incoming messages. See [Writing channel prompt files](#writing-channel-prompt-files) for guidance on scoping.

6. Deploy to pick up the channel prompt file:
   ```
   valet agents deploy
   ```

### Setting up an org-owned agent

1. Create the agent within an org:
   ```
   cd my-agent-project
   valet agents create my-agent --org my-org
   ```

2. Direct the user to set secrets scoped to the org:
   ```
   valet secrets set API_KEY=... --org my-org
   ```

3. Create connectors within the org:
   ```
   valet connectors create my-connector --org my-org \
     --transport stdio \
     --command npx \
     --args -y,@some/mcp-server \
     --env API_KEY=secret:API_KEY
   ```

4. Continue with channels, channel prompt files, and deploy as usual.

### Using the default org

If you work primarily within one org, set it as the default so you don't have to pass `--org` every time:

```
valet orgs default my-org
```

After this, `agents create` and `connectors create` automatically target `my-org`. To create something in your personal workspace instead:

```
valet agents create my-agent --personal
```

To stop using a default org:

```
valet orgs default --clear
```

### Complete teardown (order matters)

Destroy channels and connectors before the agent:

```
valet channels destroy <channel-name>
valet connectors destroy <connector-name>
valet agents destroy <agent-name>
```

### Adding a new connector to an existing agent

First, have the user set any needed secrets in their terminal:
```
valet secrets set API_KEY=...
```

Then create the connector referencing the secret:
```
cd my-agent-project
valet connectors create new-tool \
  --transport stdio \
  --command npx \
  --args -y,@some/mcp-server \
  --env API_KEY=secret:API_KEY
```

If the directory is linked, this auto-attaches and deploys.

### Redeploying after changes

After editing `SOUL.md`, channel prompt files, or other agent files:

```
valet agents deploy
```

## Writing Channel Prompt Files

A channel prompt file tells the agent what to do when a webhook arrives. Webhooks are **transactional** — each one represents a specific event (an email, a push, a form submission) and carries identifiers for the content that changed. The channel prompt file must scope the agent's actions to that transaction.

**The core principle**: The webhook payload provides the keys (a thread ID, a commit SHA, a PR number, etc.) that define the agent's scope of work. The agent should use every tool at its disposal to understand and act on that specific content — but it must not wander beyond it.

Without explicit scoping, agents treat the webhook as a wake-up call and act across all available context (listing all emails, scanning all PRs, etc.). The channel prompt file prevents this.

### Structure of a channel prompt file

A channel prompt file should contain:

1. **What happened** — a plain description of the event.
2. **What to extract** — which fields from the payload identify the transaction (IDs, refs, names).
3. **Scope boundary** — an explicit statement that all actions must be scoped to the content identified by those fields.
4. **What to do** — step-by-step instructions for processing.

### Example: email webhook

```markdown
# New Email Received

You received a webhook for a single new email.

## Scope

Extract the `thread_id` from the payload. All actions in this invocation
are scoped to this thread. You may use any tools to read, understand,
and reply to this thread — but do not list, read, or act on any other
threads or messages in the inbox.

## Steps

1. Extract `thread_id`, `from_`, `subject`, and `text` from the payload.
2. [... task-specific steps ...]
```

### Example: GitHub push webhook

```markdown
# GitHub Push Event

You received a push event webhook.

## Scope

Extract the `ref` and `commits` array from the payload. Your scope of
work is limited to the changes introduced by these specific commits.
You may fetch file contents, read diffs, and use tools to understand
what changed — but do not scan the broader repository, other branches,
or unrelated history.

## Steps

1. Parse the `commits` array from the payload.
2. [... task-specific steps ...]
```

### Reinforcing scope in SOUL.md

The channel prompt file scopes each invocation, but the agent's `SOUL.md` should reinforce the general principle so it applies across all channels:

```markdown
## Webhook Scope Rule

When you receive a webhook, your scope of work is defined by the
identifiers in the payload (thread IDs, commit SHAs, PR numbers, etc.).
Use any tools you need to fully understand and act on that specific
content, but do not act on unrelated content beyond what the webhook
identifies.
```

## Agent Project Structure

A typical agent project directory:

```
my-agent/
  SOUL.md              # Agent personality and behavior (required)
  channels/            # Channel prompt files for bindings
    my-binding.md      # Prompt for messages on "my-binding"
  scripts/             # Utility scripts (optional)
  .valet/
    config.json        # Created by link/create (auto-managed)
```

## Help and Discovery

```
valet help                          # Top-level help
valet help <command>                # Command-specific help
valet <command> <subcommand> --help # Subcommand help
valet topics                        # List help guides
valet topics <name>                 # Read a specific guide
valet version                       # Print CLI version
```

Useful topics:
- `getting-started` — initial setup walkthrough
- `agent-lifecycle` — creating, deploying, and managing agents
- `channels-and-bindings` — channels, bindings, and session strategies
- `connectors-overview` — connector types and configuration

## Execution Guidelines

- Always run commands via the Bash tool.
- When the user asks to set up an agent, guide them through the full workflow (create, connectors, secrets, channels, channel prompt files, deploy).
- **Never ask for secret values inside the LLM session.** Direct the user to run `valet secrets set NAME=VALUE` in their own terminal and wait for them to confirm before proceeding. When creating connectors that need secrets, reference them with `secret:NAME` in `--env` flags.
- When the user is working within an org, pass `--org <org-name>` to agent, connector, and secrets commands — or help them set a default org with `valet orgs default <name>` so they don't have to repeat it.
- If a command fails, read the error output and troubleshoot. Common issues:
  - Not logged in: run `valet auth login`
  - No `SOUL.md` in directory: create one or `cd` to the right directory
  - Not linked: run `valet agents link <name>`
- For destructive commands (`destroy`, `remove`, `revoke`), always confirm with the user first.
- When creating webhook channels, always save and report back the webhook URL and secret — the user will need these.
