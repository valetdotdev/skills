# Repository Guidelines

## CRITICAL: Bump the version with every content change

This directory mirrors verbatim to the public `valetdotdev/skills`
marketplace on merge, and Claude Code uses the plugin version as its
update cache key. A user who has the plugin installed receives new
content **only** when the version changes — otherwise `/plugin update`
reports "already at the latest version" and ships nothing.

So any change to a skill, a hook, or a manifest also bumps the version
in all three manifests, which must always agree:

- `plugin.json`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`

Changes to `README.md`, `AGENTS.md`, `LICENSE`, and `codex/README.md`
need no bump; they document the plugin rather than ship in it.

`make lint-valet-skills` enforces this, along with the name match Codex
requires and the component layout Claude Code expects. CI runs it on
every change to this directory. Run it before pushing.

## CRITICAL: Keep the two MCP configurations in agreement

The plugin declares Valet's MCP server twice, because no single format
reaches both clients: `mcp.json` is the Agent Plugins 1.0.0 format
(§7.2, transport `streamable-http`) and `.mcp.json` is Claude Code's
(bare server keys, transport `http`). No client reads both, so a URL
changed in one file alone ships silently to half the installed base.

Edit both, or neither. `make lint-valet-skills` compares them.

MCP configuration must not go inline in `plugin.json`: the Agent
Plugins manifest schema is closed, and §7.2.1 forbids it.

## CRITICAL: Never Commit Directly to Main

**NEVER commit directly to the main branch.** All changes must go through pull requests.

When asked to commit changes:
1. Create a new branch first: `git checkout -b $USER/<feature-name>` (e.g., `jkakar/new-skill`)
2. Commit your changes to that branch
3. Push the branch and open a pull request
4. Return the PR URL to the user

This applies to ALL changes, no matter how small. No exceptions.

## Commit & PR Guidelines
- Keep commits focused, rebase on main, and run checks before pushing.
- PRs should note intent, affected files, and user-visible updates.
- Leave PRs in draft until CI succeeds.
