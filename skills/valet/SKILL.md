---
name: valet
description: Use when the user wants to manage Valet agents, channels, connectors, organizations, or secrets via the valet CLI. Handles creation, deployment, linking, teardown, and all multi-step workflows. Also use when asked to "create an agent", "deploy an agent", "design an agent", "build me an agent that...", "create a connector", "set up a webhook", or anything involving the Valet platform or any request to create and deploy AI agents. Also use when asked to "learn from this session", "capture this workflow", "save this as an agent", "make this repeatable", or when writing SOUL.md files.
---

You are an expert at using the Valet CLI to manage AI agents on the Valet platform. You execute `valet` commands via the Bash tool to accomplish tasks. Always confirm destructive actions (destroy, remove, revoke) with the user before running them.

**Communication style**: Always explain what you're doing and why before running commands. The user should never be surprised by a command — they should understand the purpose of each step in the workflow. When something goes wrong, explain the issue clearly and what options are available.

## Installation

Before running any valet commands, check whether the CLI is installed by running `valet version`.

If `valet` is not installed, **explain to the user why it is needed before attempting installation**:

> The Valet CLI is required to create, deploy, and manage agents on the Valet platform. All valet commands depend on this CLI being installed locally. I'll install it for you now via Homebrew.

Then check whether Homebrew is available by running `brew --version`.

**If Homebrew is not installed**, ask the user whether they'd like to install Homebrew first. If they agree, install it with the official installer:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

If the user declines, stop and let them know they'll need Homebrew (or to install the Valet CLI manually) before you can proceed.

**If Homebrew is installed**, install the Valet CLI:

```
brew install valetdotdev/tap/valet-cli
```

**IMPORTANT — Homebrew failures**: If `brew install valetdotdev/tap/valet-cli` fails for any reason — tap errors, permission issues, network problems, formula conflicts, or anything else — **do not attempt to troubleshoot, retry, or work around the issue**. Instead, inform the user:

> It looks like the Homebrew installation didn't succeed. Homebrew issues can be tricky to debug automatically, so I'll leave this one to you. Please run `brew install valetdotdev/tap/valet-cli` in your terminal and resolve any issues manually. Once the CLI is installed, come back and we'll pick up where we left off.

Then **stop the current workflow**. Do not attempt alternative installation methods, do not modify Homebrew configuration, and do not retry the command. Wait for the user to confirm the CLI is installed before continuing.

## Prerequisites

After the CLI is installed, the user **must be authenticated** before any other command will work. Explain this to the user:

> Before we can create or manage agents, you need to be logged in to your Valet account. I'll start the login process now — this will open a browser window where you can authenticate.

Then run:

```
valet auth login
```

After login, verify the session is active with `valet auth whoami`. If authentication fails, let the user know and do not proceed with any other valet commands until they are successfully logged in.

## Using the Built-in Help

The Valet CLI has extensive built-in help. **Use it proactively** when you need details about a command, flag, or feature not covered in this skill file:

```
valet help                          # Top-level help
valet help <command>                # Command-specific help (e.g. valet help channels)
valet <command> <subcommand> --help # Subcommand help (e.g. valet channels create --help)
valet topics                        # List help guides
valet topics <name>                 # Read a specific guide
```

Useful topic guides: `getting-started`, `agent-lifecycle`, `channels`, `connectors-overview` (covers both MCP server and command connectors).

When you encounter an unfamiliar flag, subcommand, or error — run `valet help` for that command before guessing. The CLI help is authoritative and up to date.


## Onboarding

### Scaffold a new agent project

Create a new agent project directory without running the full setup flow:

```
valet new <name> [--dir <path>]
```

Creates `<name>/` (or the path specified by `--dir`) containing `SOUL.md`, `AGENTS.md`, `skills/`, and `channels/`. The project is ready to edit — update `SOUL.md` to define your agent, then run `valet agents create` to deploy it.

Flags:
- `--dir`: Directory to create the project in (default: `./<name>`)

## Core Concepts

- **Agent**: An AI agent defined by a `SOUL.md` file in a project directory. Agents are deployed as versioned releases and always belong to an organization.
- **Organization**: A team workspace that owns agents, connectors, channels, and secrets. All agents belong to an org — the default org is used when `--org` is omitted.
- **Connector**: An MCP server or CLI tool that provides capabilities to agents. Types: `mcp-server` (MCP tools via client) and `command` (CLI with secret injection). Transports: `stdio`, `sse`, `streamable-http`.
- **Channel**: A message entry point for agents. Types: `webhook`, `telegram`, `heartbeat`, `cron`. Each channel has a session strategy and a prompt path.
- **Secret**: An encrypted credential scoped to an agent or organization. Referenced with `{{NAME}}` template syntax in connector and channel configurations. Agent-scoped secrets override org-scoped secrets of the same name.
- **Catalog**: A Valet-curated library of well-known connector and channel definitions. Browse with `valet connectors catalog` or `valet channels catalog`. Add from the catalog instead of configuring from scratch.
- **Shared resources**: Connectors, channels, and secrets can be scoped to an org and shared across agents. The pattern is: add from catalog (or create) at the org level, then attach to agents that need them. This maximizes reuse and simplifies credential rotation.
- **Channel file**: A markdown file at `channels/<channel-name>.md` that tells the agent how to handle incoming messages.

## Resource Creation Principles

