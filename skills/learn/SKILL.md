---
name: learn
description: >
  Analyze the current Claude Code session and generate a repeatable agent
  package (SOUL.md, EVAL.md, skill files). Captures the task workflow,
  tools used, and user corrections into a self-contained, reusable agent.
  Use when the user invokes /learn after completing a task they want to
  capture as a reusable agent. Also use when asked to "save this as an
  agent", "capture this workflow", or "make this repeatable".
---

Analyze the current Claude Code session and generate a complete agent package. Follow these steps sequentially.

## Step 1: Locate the Session Log

1. Convert the current working directory to the Claude projects path: `~/.claude/projects/-<cwd-with-slashes-replaced-by-dashes>/`
   - Example: `/Users/miradu/Developer/valetdotdev/agents` becomes `~/.claude/projects/-Users-miradu-Developer-valetdotdev-agents/`
2. Run `ls -t <project-path>/*.jsonl | head -1` to find the active session log.

## Step 2: Parse the Session

Run the bundled parser script:

```bash
python3 scripts/parse_session.py <session-file>
```

This extracts: user prompts, MCP tools (server + tool + input samples), invoked skills, built-in tools, corrections, and a summary. It stops at the `/learn` invocation automatically.

If the output is empty (no user prompts besides `/learn`), inform the user: "This session is empty — nothing to capture." and stop.

Also read `~/.claude/projects/<project-path>/sessions-index.json` and find the entry matching the session ID (from the JSONL filename). Extract `summary` and `firstPrompt` if they provide a better summary.

## Step 3: Interview the User

Present the analysis and ask clarifying questions using AskUserQuestion. Keep it tight — skip questions whose answers are obvious from the session.

### 3a. Present Analysis

```
Session Analysis:
- Objective: [summary]
- User prompts: N messages
- MCP tools used: [servers + tool counts]
- Skills invoked: [names]
- Built-in tools: [names]
- Corrections detected: N
```

### 3b. Clarifying Questions

1. **Trigger**: "What event, prompt, or timer should invoke this agent in the future?" Propose a draft trigger from the first user prompt. Note: the current runtime only supports single-message invocation (no multi-turn).

2. **Scope**: "I found N MCP tools across M servers, K skills, and this objective: [summary]. Does this capture the full scope, or should I narrow/expand?"

3. **Corrections**: If corrections were detected, surface each one: "You changed direction: [correction]. Should the agent always follow the corrected approach, or decide based on context?"

4. **Task name**: Propose a kebab-case name <64 chars (e.g., `notion-database-updater`). Let the user confirm or rename.

5. **Name collision**: Check if `.claude/agents/<proposed-name>/` exists. If so, ask to overwrite or rename.

Skip questions where the session data provides a clear answer.

## Step 4: Generate the Agent Package

Read [references/agent-format.md](references/agent-format.md) for the complete output format specification.

Generate the following files using the synthesis rules from that reference:

### SOUL.md

- **Purpose**: From user prompts + corrections + interview refinements.
- **Workflow phases**: From the chronological sequence of tool calls, grouped by logical purpose (e.g., "Research", "Generate", "Verify").
- **Guardrails "Always"**: From successful session patterns and user preferences.
- **Guardrails "Never"**: From user corrections, observed mistakes, and domain norms.
- Genericize Q&A exchanges as guidance (e.g., "if ambiguous, prefer X").
- Replace session-specific values with placeholders.

### EVAL.md

- **Required Outcomes**: From actual outputs produced in the session.
- **Quality Criteria**: From user corrections and iterations.
- **Failure Modes**: From observed mistakes and anticipated errors.

### Per-MCP-Server SKILL.md

Generate one for each MCP server used. Replace session-specific values (database IDs, page IDs, user URLs) with placeholders.

### Copy Referenced Skills

For each invoked skill:
1. Check project level: `<cwd>/.claude/skills/<skill-name>/`
2. Fall back to global: `~/.claude/skills/<skill-name>/`
3. Copy the entire directory into `.claude/agents/<task-name>/skills/<skill-name>/`
4. If not found, warn the user and note it in the report.

### Write Files

Follow the file writing procedure in [references/agent-format.md](references/agent-format.md).

### Validate

After writing all files, run the validation script:

```bash
python3 scripts/validate_agent.py .claude/agents/<task-name> [generated-mcp-skill-names...]
```

Pass only the names of MCP server skill directories you generated (not copied/imported skills) as additional arguments. For example: `python3 scripts/validate_agent.py .claude/agents/daily-digest slack reddit-mcp-buddy`

**If validation fails, fix the reported errors and re-run until it passes.** Do not report success to the user until validation passes. Common fixes:
- Missing SOUL.md section → add the section with content
- Empty Purpose/Workflow → fill in from session data
- Missing subagent spec frontmatter → add name/description
- Skill SKILL.md missing frontmatter → add name/description fields

### Report

After validation passes, run `ls -R .claude/agents/<task-name>/` and report:

```
Agent "<task-name>" created successfully! (validation passed)

Files generated:
- <task-name>.md (subagent spec)
- <task-name>/SOUL.md
- <task-name>/EVAL.md
- <task-name>/skills/<server>/SKILL.md (x N)
- <task-name>/skills/<skill>/SKILL.md (x M)

Built-in tools referenced: <list>

Trigger prompt:
> <trigger>
```

## Edge Cases

| Case | Handling |
|------|----------|
| No MCP tools used | Skip MCP skill generation. |
| Long sessions (>500 entries) | Parser handles via sampling. |
| User corrections mid-session | Final version in SOUL.md workflow; originals in EVAL.md failure modes. |
| Empty session | Inform user and stop. |
| Name collision | Ask to overwrite or rename. |
| Referenced skill not found | Warn user, skip copy, note in report. |
