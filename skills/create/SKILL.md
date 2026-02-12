---
name: create
description: >
  Design and generate a new AI agent through a structured interview. If the
  user includes URLs (GitHub skills, skills.sh listings, MCP server READMEs),
  fetch and import them as part of the agent. Produces a complete agent
  package (SOUL.md, EVAL.md, skill files). Use when the user invokes /create,
  or asks to "create an agent", "build an agent", "design an automation",
  "make an agent that...", or provides skill/MCP URLs to assemble into an
  agent.
---

Design and generate a new AI agent. Interview the user to discover what it should do, identify and import tools/skills, and produce a complete agent package.

Be curious, confirmatory, and opinionated. Suggest improvements, anticipate edge cases, and help refine the idea. Prefer existing tools over new ones. **7 questions max, fewer if sufficient.**

**CRITICAL: Always generate the full agent package.** Every run MUST produce: SOUL.md, EVAL.md, skill files under `.claude/agents/<name>/`, and a subagent spec at `.claude/agents/<name>.md`. The interview determines WHAT GOES INTO these files, not WHETHER to generate them. Never short-circuit to a raw file copy.

## Step 1: Parse the User's Input

The user's prompt may contain:
- A description of what they want the agent to do (always)
- One or more URLs pointing to skills, tools, or MCP servers (sometimes)

**Extract both.** Scan the prompt for URLs matching these patterns:

| Type | Pattern | How to Fetch |
|------|---------|--------------|
| GitHub SKILL.md | `github.com/.../SKILL.md` | Convert to `raw.githubusercontent.com/...`. Explore parent dir for siblings (scripts/, references/, assets/). |
| GitHub directory | `github.com/.../tree/...` | Fetch listing. Look for SKILL.md, README.md, subdirectories. |
| skills.sh listing | `skills.sh/<name>` | Fetch page for description + source repo URL. Follow source link for full package. |
| MCP server README | npmjs.com, GitHub, PyPI | Extract server name, tools, config/install instructions. |
| Raw SKILL.md | Direct URL to raw file | Fetch directly. Explore parent path for full package. |

### If URLs are present

For each URL:

1. Fetch with `WebFetch`.
2. Identify type (skill, MCP server, listing).
3. **Discover the full package** — explore sibling files, follow source links, check for scripts/, references/, assets/.
4. Extract: name, description, tools provided, dependencies, config requirements.
5. Check if equivalent tools already exist via `ToolSearch`. If so, flag it: "You already have [tool] which provides [capability]. Still want to import [new tool]?" **Always prefer existing tools.**

For GitHub imports, convert `blob` URLs to `tree` URLs to explore the directory. Fetch siblings one level deep. Preserve original directory structure.

For skills.sh, follow the source repo link to get the full package from GitHub.

For MCP servers (no SKILL.md), extract server name, package, tools, and config from the README. You'll generate a SKILL.md for them later.

### If no URLs

Proceed directly to the interview. Tool discovery happens during Questions 3-7.

## Step 2: Interview

Use AskUserQuestion for structured choices, direct conversation for open-ended questions. Track question count — stop and build once you have enough.

### What to Discover

| Need | Description |
|------|-------------|
| Purpose | What does this agent do? |
| Trigger | When/how should it run? (schedule, prompt, event) |
| Inputs | What information does it need? |
| Workflow | What steps, in what order? |
| Tools | MCP tools, skills, or built-in tools needed? |
| Outputs | What does it produce? |
| Guardrails | What should it always/never do? |

A single answer often covers multiple items. Be efficient.

### Question 1: Open-Ended Kick-Off

**If URLs were provided:** Present what you fetched — name, description, capabilities of each imported skill/tool. Then ask:

> Here's what I found at the URL(s) you provided: [summary]. What do you want this agent to do with these? Describe the full task or workflow.

**If no URLs:** Ask directly (do NOT use AskUserQuestion):

> What do you want this agent to do? Describe the task, the problem it solves, or the workflow you want automated. Be as specific or as vague as you like — I'll ask follow-ups.

Parse their response. Extract purpose, workflow, inputs, outputs, and any mentioned tools.

### Question 2: Confirm Understanding + Trigger

Present a concise summary of what you understood. Then ask about the trigger if not already specified. Use AskUserQuestion with options relevant to their use case:
- "Slash command" — User types /<name> to run it
- "Prompt-based" — User describes a task and Claude delegates to it
- "Scheduled" — Runs on a timer (daily, hourly, etc.)
- "Event-driven" — Triggered by an external event

The answer goes into the generated SOUL.md Invocation section and subagent spec description — it does NOT change the output format or destination.

### Questions 3-7: Adaptive Deep-Dive

Ask only what's still missing. Prioritize:

1. **Tool/skill discovery** (see below) — skip if URLs already provided the tools
2. **Orchestration** — if multiple tools/skills, how do they interact? (pipeline, parallel, conditional)
3. **Workflow clarification** — decision points, branching logic
4. **Output format** — where/how artifacts are delivered
5. **Edge cases** — suggest failure modes and ask how to handle them
6. **Guardrails** — constraints for sensitive operations
7. **Customization** — for imported skills: "Modify the workflow/guardrails, or use as-is?" ("As-is" means derive SOUL.md directly from imported docs without modification. It does NOT mean skip generation.)

Be opinionated: suggest better approaches, flag automatable manual steps, raise obvious edge cases.

**Stop early**: If 3-4 questions gives a clear picture, say "I have enough to build this" and proceed.

## Tool Discovery

When the user mentions a capability not already covered by imported URLs:

### 1. Check Existing Tools

Use `ToolSearch` to search for matching tools by keyword. If found, confirm with the user and note the MCP server/tool names. **Always prefer existing tools.**

