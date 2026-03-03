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

Useful topic guides: `getting-started`, `agent-lifecycle`, `channels`, `connectors-overview`.

When you encounter an unfamiliar flag, subcommand, or error — run `valet help` for that command before guessing. The CLI help is authoritative and up to date.

## Core Concepts

- **Agent**: An AI agent defined by a `SOUL.md` file in a project directory. Agents are deployed as versioned releases.
- **Connector**: An MCP (Model Context Protocol) server that provides tools to agents. Transports: `stdio`, `sse`, `streamable-http`.
- **Channel**: A message entry point (webhook, Telegram, heartbeat, cron) owned by exactly one agent.
- **Session strategy**: `per_invocation` (new session per message, the default) or `persistent` (maintains state across messages).
- **Channel file**: A markdown file at `channels/<channel-name>.md` that tells the agent how to handle incoming messages.
- **Organization**: A shared workspace for teams. Agents, connectors, and secrets can be scoped to an org with `--org <name>`.
- **Secrets**: Sensitive values (API keys, tokens) stored outside the LLM context. Referenced with `secret:NAME` syntax.

## Agent Lifecycle

### Create an agent

The current directory must contain a `SOUL.md` file. This creates the agent, links the directory, deploys v1, and waits for readiness:

```
valet agents create [name] [--org <org-name>] [--personal] [--no-wait]
```

Name is optional (auto-generated if omitted). Use `--org` for an org workspace, `--personal` to bypass the default org.

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
valet agents [--personal] [--org <name>]
```

### Show agent details

```
valet agents info [name]
```

Displays owner, current release, process state, channels, and connectors.

### Destroy an agent

```
valet agents destroy <name>
```

Permanently removes the agent and all releases. Cannot be undone.

## Connectors

Connectors give agents access to MCP tools. When created inside a linked agent directory, connectors auto-attach and trigger a new deploy.

### Create a stdio connector

```
valet connectors create <name> [--org <org-name>] [--personal] \
  --transport stdio \
  --command <cmd> \
  --args <comma-separated-args> \
  --env KEY=secret:NAME
```

**Important**: `--args` takes comma-separated values, not space-separated. Use multiple `--env` flags for multiple variables.

Example:
```
valet connectors create slack-server \
  --transport stdio \
  --command npx \
  --args -y,@modelcontextprotocol/server-slack \
  --env SLACK_BOT_TOKEN=secret:SLACK_BOT_TOKEN \
  --env SLACK_TEAM_ID=secret:SLACK_TEAM_ID
```

### Create a remote connector

```
valet connectors create <name> \
  --transport streamable-http \
  --url https://mcp.example.com/mcp
```

Use `--header KEY=secret:VAL_ALIAS` for auth headers. Transport can be `streamable-http` or `sse`.

### Attach / Detach

```
valet connectors attach <connector-name> [-a <agent-name>]
valet connectors detach <connector-name> [-a <agent-name>]
```

### List and inspect

```
valet connectors
valet connectors info <name> [--org <org-name>]
```

### Destroy a connector

```
valet connectors destroy <name> [--org <org-name>]
```

## Channels

Channels are message entry points for agents. The most common type is a webhook.

### Create a webhook channel

```
valet channels create webhook [name] \
  --agent <agent-name> \
  --verify hmac-sha256 \
  --signature-header X-Hub-Signature-256
```

Key flags: `--verify` (scheme: `none`, `hmac-sha256`, `svix`, `stripe`, `static-token`), `--secret`, `--signature-header`, `--delivery-key-header`, `--delivery-key-path`, `--prompt`. Run `valet channels create --help` for full details.

The command outputs the **webhook URL** and **signing secret** — always save and report these to the user.

### Other channel types

The CLI also supports `telegram`, `heartbeat`, and `cron` channels. Run `valet channels create --help` or `valet topics channels` for details on these types.

### List, inspect, destroy

```
valet channels
valet channels info <name> [--agent <agent-name>]
valet channels destroy <name> [--agent <agent-name>]
```

## Secrets

Secrets keep sensitive values outside the LLM context. Connectors reference them with `secret:NAME` in `--env` values.

### Critical: handling secrets safely

**NEVER ask the user for secret values within the LLM session.** Instead:

1. Tell the user what secrets they need to configure.
2. Direct them to run `valet secrets set NAME=VALUE` in their terminal (outside the LLM). Include `--org <org-name>` or `--agent <name>` flags as needed.
3. Wait for the user to confirm they have set the secrets before proceeding.

### List and remove

```
valet secrets [--agent <name> | --org <name>]
valet secrets unset <NAME> [--agent <name> | --org <name>] [--force]
```

## Organizations, Process Management, and Other Commands

The following features are available but not detailed here. Use `valet help <command>` to learn about them when needed:

| Command | Purpose | Help |
|---------|---------|------|
| `valet orgs` | Create, manage, and switch between shared workspaces | `valet help orgs` |
| `valet run <prompt>` | Send a single prompt to an agent | `valet help run` |
| `valet console` | Start an interactive REPL with an agent | `valet help console` |
| `valet exec` | Run a command with secrets injected into its environment | `valet help exec` |
| `valet logs` | Stream live logs from a deployed agent | `valet help logs` |
| `valet ps` | List or restart agent processes | `valet help ps` |
| `valet drains` | Configure log drains (OTLP HTTP) | `valet help drains` |

**Org tips**: When working within an org, pass `--org <name>` to agent, connector, and secrets commands — or set a default with `valet orgs default <name>`. Use `--personal` to bypass the default org.

## Common Workflows

### Full agent setup

1. Create the agent from a directory with `SOUL.md`:
   ```
   cd my-agent-project
   valet agents create my-agent
   ```

2. Direct the user to set any needed secrets in their terminal (outside the LLM):
   ```
   valet secrets set GITHUB_TOKEN=<their-token>
   ```

3. Create MCP connectors referencing secrets (auto-attaches if in linked directory):
   ```
   valet connectors create github-server \
     --transport stdio \
     --command npx \
     --args -y,@modelcontextprotocol/server-github \
     --env GITHUB_PERSONAL_ACCESS_TOKEN=secret:GITHUB_TOKEN
   ```

4. Create a webhook channel:
   ```
   valet channels create webhook my-channel \
     --signature-header X-Hub-Signature-256
   ```

5. Create the channel file at `channels/my-channel.md` (see "Writing Channel Files").

6. Deploy to pick up the channel file:
   ```
   valet agents deploy
   ```

7. Validate end-to-end with an interactive test loop (see below).

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

Destroy channels and connectors before the agent:
```
valet channels destroy <channel-name>
valet connectors destroy <connector-name>
valet agents destroy <agent-name>
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

