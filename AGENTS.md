# Repository Guidelines

## CRITICAL: Bump the version with every content change

This directory mirrors verbatim to the public `valetdotdev/skills`
marketplace on merge, and Claude Code uses the plugin version as its
update cache key. A user who has the plugin installed receives new
content **only** when the version changes — otherwise `/plugin update`
reports "already at the latest version" and ships nothing.

So any change to a skill, a hook, or a manifest also bumps the version
in every manifest, which must always agree:

- `plugin.json`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.agents/plugins/marketplace.json`

Changes to `README.md`, `AGENTS.md`, `LICENSE`, and `codex/README.md`
need no bump; they document the plugin rather than ship in it.

`make lint-valet-skills` enforces this, along with the name match Codex
requires, the component layout Claude Code expects, and the `valet`
commands, flags, and MCP tool names the skill text uses, which must exist
in `valet-cli/reference/commands.json` and
`valet-api/reference/mcp-tools.json`. CI runs it on every change to this
directory and to those references. Run it before pushing.

## CRITICAL: Keep the two plugins in one directory

Claude Code and Codex read this directory differently:

- Codex reads `plugin.json`, `mcp.json`, and
  `.agents/plugins/marketplace.json`. The OpenAI listing lives in
  `plugin.json` under `extensions["com.openai"].interface`. Each server
  in `mcp.json` carries only `type` and `url`, because Codex refuses any
  other field and then loads no server. Codex discovers OAuth itself.
- Claude Code reads `.claude-plugin/`, `.mcp.json`, and the hook file its
  `plugin.json` `hooks` field names.

Keep the Claude hook at `claude/hooks.json`. Never create
`hooks/hooks.json`: Codex loads it by default, and OpenAI's public
directory excludes plugins with hooks. Quote the plugin root in hook
commands (`"\"${CLAUDE_PLUGIN_ROOT}\"/claude/prefer-valet.py"`);
`claude plugin validate --strict` warns otherwise.

The two marketplaces must name the same plugin, version, and source.

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
- Open a PR ready for review, not as a draft. `ci.yml` runs nothing on a
  draft, so a draft PR never produces the CI result you are waiting for.