These principles apply to all connectors, channels, and secrets. Follow this priority order every time:

1. **Catalog first**: Check `valet connectors catalog` or `valet channels catalog` before creating from scratch. Catalog entries handle transport, commands, and secret slots automatically.
2. **Reuse existing**: Check `valet connectors --org <org>` or `valet channels --org <org>` for resources that already provide what you need. Attach rather than duplicate.
3. **Org-scoped by default**: Create resources at the org level (`--org`) so they can be shared across agents. Only use agent-scoped resources when a resource is truly single-agent.
4. **Secrets at org level**: Default to `--org` for secrets so connectors and channels shared across agents can all access them. Agent-scoped secrets override org-scoped ones of the same name when needed.
5. **Verify before deploying**: Test every secret-backed command locally with `valet exec` before deploying (see "Pre-Deploy Verification").

## Agent Lifecycle

### Create an agent

The current directory must contain a `SOUL.md` file. This creates the agent, links the directory, deploys v1, and waits for readiness:

```
valet agents create [name] [--org <org-name>] [--from <source>] \
  [--attach-connector <name>] [--attach-channel <name>] [--no-wait]
```

Name is optional (auto-generated if omitted). When `--org` is omitted, the default org is used. The default org is set automatically when you create or join an org.

Sources for `--from`:
- **Current directory (default)** — uses the `SOUL.md` in the current directory
- **Local path** — `--from .` or `--from ./path/to/agent`
- **Git URL** — `--from github.com/user/repo` clones and deploys from a remote repo
- **Catalog** — `--from catalog:name` creates from a Valet-curated agent template

Use `--attach-connector` and `--attach-channel` to wire org-scoped resources to the agent at creation time (repeatable flags).

### Link a directory

```
valet agents link <name>
```

Creates `.valet/config.json` so subsequent commands auto-detect the agent. Not needed if you created the agent from this directory.

### Deploy changes

After editing `SOUL.md`, channel files, or other project files:

```
valet agents deploy [-a <name>] [--no-wait]
```

### List agents

```
valet agents [--org <name> | -o <name>]
```

Lists agents in the default org, or the org specified with `--org` / `-o`. Errors with a helpful message if no default org is configured. Run `valet agents --help` for all options.

### Show agent details

```
valet agents info <name>
```

Displays owner, current release, process state, channels, and connectors.

### Destroy an agent

```
valet agents destroy <name> [--force]
```

Permanently removes the agent and all releases. Use `--force` to skip the confirmation prompt. Cannot be undone.

## Connectors

Connectors give agents access to MCP tools and CLI commands. Follow the Resource Creation Principles above.

### Browse the catalog

```
valet connectors catalog
valet connectors catalog get <name>
```

The catalog contains Valet-curated connector definitions for well-known services (GitHub, Slack, Sentry, Linear, etc.). Each entry defines transport, command, and required secret slots.

### Add from the catalog (preferred)

```
valet connectors add <entry> [--org <org>] [--agent <agent>] [--as <name>]
```

Adds a connector from the catalog. Use `--as` to rename the instance (useful for multiple instances with different credentials). Required secrets must already be set.

Example:
```
valet secrets set GITHUB_TOKEN=ghp_abc123 --org acme
valet connectors add github --org acme
```

### Create a custom connector

Only use `create` when the catalog doesn't have what you need:

```
valet connectors create <name> [--type <type>] \
  [--transport <type>] [--command <cmd>] [--args <args>] \
  [--url <url>] [--env K=V] [--header K=V] \
  [--secrets <names>] [--org <org>] [--agent <agent>]
```

Two types: `mcp-server` (default) and `command`. **Important**: `--args` takes comma-separated values. Use `{{NAME}}` to reference secrets.

```
# MCP server — stdio transport
valet connectors create slack-server --org acme \
  --transport stdio --command npx \
  --args -y,@modelcontextprotocol/server-slack \
  --env SLACK_BOT_TOKEN={{SLACK_BOT_TOKEN}} \
  --env SLACK_TEAM_ID={{SLACK_TEAM_ID}}
```

# MCP server — remote transport
valet connectors create <name> \
  --transport streamable-http \
  --url https://mcp.example.com/mcp \
  --header Authorization={{API_TOKEN}}
```

**Command connectors** (`--type command`) wrap CLI tools. They require `--command` and accept `--secrets` (comma-separated secret names injected at runtime):

```
valet connectors create gh --type command \
  --command gh --secrets GITHUB_TOKEN
```

Run `valet connectors create --help` for all flags.

### Attach / Detach

Attach an org connector to an agent. Use `--as` for a custom alias:

```
valet connectors attach <name> [--agent <agent>] [--as <alias>]
valet connectors detach <name> [--agent <agent>]
```

### List and inspect

```
valet connectors [--org <org>] [--agent <agent>]
valet connectors info <name>
```

`valet connectors info` shows name, type, transport, command, args, URL, env, headers, secrets (for connectors with `--secrets` configured), and catalog origin.

### Destroy a connector

```
valet connectors destroy <name>
```

## Channels

Channels are message entry points for agents. Follow the Resource Creation Principles above — the catalog encodes signing schemes and service-specific behaviors for webhook channels.

### Browse the catalog

```
valet channels catalog
valet channels catalog get <name>
```

The catalog contains Valet-curated channel definitions for well-known services (GitHub webhooks, Slack Events API, Stripe, etc.). Each entry defines signing scheme, event taxonomy, and required secret slots.

### Add from the catalog (preferred for webhooks)

```
valet channels add <entry> [--org <org>] [--agent <agent>] [--as <name>]
```

Adds a channel from the catalog. Use `--as` to rename the instance.

Example:
```
valet secrets set GITHUB_WEBHOOK_SECRET=whsec_abc123 --org acme
valet channels add github-webhook --org acme
```

### Attach / Detach

Attach an org channel to an agent. Use `--events` to filter which event types are delivered:

```
valet channels attach <name> [--agent <agent>] [--as <alias>] [--events <types>]
valet channels detach <name> [--agent <agent>]
```

Example:
```
valet channels attach github-webhook --agent my-reviewer --events pull_request,issue_comment
```

### Create a webhook channel

```
valet channels create webhook [name] \
  [--agent <agent-name>] [--org <org>] \
  [--verify <scheme>]