When the user mentions a capability not covered by imported URLs:

1. **Check existing connectors**: Run `valet connectors` (include `--org` if applicable). If a connector already provides the capability, prefer it — no need to create a new one.
2. **Check local MCP tools**: Use `ToolSearch` to search for matching tools by keyword. If found, note the MCP server/tool names.
3. **Browse skills.sh**: Use `WebFetch` on `https://skills.sh` to search for relevant skills. Present matches with name and description.
4. **Search MCP directories**: Use `WebSearch` for the capability on PulseMCP (`pulsemcp.com`) or Smithery (`smithery.ai`). Present matching servers with install instructions.
5. **No match**: Be honest — the agent can use built-in tools (Bash, WebFetch, etc.) to approximate it, or it can remain a manual step.

Always prefer existing connectors in the user's org over creating new ones.

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
- The agent itself (registered and deployed)
- [Connectors: <list each connector by name and what it provides>]
- [Channels: <list each channel by type and purpose>]

**What you'll need to do:**
- [Set secrets in your terminal: <list each secret and what it's for>]
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
6. Create and deploy:
   ```
   cd <agent-name>
   valet agents create [name] [--org <org-name>]
   ```
7. Create connectors referencing secrets:
   ```
   valet connectors create <connector-name> \
     --transport stdio \
     --command <cmd> --args <args> \
     --env KEY=secret:SECRET_NAME
   ```
8. Direct the user to set secrets in their terminal
9. Create channels if needed:
   ```
   valet channels create webhook <channel-name>
   ```
10. Deploy to pick up channel files: `valet agents deploy`
11. If the agent has channels, run the interactive test loop (see "Interactive test loop" under Common Workflows).
12. **Last step**: Write `AGENTS.md` in the project root (see "Writing AGENTS.md"). This summarizes the full setup for future developers.

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

- **Write in plain English.** Describe each requirement as a noun and a reason: "A GitHub connector for reading source code and pull requests", not `npx -y @modelcontextprotocol/server-github --args ...`.
- **Be specific about secrets.** Say "A GitHub personal access token with `repo` scope for reading private repositories", not "GITHUB_TOKEN".
- **Include external setup.** If the agent depends on a Slack app, a Google Cloud project, a webhook registration in a third-party service, or anything else outside Valet — document the steps. This is often the part a future developer will struggle with most.
- **Omit sections that don't apply.** If the agent has no channels, leave out the Channels section. If there's no external setup, leave that out too.
- **Write this file last.** It summarizes the completed agent, so it should reflect the final state of the project after all connectors, channels, and secrets are configured.

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
- When the user asks to create an agent from scratch, follow "Designing a New Agent".
- When the user asks to capture the current session as an agent, follow "Learning from the Current Session".
- When writing SOUL.md, follow the template and synthesis rules. Never leave Purpose or Workflow empty.
- For destructive commands (`destroy`, `remove`, `revoke`), always confirm with the user first.
- When creating webhook channels, always report back the webhook URL and signing secret.
- When writing channel prompt files, always include the webhook payload location instruction.
- After deploying an agent with channels for the first time, always run the interactive test loop.
- If a command fails, read the error output and troubleshoot. Common issues:
  - Not logged in → `valet auth login`
  - No `SOUL.md` → create one or `cd` to the right directory
  - Not linked → `valet agents link <name>`
  - Agent crashed → check `valet logs`, fix, redeploy
  - **Homebrew errors → do NOT troubleshoot. Stop and ask the user to resolve manually.**
