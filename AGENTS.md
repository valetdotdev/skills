# Repository Guidelines

## The plugin is retired

Valet works through its MCP server, which people add with
`claude mcp add` or `codex mcp add`. This directory holds the plugin's
last release so installed copies stop carrying stale guidance: four
manifests and a `valet` skill that tells the person to add the server
and remove the plugin. Removing `valet-skills/` and its mirror workflow
is a follow-up, once installs have moved.

Do not add content back. `make lint-valet-skills` fails when the plugin:

- carries a hook, at `hooks/hooks.json` or named in
  `.claude-plugin/plugin.json`. A hook runs on events the user did not
  ask Valet about.
- declares an MCP server in `mcp.json` or `.mcp.json`. A bundled server
  would sit beside the one the person added by hand, putting two copies
  of the same tools in front of the model.

## CRITICAL: Bump the version with every content change

This directory mirrors verbatim to the public `valetdotdev/skills`
marketplace on merge, and Claude Code uses the plugin version as its
update cache key. A user who has the plugin installed receives new
content **only** when the version changes.

So any change to the skill or a manifest also bumps the version in
every manifest, which must always agree:

- `plugin.json`
- `.claude-plugin/plugin.json`
- `.claude-plugin/marketplace.json`
- `.agents/plugins/marketplace.json`

Changes to `README.md`, `AGENTS.md`, and `LICENSE` need no bump. The
two marketplaces must name the same plugin, version, and source, and
the root `plugin.json` name must match the marketplace plugin name, as
Codex requires. `make lint-valet-skills` enforces all of this. Run it
before pushing.

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