```

Verification schemes: `hmac-sha256` (default), `slack`, `stripe`, `svix`, `static-token`, `none`. Key flags: `--secret-name` (reference to a managed secret; required for `slack`, `stripe`, and `svix`), `--signature-header` (not used with `slack` or `svix`), `--delivery-key-header`, `--delivery-key-path`, `--prompt`. For `hmac-sha256` and `static-token`, a managed secret is auto-generated if `--secret-name` is omitted. The `slack` scheme implements Slack's Events API signing protocol and handles `url_verification` challenges automatically. Run `valet channels create webhook --help` for full details.

The command outputs the **webhook URL**, **signing secret**, and (if applicable) **managed secret name** — always save and report these to the user.

### Create a Slack channel

```
valet channels create slack [name] \
  [--agent <agent-name>] [--org <org>] \
  [--bot-name <display-name>]
```

Creates a Slack channel that enables agents to participate in your Slack workspace. Before creating the channel, the CLI automatically checks whether the org has a connected Slack workspace. If not connected, it prompts you to connect via OAuth, opens a browser window for authorization, and polls until the connection is confirmed. The `--bot-name` flag sets the Slack bot display name (default: agent name, resolved server-side). The command outputs the bot name and workspace after setup. Run `valet channels create slack --help` for all flags.

### Create a heartbeat channel

```
valet channels create heartbeat [name] --agent <agent-name> --every 5m
```

Fires a prompt on a fixed interval. Run `valet channels create heartbeat --help` for all flags.

### Create a cron channel

```
valet channels create cron [name] --agent <agent-name> --schedule "every day at 9am"
# Or with a raw crontab expression:
valet channels create cron [name] --agent <agent-name> --cron "0 9 * * *"
```

Run `valet channels create cron --help` for all flags (`--timezone`, `--prompt`, etc.).

### List, inspect, destroy

```
valet channels [--org <org>] [--agent <agent>]
valet channels info <name>
valet channels destroy <name>
```

## Secrets

Secrets are encrypted credentials stored in Valet. They keep sensitive values outside the LLM context. Connectors and channels reference them with `{{NAME}}` template syntax.

**NEVER ask the user for secret values within the LLM session.** Direct them to run `valet secrets set NAME=VALUE --org <org>` in their terminal and wait for confirmation before proceeding.

### Set secrets

```
valet secrets set <NAME=VALUE>... [--org <org>] [--agent <agent>] [--no-wait]
```

Must specify exactly one scope: `--org` or `--agent` (or run from a linked agent directory). Agent-scoped secrets trigger a redeploy; org-scoped do not.

### {{NAME}} template syntax

Use `{{NAME}}` in connector `--env`, `--header`, or `--url` values to reference a secret. Templates are resolved at deploy time and can appear anywhere in a value:

```
--url https://{{DB_HOST}}/api
--header "Authorization=Bearer {{API_TOKEN}}"
--env SLACK_BOT_TOKEN={{SLACK_BOT_TOKEN}}
```

When directing the user to set secrets, **always tell them what format the value should be in**, including any prefix the service expects.

### List and remove

```
valet secrets [--agent <name> | --org <name>]
valet secrets unset <NAME> [--agent <name> | --org <name>]
```

## Organizations

Organizations own agents, connectors, channels, and secrets. All agents belong to an org.

```
valet orgs create <name>           # Create a new org
valet orgs                         # List your orgs
valet orgs info <name>             # Show org details
valet orgs destroy <name>          # Delete an org
valet orgs members <name>          # List members
valet orgs invite <name> <email>   # Invite a member
valet orgs join <name>             # Accept an invitation
valet orgs leave <name>            # Leave an org
valet orgs remove <name> <user>    # Remove a member
valet orgs revoke <name> <email>   # Cancel an invitation
```

**Org tips**: Set a default org with `valet orgs default <name>` so you don't need `--org` on every command.

## Other Commands

| Command | Purpose | Help |
|---------|---------|------|
| `valet run <prompt>` | Send a single prompt to an agent | `valet help run` |
| `valet console` | Start an interactive REPL with an agent | `valet help console` |
| `valet exec` | Run a command with secrets injected into its environment | `valet help exec` |
| `valet logs` | Stream live logs from a deployed agent | `valet help logs` |
| `valet ps` | List or restart agent processes | `valet help ps` |
| `valet drains` | Configure log drains (OTLP HTTP) | `valet help drains` |

## Pre-Deploy Verification with valet exec

`valet exec` is the **only way** to run local commands with Valet-managed secrets injected. Secrets are stored in the control plane — they are **not** available as shell environment variables. Always test secret-backed commands before deploying.

There are two modes:

### Connector mode (no `--`)

The first argument is looked up as a connector name. If a `command` connector is found, its secrets are fetched and injected, and the connector's configured command is executed. Extra arguments are appended after the connector's configured args:

```
# Run the "gh" command connector (looks up connector named "gh")
valet exec -a my-agent gh pr list

