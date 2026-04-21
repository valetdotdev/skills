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

### Command connector references in SOUL.md

When the agent uses a command connector, the SOUL.md workflow must reference the **connector name** as the command — not the npm package name, underlying transport, or `npx` invocation. The connector name is the CLI command the agent types, and it is the only name on the agent's PATH.

Good: `Run agentmail inboxes list to verify the CLI is connected.`
Bad: `Run npx agentmail-cli inboxes list` or `Run agentmail-cli inboxes list`

Using the wrong name either bypasses secret injection (calling npx directly) or fails entirely (command not found). When creating connectors, always name them after the CLI command (see naming rule in the Connectors section).

### Common mistakes

- Empty or vague Purpose — always name specific inputs, tools, and outputs
- Missing Workflow — Purpose without steps leaves the agent guessing
- Hardcoded values that should be `<placeholder>`s
- No scope boundary for webhook agents (see Writing Channel Files)
- Using the wrong command name for command connectors — the connector must be named after the CLI command (e.g., `agentmail` not `agentmail-cli`), and SOUL.md must reference that same name

