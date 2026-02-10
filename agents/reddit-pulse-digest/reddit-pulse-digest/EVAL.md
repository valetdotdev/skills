# Evaluation: Reddit Pulse Digest

## Overview

A successful run produces a single, well-formatted Slack message in #customer-research containing exactly 3 synthesized "need-to-know" bullets drawn from today's top posts across r/mcp, r/claudeai, and r/aiagents.

## Success Criteria

### Required Outcomes

- [ ] All 3 target subreddits were browsed (mcp, claudeai, aiagents)
- [ ] Subreddits were browsed in parallel (not sequentially)
- [ ] Exactly 3 bullets were produced (a bonus "Hot post" one-liner is acceptable but not required)
- [ ] The message was posted to #customer-research without user intervention (no channel selection prompt)
- [ ] Each bullet includes specific numbers (upvote score, ratio, or comment count)
- [ ] Each bullet attributes its source subreddit
- [ ] The message includes a header with date and source subreddits
- [ ] The message includes a source attribution line at the bottom
- [ ] MCP tools were loaded sequentially (Reddit first, then Slack) to avoid tool name collisions
- [ ] The agent completed autonomously without requiring user input

### Quality Criteria

- [ ] The 3 bullets cover genuinely different topics (not 3 variations of the same theme)
- [ ] At least one bullet surfaces a non-obvious insight (not just the highest-upvoted post restated)
- [ ] Each bullet explains *why it matters*, not just *what happened*
- [ ] The writing is concise — each bullet is 3-5 sentences, not a wall of text
- [ ] Slack formatting is correct (bold titles render, no broken markdown)
- [ ] The tone reads like a morning briefing, not a raw data dump

## Evaluation Method

### Inputs

- The current date (determines "today's" posts)
- Access to Reddit MCP (`reddit-mcp-buddy`) and Slack MCP (`slack`)
- The target Slack channel name: `#customer-research`

### Expected Outputs

- One Slack message in #customer-research with the "Reddit Pulse" format
- No additional messages, threads, or side-effects

### Diagnostic Checklist

| Check | Pass | Fail |
|-------|------|------|
| Agent launch | Agent runs as single unit without crashing | Tool collision or launch error requiring manual fallback |
| Tool loading | Reddit tools loaded first, Slack tools loaded second, no errors | Simultaneous loading causes collision |
| Subreddit coverage | All 3 subreddits appear in source data | One or more subreddits missing |
| Parallel browsing | All 3 browse_subreddit calls issued in same turn | Sequential browsing (one at a time) |
| Bullet count | Exactly 3 (+ optional hot post) | Fewer or more than 3 |
| Channel targeting | Posted to #customer-research autonomously | User prompted to pick channel, or posted to wrong channel |
| Data freshness | Posts are from the last 24 hours | Posts are stale or from wrong time range |
| Formatting | Slack renders bold, italic, emoji correctly | Raw markdown visible or broken layout |
| Synthesis quality | Bullets show editorial judgment and cross-referencing | Bullets are just the top 3 posts by score, restated |
| Autonomy | No user interaction required during run | User asked questions or had to intervene |

## Failure Modes

- **Tool name collision**: Loading Reddit and Slack MCP tools simultaneously causes `"tools: Tool names must be unique"` error and crashes the agent. Mitigation: always load Reddit MCP tools first, wait for completion, then load Slack MCP tools. Never load both in the same ToolSearch call or in parallel.
- **Subreddit not found**: If a subreddit name is misspelled or the subreddit is private, `browse_subreddit` will fail. Mitigation: verify subreddit names are lowercase and correct before calling.
- **Slack channel not found**: If #customer-research doesn't exist or the bot isn't a member, posting will fail. Mitigation: always look up channel by name first; if not found, report the error clearly rather than guessing a channel ID. Do NOT prompt the user to pick a different channel — just fail with a clear message.
- **Empty subreddit results**: On very slow days, a subreddit may have no posts in the last 24 hours. Mitigation: fall back to `sort: "hot"` without a time filter, but note this in the digest.
- **Tool loading failure**: If `ToolSearch` doesn't find the MCP tools, the agent can't proceed. Mitigation: fail fast with a clear error message.
- **Overly long message**: Slack has a ~4000 character limit per message. Mitigation: keep each bullet to 3-5 sentences; if the draft exceeds limits, trim the least-important bullet's detail.
- **Agent launch failure**: If the agent cannot be launched as a single subagent (e.g., tool conflicts at the framework level), the orchestrator must fall back to a two-step pattern: (1) launch `reddit-mcp-buddy` subagent for data collection, (2) synthesize in parent context, (3) launch `slack` subagent for posting. This is a degraded mode — synthesis happens outside the agent's guardrails.
