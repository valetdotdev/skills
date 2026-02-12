# Agent Package Format Reference

Generated agents follow this directory structure and file format.

## Directory Structure

```
.claude/agents/<task-name>.md          # Subagent spec (triggers delegation)
.claude/agents/<task-name>/
├── SOUL.md                            # Agent identity + orchestration
├── EVAL.md                            # Success criteria + evaluation
└── skills/
    ├── <mcp-server-name>/SKILL.md     # Per-MCP-server skill file
    └── <skill-name>/SKILL.md          # Copied/imported skill files
```

## SOUL.md

```markdown
# <Task Title>

## Purpose

<2-3 sentences: what this agent does, synthesized from session/interview.>

## Personality

<3-4 traits matching the agent's domain. E.g., "methodical", "concise", "thorough", "proactive".>

## Workflow

### Phase 1: <Phase Name>

<Steps referencing specific tools/skills.>

### Phase 2: <Phase Name>

<Steps.>

## Skills Used

### MCP Tools

- [`<server-name>`](skills/<server-name>/SKILL.md) — <brief description>

### Referenced Skills

- [`<skill-name>`](skills/<skill-name>/SKILL.md) — <what it does>

### Built-in Tools

- **Read** — <usage context>
- **Write** — <usage context>

## Invocation

```
<trigger prompt or schedule description>
```

## Guardrails

### Always
<Positive constraints from session patterns, interview, or domain norms.>

### Never
<Negative constraints from corrections, limitations, or domain norms.>
```

## EVAL.md

```markdown
# Evaluation: <Task Title>

## Overview

<One sentence: what a successful run looks like.>

## Success Criteria

### Required Outcomes

- [ ] <Concrete, measurable criterion>
- [ ] <Criterion 2>

### Quality Criteria

- [ ] <Qualitative criterion distinguishing "good" from "excellent">
- [ ] <Criterion 2>

## Evaluation Method

### Inputs

<What to provide to the agent.>

### Expected Outputs

<What the agent should produce — files, messages, API calls.>

### Diagnostic Checklist

| Check | Pass | Fail |
|-------|------|------|
| <Check> | <Pass> | <Fail> |

## Failure Modes

- **<Mode 1>**: <Description and mitigation>
- **<Mode 2>**: <Description and mitigation>
```

## Per-MCP-Server SKILL.md

```yaml
---
name: <server-name>
description: <What this MCP server does for this agent>
---
```

Body:

```markdown
# <Server Name> — Skills for <Agent Name>

## Tools Used

### <tool-name>

**Purpose**: <What this tool does in this agent's context>

**Typical Input**:
```json
<Input pattern with placeholders replacing session-specific values>
```

**Expected Output**: <Response shape>

**Workflow Integration**: Used in Phase N — <brief context>

**Error Patterns**: <Observed errors and resolutions, if any>
```

## Subagent Spec (.claude/agents/<task-name>.md)

```markdown
---
name: <task-name>
description: <One sentence from SOUL.md Purpose. End with "Use when asked to <trigger>.">
mcpServers:
  - <server-name-1>
  - <server-name-2>
---

Read and follow the instructions in `.claude/agents/<task-name>/SOUL.md`.
```

Omit `mcpServers` if no MCP tools are used.

## Synthesis Rules

- **Purpose**: From user prompts/interview, refined by corrections/follow-ups.
- **Workflow phases**: From chronological tool call sequence (learn) or logical task decomposition (invent/import).
- **Guardrails**: From user corrections + domain norms.
- **Personality**: Match the agent's domain (code reviewer = "precise", content creator = "creative").
- **Placeholders**: Replace session-specific values (IDs, URLs, paths) with `<database-id>`, `<channel-name>`, `<target-url>`, etc.

## File Writing Procedure

1. Create directory: `mkdir -p .claude/agents/<task-name>/skills/<server-name>/`
2. Copy referenced skill directories (check project `.claude/skills/` first, fall back to `~/.claude/skills/`).
3. Write SOUL.md, EVAL.md, per-server SKILL.md files.
4. Write subagent spec at `.claude/agents/<task-name>.md`.
5. Verify with `ls -R .claude/agents/<task-name>/`.
6. Report created files, built-in tools referenced, and the trigger prompt.