# Use linked agent from current directory
valet exec gh pr list
```

### Explicit secrets mode (with `--`)

Secret names are passed as a comma-separated positional argument before `--`. The command and its arguments follow after `--`:

```
valet exec [-a <agent>] SECRET[,SECRET...] -- command [args...]
```

Fetches the requested secret values and executes the given command with those secrets injected into the environment. The current process is replaced by the command.

```
# Run gh with GITHUB_TOKEN injected as an env var
valet exec -a my-agent GITHUB_TOKEN -- gh pr list

# Pass a secret as a CLI argument using {{}} syntax
valet exec -a my-agent API_KEY -- curl -H "Authorization: Bearer {{API_KEY}}" https://api.example.com

# Multiple secrets in one command
valet exec -a my-agent GITHUB_TOKEN,SLACK_TOKEN -- env
```

Flag: `--agent` or `-a`: Agent that owns the secrets (uses linked agent if omitted). Run `valet exec --help` for full details.

### Template syntax for CLI arguments

Use `{{SECRET_NAME}}` in command arguments to substitute secret values directly. This is useful for tools that accept credentials as flags or in URLs rather than reading from the environment. Works in both modes.

### Running MCP servers locally

To test an MCP server that requires secret-backed environment variables:

```
valet exec -a my-agent SLACK_BOT_TOKEN,SLACK_TEAM_ID -- \
  npx -y @modelcontextprotocol/server-slack

Without `valet exec`, the MCP server would start without the required tokens and fail to authenticate.

### Why valet exec is required

Regular shell commands (`curl`, `npx`, `node`, etc.) cannot access Valet secrets. This will **not** work:

```
# WRONG — $API_KEY is not set in your shell
curl https://api.example.com/data?key=$API_KEY

# CORRECT — valet exec injects the secret (explicit secrets mode)
valet exec -a my-agent API_KEY -- curl https://api.example.com/data?key={{API_KEY}}

# OR use connector mode if you have a command connector configured
valet exec -a my-agent my-connector-name
```

The same applies to any connector command. If your connector's `--command` or `--args` reference environment variables backed by secrets, test the exact command through `valet exec` before deploying.

## Pre-Deploy Verification with valet exec

**Before deploying an agent, locally test every command that requires secrets using `valet exec`.** This catches authentication failures, wrong secret names, malformed URLs, and missing dependencies before they cause the agent to crash in production.

### What to test

Any connector command that references secrets in its `--env` flags should be verified locally. Reproduce the exact command the connector will run, wrapping it in `valet exec`:

```
# If the connector is defined as:
valet connectors create github-server \
  --transport stdio \
  --command npx \
  --args -y,@modelcontextprotocol/server-github \
  --env GITHUB_PERSONAL_ACCESS_TOKEN={{GITHUB_TOKEN}}

# Test the underlying command locally:
valet exec -a my-agent GITHUB_TOKEN -- \
  npx -y @modelcontextprotocol/server-github
```

For remote connectors (SSE/streamable-http) with secret-backed headers or URLs, test with curl:

```
# If the connector uses --header Authorization={{API_TOKEN}} --url https://mcp.example.com/mcp
# Test the endpoint is reachable and the token works:
valet exec -a my-agent API_TOKEN -- \
  curl -s -o /dev/null -w "%{http_code}" -H "Authorization: {{API_TOKEN}}" https://mcp.example.com/mcp
```

Also test any webhook endpoint you plan to call with secrets in the URL:

```
valet exec -a my-agent WEBHOOK_SECRET -- \
  curl -X POST https://hooks.example.com/{{WEBHOOK_SECRET}}/notify -d '{"test": true}'
```

### Verification checklist

Before running `valet agents deploy`, confirm:

1. All secrets are set: `valet secrets --agent <name>` and `valet secrets --org <org>` list every name referenced by connectors
2. Each connector's command succeeds locally via `valet exec`
3. Any secret-backed URLs resolve and authenticate correctly

Do not deploy until all `valet exec` tests pass.

## Common Workflows

### Full agent setup (org-first, preferred)

Follow Resource Creation Principles — set up org-scoped resources first, then attach to the agent.

1. Direct the user to set org-scoped secrets in their terminal
2. Add connectors (catalog first, then custom if needed) at the org level
3. Add channels (catalog first for webhooks) at the org level
4. Create the agent and attach org resources:
   ```
   valet secrets set GITHUB_TOKEN=<their-token> --org acme
   ```

2. Add connectors from the catalog at the org level:
   ```
   valet connectors catalog
   valet connectors add github --org acme
   ```

3. If no catalog entry exists, create a custom connector at the org level:
   ```
   valet connectors create my-tool --org acme \
     --transport stdio \
     --command npx \
     --args -y,@example/mcp-server \
     --env API_KEY={{API_KEY}}
   ```

4. Add channels from the catalog at the org level (for webhooks):
   ```
   valet channels add github-webhook --org acme
   ```

