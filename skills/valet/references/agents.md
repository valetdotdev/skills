# Agents

An agent is a `SOUL.md`, a `valet.yaml`, and supporting files that Valet
runs when a channel wakes it. Read the `agents` skill before building
one: it owns what an agent holds and how to run, inspect, and remove it.
Read `channels` before giving it a way to be woken.

This file covers designing an agent with the person, writing its files,
and the CLI's agent commands.

## The project

```
my-agent/
  SOUL.md              # identity and behavior (required)
  valet.yaml           # name, display_name, description, category
  AGENTS.md            # setup guide for whoever deploys it next
  CLAUDE.md            # points coding agents at AGENTS.md
  channels/<name>.md   # what to do when that channel fires
  skills/<name>/SKILL.md   # a skill only this agent needs
```

`valet new <name> [--dir <path>]` scaffolds this. Deployed files are
read-only at runtime. Files the agent writes do not survive a deploy.

## Create, deploy, remove

```
valet agents create [name] [--org <org>] [--from <source>] \
  [--attach-connector <name>] [--attach-channel <name>] [--no-wait]
valet deploy
valet agents [--org <org>]
valet agents info <name> [--org <org>]
valet agents destroy <name> [--org <org>]
```

`valet agents create` needs a `SOUL.md`. It creates the agent, links the
directory, deploys the first release, and waits until it runs. `--from`
takes a local path, a Git URL such as `github.com/user/repo`, or
`catalog:<name>`. The attach flags repeat.

`valet.yaml` may declare `cron`, `heartbeat`, and `mcp` channels inline
with `type:`, and the deploy creates them:

```yaml
channels:
  - type: cron
    schedule: "every day at 9am"     # or cron: "0 9 * * *"
    timezone: America/New_York
  - type: heartbeat
    every: 5m
  - type: mcp
    description: answers questions about the team's runbooks
```

Over MCP, `publish_agent` does what `valet agents create` and
`valet deploy` do. Memories are `valet memories`, `valet memories set`,
and `valet memories unset`, or the memory tools the `agents` skill names.

To take an agent down, detach the organization's connectors and channels
it holds, destroy the ones only it holds, then destroy the agent:

```
valet connectors detach github --agent my-agent
valet channels detach github-webhook --agent my-agent
valet agents destroy my-agent
```

## Design an agent with the person

Use this when the person asks you to build or design an agent, or gives
URLs of skills, tools, or MCP servers to combine. Be curious and
opinionated. Ask at most seven questions, fewer when the picture is
clear.

1. **Read what they gave you.** Fetch each URL. For a GitHub `SKILL.md`,
   read the raw file and its siblings. For an MCP server's page, note
   its tools and setup. Prefer tools that already exist.
2. **Interview.** First confirm what you understood and how the agent is
   woken: a schedule, a webhook, a chat message, or a prompt. Then ask
   only what you need: the workflow's decision points, where results
   go, edge cases, and limits. When you offer choices, phrase each as a
   full question that ends with a question mark.
3. **Find the tools.** Look in Valet's connector catalog, then the
   organization's connectors, then your local tools, then public skill
   and MCP directories. If nothing fits, the step stays manual.
4. **Present the plan and wait.** Say what you will create on this
   machine, what you will set up on Valet, and what the person must do:
   each secret they will set and where to get it, and each step outside
   Valet, such as creating an OAuth app in a cloud console. Name the
   hard parts plainly and offer a simpler route when one exists. Build
   nothing until they agree.
5. **Build.** Scaffold with `valet new`, write `SOUL.md`, channel files,
   any skills, and `valet.yaml`, then `AGENTS.md` last. Set up
   connectors and channels as `references/connectors.md` and
   `references/channels.md` describe, then create the agent.
6. **Verify.** Ask the agent to use each command connector once. Fix
   failures and deploy again. For each new channel, watch the logs while
   the person triggers it, as `references/cli.md` describes.

Before deploying, check:

- `SOUL.md` has a specific Purpose and a Workflow.
- Guardrails has both Always and Never.
- Values specific to one person or account are `<placeholders>`.
- Each webhook channel file starts with the payload instruction and has
  a Scope section.
- No file holds a secret.
- `valet manifests validate` passes.

## Save a session as an agent

Use this when the person says "save this as an agent", "capture this
workflow", or "make this repeatable".

1. **Find the session log.** Replace each `/` in the working directory
   with `-` to find `~/.claude/projects/-<path>/`, and take the newest
   `*.jsonl` there. `sessions-index.json` beside it may hold a summary.
2. **Read it.** Each line is JSON. Collect the person's prompts (type
   `user` with string content), tool calls (`tool_use` blocks; a name
   `mcp__<server>__<tool>` names an MCP server), skills invoked, and
   corrections, where the person said "no", "instead", "don't", or
   "undo". Stop at the call that started this capture. In a long
   session, sample the first three and last three prompts.
3. **Show what you found and ask.** The objective, the prompt count, the
   tools and skills used, and each correction. Ask what should wake the
   agent, whether the scope is right, which corrections become rules,
   and its name.
4. **Plan and build** as in steps 4 to 6 above. Build the Workflow from
   the tool calls in order, Always from what worked, and Never from the
   corrections. Replace session-specific values with placeholders.

If the session is empty, say so and stop.

