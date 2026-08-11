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
