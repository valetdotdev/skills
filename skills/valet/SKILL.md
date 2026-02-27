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
- **Binding**: Connects a channel to an agent with a session strategy and a prompt path (defaults to `hooks/<binding-name>.md`).
- **Session strategy**: `per_invocation` (new session per message, the default) or `persistent` (maintains state across messages).
- **Hook file**: A markdown file at `hooks/<binding-name>.md` inside the agent project that tells the agent how to handle messages arriving on that binding.
- **Organization**: A shared workspace for teams. Agents, connectors, and secrets can be scoped to an org using the `--org <org-name>` flag. When the user is working within an org context, pass `--org` to agent, connector, and secrets commands.

## Agent Lifecycle

### Create an agent

The current directory must contain a `SOUL.md` file. This creates the agent, links the directory, and deploys v1:

```
valet agents create [name] [--org <org-name>]
```

Name is optional; the server generates one if omitted. Use `--org` to create within an organization.

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
valet agents [--org <org-name>]
```

### Destroy an agent

```
valet agents destroy [name]
```

Permanently removes the agent and all releases. Cannot be undone.

## Connectors (MCP Tool Access)

### Create a stdio connector (local command)

```
valet connectors create <name> [--org <org-name>] \
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

**Important**: `--args` takes comma-separated values, not space-separated. Multiple `--env` flags for multiple environment variables.

### Create a remote connector (SSE or streamable-http)

```
valet connectors create <name> [--org <org-name>] \
  --transport streamable-http \
  --url https://mcp.example.com/mcp
```

For SSE:
```
valet connectors create <name> [--org <org-name>] \
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
valet connectors [--org <org-name>]
valet connectors info <name> [--org <org-name>]
```

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
- `--as`: Binding name (defaults to channel name). This determines the hook file path: `hooks/<binding-name>.md`
- `--session-strategy` or `-s`: `per_invocation` (default) or `persistent`
- `--signature-header`: Header name for HMAC verification (default: `X-Webhook-Signature`)
- `--no-secret`: Skip secret generation
- `--prompt`: Override prompt path (default: `hooks/<binding>.md`)

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

### Create an organization

```
valet orgs create <name>
```

### Destroy an organization

```
valet orgs destroy <name>
```

Permanently removes the org. Cannot be undone.

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

### Leave an organization

```
valet orgs leave <name>
```

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

### Inject secrets into a local process

`valet exec` fetches decrypted secret values from the control plane and injects them into a child process as environment variables via `exec`. Useful for local development workflows where a tool needs the same secrets your agent uses:

```
valet exec --secrets <NAME>[,<NAME>...] [--agent <name>] -- <command> [args...]
```

Examples:
```
valet exec --secrets GITHUB_TOKEN --agent my-agent -- gh pr list
valet exec --secrets GITHUB_TOKEN,SLACK_TOKEN -- env
```

- `--secrets`: Comma-separated list of secret names to fetch and inject.
- `--agent`: Agent whose secret scope to use (uses the linked agent if omitted).

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

5. Create the hook file at `hooks/my-binding.md` that tells the agent how to process incoming messages.

6. Deploy to pick up the hook file:
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

4. Continue with channels, hooks, and deploy as usual.

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

After editing `SOUL.md`, hook files, or other agent files:

```
valet agents deploy
```

## Agent Project Structure

A typical agent project directory:

```
my-agent/
  SOUL.md              # Agent personality and behavior (required)
  hooks/               # Hook files for channel bindings
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
- When the user asks to set up an agent, guide them through the full workflow (create, connectors, secrets, channels, hooks, deploy).
- **Never ask for secret values inside the LLM session.** Direct the user to run `valet secrets set NAME=VALUE` in their own terminal and wait for them to confirm before proceeding. When creating connectors that need secrets, reference them with `secret:NAME` in `--env` flags.
- When the user is working within an org, pass `--org <org-name>` to agent, connector, and secrets commands.
- If a command fails, read the error output and troubleshoot. Common issues:
  - Not logged in: run `valet auth login`
  - No `SOUL.md` in directory: create one or `cd` to the right directory
  - Not linked: run `valet agents link <name>`
- For destructive commands (`destroy`, `remove`, `revoke`), always confirm with the user first.
- When creating webhook channels, always save and report back the webhook URL and secret — the user will need these.