### 2. Browse skills.sh

If no existing match, use `WebFetch` on `https://skills.sh` to search for relevant skills. Present matches via AskUserQuestion with name and description. Note confirmed skills as required.

### 3. MCP Directories

If skills.sh has no match, use `WebSearch` for the capability on PulseMCP (`pulsemcp.com`) or Smithery (`smithery.ai`). Present matching servers with install instructions.

### 4. No Match

Be honest:

> I couldn't find an existing tool for [capability]. The agent can use built-in tools (Bash, WebFetch, etc.) to approximate it, or this can remain a manual step. What do you prefer?

## Step 3: Generate the Agent Package

Read [references/agent-format.md](references/agent-format.md) for the complete output format specification.

### Task Name

Derive a kebab-case name <64 chars from the agent's purpose. For URL-only imports, base on the skill name. For multi-skill agents, reflect the combined purpose. Propose and let the user confirm. Check for collisions in `.claude/agents/`.

### SOUL.md

- **Purpose**: From the user's description, refined by follow-ups. If URLs were imported, incorporate their capabilities.
- **Workflow phases**: From logical task decomposition. For multiple imported tools, from orchestration mode (pipeline, parallel, conditional).
- **Skills Used**: Include source URLs for imported skills: `(source: <url>)`.
- **Guardrails**: From explicit user constraints + imported skills' documented limitations + your domain knowledge.
- **Personality**: Match the domain (code reviewer = "precise and constructive", content creator = "creative and engaging").
- Replace user-specific values with placeholders.

### EVAL.md

- **Required Outcomes**: From described capabilities, expected outputs, and imported skills' capabilities.
- **Quality Criteria**: From interview refinements.
- **Failure Modes**: From edge cases discussed + imported skills' known limitations.

### Per-MCP-Server SKILL.md

Generate one for each MCP server identified (from imports or tool discovery). Include installation instructions and config requirements.

### Store Imported Skills

For skills fetched from URLs:
1. Create `.claude/agents/<task-name>/skills/<skill-name>/`.
2. Write fetched SKILL.md and all siblings, preserving directory structure.

### Copy Already-Installed Skills

For skills already installed locally:
1. Check project: `<cwd>/.claude/skills/<skill-name>/`
2. Fall back to global: `~/.claude/skills/<skill-name>/`
3. Copy into `.claude/agents/<task-name>/skills/<skill-name>/`
4. If not found, warn and note in report.

### Write Files

Follow the file writing procedure in [references/agent-format.md](references/agent-format.md).

### Validate

After writing all files, run the validation script:

```bash
python3 scripts/validate_agent.py .claude/agents/<task-name> [generated-mcp-skill-names...]
```

Pass only the names of MCP server skill directories you generated as additional arguments. Do NOT pass names of imported or copied skill directories.

**If validation fails, fix the reported errors and re-run until it passes.** Do not report success to the user until validation passes. Common fixes:
- Missing SOUL.md section → add the section with content
- Empty Purpose/Workflow → fill in from interview/import data
- Missing subagent spec frontmatter → add name/description
- Skill SKILL.md missing frontmatter → add name/description fields

### Report

After validation passes, run `ls -R .claude/agents/<task-name>/` and report:

```
Agent "<task-name>" created successfully! (validation passed)

[If URLs were imported:]
Imported from:
- <url-1> -> skills/<skill-1>/
- <url-2> -> skills/<skill-2>/

Files generated:
- <task-name>.md (subagent spec)
- <task-name>/SOUL.md
- <task-name>/EVAL.md
- <task-name>/skills/<server>/SKILL.md (x N)
- <task-name>/skills/<skill>/SKILL.md (x M)

Built-in tools referenced: <list>

Trigger prompt:
> <trigger>

[If MCP servers need configuration:]
MCP servers to configure:
- <server>: <install command>
```

## Edge Cases

| Case | Handling |
|------|----------|
| No URLs, pure description | Standard interview flow. Tool discovery in Questions 3-7. |
| URLs only, no description | Present imported skills and ask "What do you want this agent to do with these?" |
| Mix of URLs and description | Fetch URLs first, then interview starting from the description + imported context. |
| URL unreachable | Report error. Ask for alternative URL or direct paste. |
| Single file, not a package | Import file, generate wrapper SKILL.md. Note it may be incomplete. |
| Overlapping capabilities | Flag overlap. Ask which to prefer, or both for different contexts. |
| MCP server needs API keys | Document in SKILL.md and report. Do NOT ask for actual secrets. |
| No MCP tools needed | Skip MCP skill generation. |
| Name collision | Ask to overwrite or rename. |
| GitHub URL requires auth | Suggest pasting raw content or providing a public URL. |
| Skill has dependencies | Fetch and import dependencies too. Note the chain in SOUL.md. |
| User is vague | Ask probing questions. Suggest concrete interpretations. |
| User wants something dangerous | Explain the risk. Suggest safer alternatives. Add guardrails. |
| User changes direction | Summarize new direction and confirm before proceeding. |
| User says "as-is" for imports | Derive SOUL.md from imported docs without modification. Do NOT skip generation. |
| User picks "slash command" trigger | Record in SOUL.md Invocation section. Do NOT redirect output to .claude/skills/. |
| Tool exists but wrong server name | Use ToolSearch results as source of truth. |

## Now Begin

Parse the user's input for URLs and a description. Then:

1. **If URLs found**: Fetch and analyze each one, then present findings and start the interview.
2. **If no URLs**: Ask the first question:

> What do you want this agent to do? Describe the task, the problem it solves, or the workflow you want automated. Be as specific or as vague as you like — I'll ask follow-ups.