5. Create the agent and attach org resources:
   ```
   cd my-agent-project
   valet agents create my-agent --org acme \
     --attach-connector github \
     --attach-channel github-webhook
   ```
   Or attach after creation:
   ```
   valet connectors attach github --agent my-agent
   valet channels attach github-webhook --agent my-agent --events pull_request
   ```

6. **Verify each connector command locally with `valet exec`** before proceeding:
   ```
   valet exec GITHUB_TOKEN -- \
     npx -y @modelcontextprotocol/server-github
   ```
   If this fails (bad token, missing dependency, wrong command), fix it now.

7. Create the channel file at `channels/<channel-name>.md` (see "Writing Channel Files").

8. Deploy to pick up the channel file:
   ```
   valet agents deploy
   ```

9. Validate end-to-end with an interactive test loop (see below).

### One-off agent setup (agent-scoped)

For standalone agents that don't need to share resources:

1. Create the agent:
   ```
   cd my-agent-project
   valet agents create my-agent
   ```

2. Set agent-scoped secrets and create agent-scoped connectors:
   ```
   valet secrets set API_KEY=<value> --agent my-agent
   valet connectors create my-tool --agent my-agent \
     --transport stdio --command npx \
     --args -y,@example/server \
     --env API_KEY={{API_KEY}}
   ```

3. Create channels, channel files, deploy, and test as above.

### Interactive test loop (mandatory for first-time channel setup)

1. Start streaming logs in the background:
   ```
   valet logs > /tmp/valet-test-<agent-name>.log 2>&1
   ```
   (Run via Bash with `run_in_background: true`.)

2. Ask the user to trigger the channel (send the email, push to GitHub, etc.). Be specific about what they need to do.

3. Wait for the user to confirm the trigger completed.

4. Stop the background log stream and read the log file.