## Write SOUL.md

```markdown
# <Agent Title>

## Purpose

<Two or three sentences: what it does and why. Name its inputs, tools,
and outputs.>

## Workflow

### Phase 1: <name>

1. <A concrete step naming the tool it uses>

## Guardrails

### Always
- <rule>

### Never
- <rule>
```

Add sections as the agent needs them: Personality, Environment
Requirements, Webhook Scope Rule, Skills Used, or the format of a file it
keeps.

- **Purpose is specific.** "Watches channel X for new episodes, fetches
  transcripts, and posts digests to #channel" — not "processes data".
- **Workflow names real tools,** in numbered steps grouped by purpose.
- **A command connector is called by its connector name,** the only
  name on the agent's `PATH`. Write `agentmail inboxes list`, never
  `npx agentmail-cli inboxes list`, which bypasses the secrets.
- **A webhook agent gets a scope rule:**

  ```markdown
  ## Webhook Scope Rule

  When you receive a webhook, your scope of work is defined by the
  identifiers in the payload. Use any tools to fully understand and act
  on that specific content, but do not act on unrelated content.
  ```

## Write valet.yaml

```yaml
name: <agent-name>          # matches the name given to valet agents create
display_name: <Human Name>
description: <One sentence on what it does and for whom>
category: <one lowercase word, such as finance or developer-tools>
```

These four are required. Add `connectors`, `channels`, and `skills`
entries only for catalog items; a custom connector or channel cannot
appear here, so document it in `AGENTS.md`. Check each name with
`valet connectors catalog` and `valet channels catalog`, and each slot
with `valet connectors catalog get <name>`. If something should be in
the catalog and is not, the person can ask support@valet.dev.

```yaml
connectors:
  - catalog: github
    description: Reads the repository the team asks about
    slot_descriptions:
      GITHUB_TOKEN: A token with read access to the repository
channels:
  - catalog: github-webhook
    events: [pull_request]
```

Keep `display_name` and `description` current when the agent's purpose
changes. Run `valet manifests validate` after every edit.

### The story, for the catalog

An agent published to Valet's catalog also needs a `story`, which the
dashboard's setup wizard shows. Skip it for an agent only this
organization uses.

```yaml
story:
  hero: "Let's get AskADev answering questions for your team."
  subheadline: "Ask a question about a GitHub repo in Slack. AskADev researches the code, then replies in-thread."
  steps:
    - role: trigger
      title: "Your team asks a question in Slack."
      body: "Someone posts 'where do we handle the Stripe webhook retry logic?'"
      catalog: slack-webhook
    - role: action
      title: "AskADev reads your code."
      body: "Searches the repo. Finds the handler and surrounding comments."
      catalog: github
    - role: outcome
      title: "And answers — with sources."
      body: "Replies in-thread, linking to the exact file, line, and commit."
      catalog: slack-mcp
```

Exactly three steps, in the order `trigger`, `action`, `outcome`. A
step's `catalog` must match one of the manifest's connectors or
channels; leave it empty for a step with no outside service.

| Field | Aim for | Limit |
|---|---|---|
| `hero` | 45–75 characters | 80 |
| `subheadline` | 110–170 | 200 |
| step `title` | 25–50 | 60 |
| step `body` | 80–130 | 140 |
| `ui.headline` | 30–55 | — |
| `ui.blurb` | 80–140 | — |
| `ui.done_note` | 20–45 | — |

Draft it from `SOUL.md`: Purpose names the trigger, action, and outcome.
Find the hook that makes this agent specific, such as a time, a place,
or a constraint. Write the steps first, then each `done_note`, then the
subheadline, and the hero last.

- **Hero** names the agent and says what it does: "Let's get AskADev
  answering questions for your team."
- **Subheadline** is one concrete sentence naming the services and the
  reward.
- **Trigger** starts from the person's world: "A PR is opened."
- **Action** is active and names the agent: "AskADev reads your code."
- **Outcome** names what the person sees: "Replies in-thread, linking
  to the file."

Write in the present tense and the active voice. Address the reader as
"you". Name real services, channels, and times. Avoid buzzwords such as
seamless, leverages, empowers, and powerful. Describe results, not
mechanism. If the copy would fit a different agent, add the hook.

Each connector or channel entry may carry a `ui` block with copy about
this agent's use of the service:

```yaml
connectors:
  - catalog: github
    ui:
      headline: "Point AskADev at your repo."
      blurb: "AskADev reads your code when it answers — like a new hire would."
      done_note: "Connected to your repo"
```

Leave permissions, restrictions, and safety notes to the catalog. When
the agent has a `README.md`, keep its title equal to `display_name` and
its tagline equal to `subheadline`, word for word.

## Write AGENTS.md

Write it last, once every setup step is known. It tells a person or a
coding agent how to set the agent up again. Never put a secret in it.

```markdown
This folder contains the source for a Skilled Agent originally built for the Valet runtime.

## Setup

### Connectors
- **<name>**: what it provides and why the agent needs it

### Channels
- **<name>** (<type>): what wakes it and what the agent then does

### Secrets
- **<NAME>**: what it is for, where to get it, and the scopes it needs

### External Setup
<Each step outside Valet, plainly enough for someone new to follow.>
```

Describe needs in plain words, not commands. Leave out a section that
does not apply.
