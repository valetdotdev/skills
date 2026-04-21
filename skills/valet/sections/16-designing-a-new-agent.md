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

**Important: When using `AskUserQuestion`, the `question` field must be a complete, clear question sentence that ends with a question mark.** The user sees this question text prominently — it's the primary thing they read to understand what you're asking. Bad: "Trigger" or "Trigger type". Good: "How should this agent be triggered?" Option labels should be short (1-5 words) with the description providing detail.

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
   valet connectors create <entry> --org <org-name>
   ```
   Only create custom connectors if no catalog entry exists:
   ```
   valet connectors create mcp-server <name> --org <org-name> \
     --transport stdio \
     --command <cmd> --args <args> \
     --env KEY={{SECRET_NAME}}
   ```
8. Set up channels — **check the catalog first** for webhook channels:
   ```
   valet channels catalog
   valet channels create <entry> --org <org-name>
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