5. Review the logs:
   - **Healthy**: Few turns, `mcp_call_tool_start`/`mcp_call_tool_done` pairs, `dispatch_complete`.
   - **Unhealthy**: Many turns with only built-in tools (agent looping), no `mcp_call_tool_start` (can't find tools), no `dispatch_complete` (timeout/stuck).

6. If problems, fix SOUL.md or channel prompt, redeploy, and repeat.

### Teardown (order matters)

Detach org resources first, then destroy agent-scoped resources, then the agent:
```
# Detach org resources (they remain available for other agents)
valet connectors detach github --agent my-agent
valet channels detach github-webhook --agent my-agent

# Destroy agent-scoped resources
valet channels destroy <agent-channel>
valet connectors destroy <agent-connector>

# Destroy the agent
valet agents destroy <agent-name> --force
```

### Debugging

```
valet agents info my-agent   # Check state, channels, connectors
valet logs --agent my-agent  # Stream live logs
valet ps restart -a my-agent # Restart without redeploying
```

## Designing a New Agent

**When to use**: The user asks to "build an agent", "create an agent from scratch", "design an automation", or provides skill/MCP URLs to assemble into an agent.

Be curious, confirmatory, and opinionated. Suggest improvements, anticipate edge cases, and help refine the idea. **7 questions max, fewer if sufficient.**

### Step 1: Parse the user's input

The user's prompt may contain a description of what they want and/or URLs pointing to skills, tools, or MCP servers. Extract both.

| URL type | Pattern | How to fetch |
|----------|---------|--------------|
| GitHub SKILL.md | `github.com/.../SKILL.md` | Convert to `raw.githubusercontent.com/...`. Explore parent dir for siblings. |
| GitHub directory | `github.com/.../tree/...` | Fetch listing. Look for SKILL.md, README.md. |
| skills.sh listing | `skills.sh/<name>` | Fetch page for description + source repo URL. Follow source link. |
| MCP server README | npmjs.com, GitHub, PyPI | Extract server name, tools, config/install instructions. |

For each URL: fetch with `WebFetch`, identify type, discover the full package, extract name/description/tools/dependencies/config. Check if equivalent tools already exist via `ToolSearch` — **always prefer existing tools**.

If no URLs, proceed directly to the interview.

### Step 2: Interview

Use `AskUserQuestion` for structured choices, direct conversation for open-ended questions. Track question count — stop and build once you have enough.

**Question 1 — Confirm understanding + trigger type:**

Present a concise summary of the agent you will build based on what you understood from the initial prompt:
- If URLs provided: present what you fetched — names, descriptions, capabilities and combine with any instructions to suggest the agent you will build.

Ask about the trigger if not already clear:
- Webhook — event-driven (email, push, form submission)
- Prompt — user sends a message via `valet run` or console

**Questions 2–6 — Adaptive deep-dive**

Be opinionated: suggest better approaches, flag automatable manual steps, raise obvious edge cases. **Stop early** if 1–3 questions gives a clear picture of the user intent.

Some example topics you might need to understand better are:

* Tool/skill discovery (see below) — skip if URLs already provided the tools
* Workflow clarification — decision points, branching logic
* Output format — where/how results are delivered (Slack channel, email, file, etc.)
* Edge cases and guardrails — suggest failure modes, ask about constraints

#### Tool discovery

When the user mentions a capability not covered by imported URLs, search in this order (per Resource Creation Principles): catalog (`valet connectors catalog`) → existing org connectors → `ToolSearch` for local MCP tools → `WebFetch` on `skills.sh` → `WebSearch` on PulseMCP/Smithery. If no match, the agent can use built-in tools or it remains a manual step.

### Step 3: Present the plan and confirm

After the interview and any tool/skill discovery, **stop and present a clear plan to the user before building anything**. The plan sets expectations about what will happen on their machine, what the agent will do automatically, and what the user will need to do manually. This gives the user a chance to change direction before any work begins — especially important when external setup (API credentials, third-party configuration, cloud consoles) is involved.

Present the plan in this format:

```
Here's the plan for your <agent-name> agent:

**What I'll create on your machine:**
- A project directory with SOUL.md defining the agent's identity and behavior
- [Channel files for <channel-type> triggers, if applicable]
- [Skill files for <connector> usage, if applicable]

**What I'll set up on the Valet platform:**
- The agent itself (registered and deployed in org <org-name>)
- [Org connectors: <list each, noting if from catalog or custom>]
- [Org channels: <list each, noting if from catalog or custom>]
- [Agent-scoped resources, if any: <list with reason they're not org-scoped>]

**What you'll need to do:**
- [Set secrets in your terminal (org-scoped by default): <list each secret and what it's for>]
- [External setup: <specific steps, e.g., "Create a Google Cloud project,
  enable the Gmail API, and generate OAuth credentials — I'll walk you
  through this when we get there">]
- [Any other manual steps the user must perform]

[If external setup is complex, call it out explicitly: "The <service>
integration requires some setup on your end — <brief description of
what's involved>. If that feels like too much, we could <alternative
approach> instead."]

Want to proceed with this plan, or would you like to adjust anything?
```

**Guidelines for the plan:**

- **Be specific about user obligations.** Don't say "set up API credentials" — say "create a Slack app at api.slack.com, add the `chat:write` scope, install it to your workspace, and copy the Bot User OAuth Token." The user needs to know what they're signing up for.
- **Flag complexity honestly.** If an integration requires navigating a cloud console, setting up OAuth, configuring webhooks on a third-party service, or any multi-step external process — say so clearly. This is often where users decide to change approach.
- **Offer alternatives when they exist.** If the user's goal can be achieved a simpler way (different service, fewer integrations, manual step instead of automation), mention it.
- **Wait for explicit confirmation.** Do not proceed to Step 4 until the user says yes. If they want changes, revise the plan and present it again.

### Step 4: Generate the agent

1. Create the project directory: `mkdir -p <agent-name>/channels`
2. Write `SOUL.md` following the "Writing SOUL.md" guidance below
3. Write channel files if the agent uses webhooks (see "Writing Channel Files")
4. Write skill files if documenting connector usage (see "Writing Skill Files")
5. Run the validation checklist:
   - [ ] SOUL.md exists with non-empty Purpose and Workflow
   - [ ] Guardrails has both Always and Never subsections
   - [ ] No hardcoded IDs that should be `<placeholder>`s
   - [ ] Channel files have Scope section if webhook-driven
   - [ ] Channel files include webhook payload location instruction
   - [ ] No secrets or API keys in any file
   - [ ] AGENTS.md written as the last step (see "Writing AGENTS.md")
6. Direct the user to set secrets at the org level (preferred) or agent level:
   ```
   valet secrets set SECRET_NAME=<value> --org <org-name>
   ```
7. Set up connectors — **check the catalog first**:
   ```
   valet connectors catalog
   valet connectors add <entry> --org <org-name>
   ```
   Only create custom connectors if no catalog entry exists:
   ```
   valet connectors create <name> --org <org-name> \
     --transport stdio \
     --command <cmd> --args <args> \
     --env KEY={{SECRET_NAME}}
   ```
8. Set up channels — **check the catalog first** for webhook channels:
   ```
   valet channels catalog
   valet channels add <entry> --org <org-name>
   ```
   Or create directly:
   ```
   valet channels create webhook <channel-name> --agent <agent-name>
   ```
9. Create and deploy the agent, attaching org resources:
   ```
   cd <agent-name>
   valet agents create [name] --org <org-name> \
     --attach-connector <connector> \
     --attach-channel <channel>
   ```
10. **Verify each connector command locally with `valet exec`:**
    ```
    valet exec -a <agent-name> SECRET_NAME -- <cmd> <args>
    ```
    Fix any failures before proceeding.
11. Deploy to pick up channel files: `valet agents deploy`
12. If the agent has channels, run the interactive test loop (see "Interactive test loop" under Common Workflows).
13. **Last step**: Write `AGENTS.md` in the project root (see "Writing AGENTS.md"). This summarizes the full setup for future developers.

### Design edge cases

| Case | Handling |
|------|----------|
| No URLs, pure description | Standard confirmatory interview. |
| URLs only, no description | Present imported capabilities, ask what the agent should do with them. |
| Mix of URLs and description | Fetch URLs first, then interview with imported context. |
| URL unreachable | Report error. Ask for alternative URL or direct paste. |
| Name collision | Run `valet agents` to check. Ask to choose a different name. |
| MCP server needs API keys | Document in SOUL.md Environment Requirements. Direct user to `valet secrets set`. Never ask for actual values. |

## Learning from the Current Session

**When to use**: The user says "save this as an agent", "capture this workflow", "learn from this session", or "make this repeatable".

### Step 1: Locate the session log

1. Convert the current working directory to the Claude projects path:
   `~/.claude/projects/-<cwd-with-slashes-replaced-by-dashes>/`
   Example: `/Users/me/Developer/my-project` → `~/.claude/projects/-Users-me-Developer-my-project/`
2. Find the active session log:
   ```bash
   ls -t ~/.claude/projects/-<path>/*.jsonl | head -1
   ```

### Step 2: Parse the session

Read the JSONL file with the Read tool. Each line is a JSON object. Extract:

- **User prompts**: Entries where `type` is `"user"` and `message.content` is a string. Capture the text (truncate to 500 chars each).
- **MCP tool usage**: Entries where `type` is `"assistant"` and `message.content` contains objects with `type: "tool_use"`. If the tool `name` starts with `mcp__`, split on `__` to get server and tool name (e.g., `mcp__slack__post_message` → server: `slack`, tool: `post_message`).
- **Skill invocations**: Tool calls where `name` is `"Skill"` — extract `input.skill` for the skill name.
- **Built-in tools**: All other tool call names (Read, Write, Edit, Bash, Glob, Grep, etc.).
- **Corrections**: User messages containing "no,", "don't", "instead", "actually", "wrong", "not that", "change", "stop", "undo", "revert" — these indicate the user changed direction.
- **Stop point**: Stop parsing when you encounter a Skill tool call with `input.skill` matching the learn/capture trigger. Exclude everything after.

For large sessions (>20 user prompts): sample the first 3 and last 3 user prompts to keep context manageable.

Also check `~/.claude/projects/<project-path>/sessions-index.json` for `summary` and `firstPrompt` fields matching the session ID (derived from the JSONL filename).

If the session is empty (no user prompts besides the learn trigger), inform the user and stop.

### Step 3: Present analysis and interview

Show the analysis:

```
Session Analysis:
- Objective: [summary from first prompt or sessions-index]
- User prompts: N messages
- MCP tools used: [server names + tool counts]
- Skills invoked: [names]
- Built-in tools: [names]
- Corrections detected: N
```

Ask clarifying questions (skip any with obvious answers from the session):

1. **Trigger**: What should invoke this agent? Propose a draft based on the first user prompt — webhook or prompt?
2. **Scope**: Does the extracted objective + tool list capture the full scope, or should it be narrowed/expanded?
3. **Corrections**: Surface each detected correction and ask whether the agent should always follow the corrected approach.
4. **Name**: Propose a kebab-case name (<64 chars). Let the user confirm.

### Step 4: Present plan and confirm

Follow the same confirmation flow as "Designing a New Agent" Step 3. Present what will be created, what platform resources will be set up, and what the user needs to do. Wait for confirmation.

### Step 5: Generate the agent

Follow the same generation flow as "Designing a New Agent" (Step 4 above), but source content from the session:

- **Purpose**: From user prompts + corrections + interview refinements
- **Workflow phases**: From the chronological sequence of tool calls, grouped by logical purpose (e.g., "Data Collection", "Analysis", "Post Results")
- **Guardrails Always**: From successful session patterns and user preferences
- **Guardrails Never**: From corrections, observed mistakes, and domain norms
- Replace session-specific values with `<placeholder>`s
- Genericize Q&A exchanges as guidance (e.g., "if ambiguous, prefer X")
- **Last step**: Write `AGENTS.md` in the project root (see "Writing AGENTS.md")

### Edge cases

| Case | Handling |
|------|----------|
| Empty session | Inform user: "This session is empty — nothing to capture." Stop. |
| No MCP tools used | Skip connector creation. Agent uses only built-in tools. |
| Long session (>500 entries) | Sample first 3 + last 3 user prompts. Summarize tool usage by frequency. |
| Many corrections | Present each one. Let the user decide which to encode as guardrails. |

## Writing SOUL.md

SOUL.md defines the agent's identity and behavior. It's the only required file.

### Template

```markdown
# <Agent Title>

## Purpose

<2-3 sentences: what this agent does and why. Name the specific tools, inputs, and outputs.>

## Personality

<3-4 traits matching the agent's domain. Skip for simple utility agents.>

- **<Trait>**: <Description>

## Workflow

### Phase 1: <Phase Name>

1. <Concrete step referencing specific tool names>
2. <Next step>

### Phase 2: <Phase Name>

1. <Steps>

## Guardrails

### Always
- <Positive constraint>

### Never
- <Negative constraint>
```

### Optional sections

Add as needed: **Target Channel**, **Environment Requirements**, **Webhook Scope Rule**, **Skills Used**, **MEMORY.md Format**.

### Synthesis rules

- **Purpose**: Specific what + why. Name inputs, outputs, and tools. Good: "Monitors YouTube channel X for new episodes, downloads transcripts, and posts digests to #channel on Slack." Bad: "Processes data."
- **Workflow**: Concrete numbered steps with actual tool names. Group into phases by logical purpose.
- **Guardrails Always**: From positive patterns the agent must consistently follow.
- **Guardrails Never**: From corrections and constraints the agent must avoid.
- **Placeholders**: Replace user-specific values (IDs, URLs, keys) with `<placeholder-name>`.

### Common mistakes

- Empty or vague Purpose — always name specific inputs, tools, and outputs
- Missing Workflow — Purpose without steps leaves the agent guessing
- Hardcoded values that should be `<placeholder>`s
- No scope boundary for webhook agents (see Writing Channel Files)

## Writing Channel Files

Channel files tell the agent what to do when a message arrives. They are instructions TO the agent, written as direct imperatives.

### Webhook payload location (critical)

The JSON webhook payload is appended inline after the channel file in the user message. Every channel file **must** start with:

```
The JSON webhook payload is appended directly after these instructions
in the user message. Parse it inline — do not fetch, list, or search
for the payload elsewhere. Do NOT use tools to read the payload.
```

Without this, agents waste turns searching for the payload with tool calls.

### Structure

1. **Payload location** — the instruction above
2. **What happened** — describe the event
3. **What to extract** — which payload fields identify the transaction (IDs, refs)
4. **Scope boundary** — all actions must be scoped to those identifiers
5. **What to do** — step-by-step processing instructions

### Example

```markdown
# New Email Received

The JSON webhook payload is appended directly after these instructions
in the user message. Parse it inline — do not fetch, list, or search
for the payload elsewhere. Do NOT use tools to read the payload.

You received a webhook for a single new email.

## Scope

Extract the `thread_id` from the payload. All actions are scoped to
this thread. Do not list, read, or act on any other threads.

## Steps

1. Extract `thread_id`, `from_`, `subject`, and `text` from the payload.
2. [... task-specific steps ...]
```

### Reinforcing scope in SOUL.md

For webhook-driven agents, add to SOUL.md:

```markdown
## Webhook Scope Rule

When you receive a webhook, your scope of work is defined by the
identifiers in the payload. Use any tools to fully understand and act
on that specific content, but do not act on unrelated content.
```

## Writing AGENTS.md

`AGENTS.md` is the **last file written** before the session ends. It lives in the root of the agent project directory and serves as a human- and LLM-readable setup guide for anyone who needs to deploy this agent in the future.

**NEVER include secret values, API keys, or tokens in AGENTS.md.** Only describe what is needed and why.

### Template

```markdown
This folder contains the source for a Skilled Agent originally built for the Valet runtime. Changes should follow the Skilled Agent open standard.

## Setup

### Connectors

- **<connector-name>**: <plain-English description of what it provides and why the agent needs it>
  [Repeat for each connector]

### Channels

- **<channel-name>** (<channel-type>): <what triggers this channel and what the agent does when it fires>
  [Repeat for each channel]

### Secrets

- **<SECRET_NAME>**: <what this secret is for, where to obtain it, and any scopes or permissions required>
  [Repeat for each secret]

### External Setup

[If the agent requires any configuration outside of Valet — third-party service setup, OAuth apps, cloud console steps, DNS records, etc. — describe each step here in plain English. Be specific enough that a person unfamiliar with the project can follow along.]
```

### Rules

- Write in plain English — describe requirements as nouns with reasons, not CLI commands
- Be specific about secrets — include required scopes/permissions and where to obtain them
- Include external setup steps (OAuth apps, cloud consoles, webhook registrations, etc.)
- Omit sections that don't apply. Write this file last.

## Agent Project Structure

```
my-agent/
  AGENTS.md            # Setup guide for future developers (required)
  SOUL.md              # Agent identity and behavior (required)
  channels/            # Channel files (for webhook/trigger-driven agents)
    <channel-name>.md
  skills/              # Agent-scoped skill documentation (optional)
    <connector-name>/
      SKILL.md
  .valet/
    config.json        # Auto-managed by CLI
```

All deployed files are **read-only** at runtime. The agent can write new files (e.g., MEMORY.md), but written files **do not survive deploys**.

## Execution Guidelines

- Always run commands via the Bash tool.
- **Be explanatory**: Before running any valet command, briefly tell the user *what* you're about to do and *why*. Don't silently execute commands — the user should always understand the purpose of each step.
- **Installation guardrails**: Follow the Installation section strictly. If the CLI is not installed, explain why it's needed and attempt installation via Homebrew. If Homebrew fails, **stop immediately** — do not retry, work around, or troubleshoot brew issues. Let the user resolve it manually.
- **Authentication first**: Always verify the user is logged in (`valet auth whoami`) before running any non-auth valet commands. If not logged in, explain that authentication is required and run `valet auth login`. Do not proceed until authentication succeeds.
- **Use `valet help` proactively**: When you encounter a command, flag, or feature you're unsure about, run `valet help <command>` before guessing. The CLI help is the authoritative source.
- **Never ask for secret values inside the LLM session.** Direct the user to run `valet secrets set NAME=VALUE` in their own terminal and wait for confirmation.
- **Always verify privileged commands with `valet exec` before deploying.** After the user sets secrets and you create connectors, test the underlying command locally using `valet exec <names> -- <command>`. This is the only way to run commands with Valet-managed secrets locally. Do not deploy until the command succeeds. Use `{{SECRET_NAME}}` template syntax to embed secrets in URLs, headers, or env values.
- When the user asks to create an agent from scratch, follow "Designing a New Agent".
- When the user asks to capture the current session as an agent, follow "Learning from the Current Session".
- When writing SOUL.md, follow the template and synthesis rules. Never leave Purpose or Workflow empty.
- For destructive commands (`destroy`, `remove`, `revoke`), always confirm with the user first.
- When creating webhook channels, report the webhook URL and signing secret. When writing channel files, include the payload location instruction.
- After deploying an agent with channels for the first time, run the interactive test loop.
- If a command fails, read the error and troubleshoot. Common issues: not logged in, no `SOUL.md`, not linked, agent crashed. For Homebrew errors, **stop and let the user resolve manually**.

