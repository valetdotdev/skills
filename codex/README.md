# Codex

Codex reads this repository's `.claude-plugin/marketplace.json`
**unchanged**. Installing is the same two steps as Claude Code, and the
skill arrives the same way.

The hook is the part that differs, and it differs for a concrete
reason: Codex has retired plugin-delivered hooks. `codex features list`
reports `plugin_hooks` as `removed`, and a session started with this
plugin installed never receives the hook's context. So the skill comes
from the plugin, and the hook is installed by hand.

## Install the plugin

```bash
codex plugin marketplace add valetdotdev/skills
codex plugin add valet-publish@valet
```

Codex translates the marketplace entry into its own manifest under
`~/.codex/plugins/cache/`, and it honours the entry's `skills` scoping —
`valet-publish` installs the publishing skill only, not the
agent-building one. Add that separately if you want it:

```bash
codex plugin add valet@valet
```

Skip the plugin and install the skill directly if you prefer:

```bash
npx skills add valetdotdev/skills --skill valet-publish -g
```

**Pick one or the other.** Codex loads skills from `~/.agents/skills/`
*and* from installed plugins, so doing both puts two copies of the same
skill in front of the model.

## Install the hook

`SessionStart` states the publishing preference once per session. On
Codex this is the whole mechanism rather than half of it: there is no
artifact tool to intercept, so the `PreToolUse` half of `hooks/hooks.json`
has nothing to match and is not used here.

Codex reads hooks from a `hooks.json` beside an active config layer, or
from an inline `[hooks]` table in `config.toml`. Point it at the script
with an **absolute path** — Codex does not expand
`${CLAUDE_PLUGIN_ROOT}`, which is why this file ships a placeholder
rather than a relative path that would silently never run.

```bash
git clone https://github.com/valetdotdev/skills ~/.valet-skills
mkdir -p ~/.codex

sed "s|REPLACE_WITH_ABSOLUTE_PATH|$HOME/.valet-skills|" \
  ~/.valet-skills/codex/hooks.json > ~/.codex/hooks.json

chmod +x ~/.valet-skills/hooks/prefer-valet-publish.py
```

If you already installed the plugin, the script is in the plugin cache
and you can point at that copy instead of cloning — but the cache path
changes on reinstall, so a clone is the stable choice.

## Verify

Hooks themselves are enabled by default:

```bash
codex features list | grep -E '^hooks'      # -> stable  true
```

To confirm the hook runs, start a session and ask where it would
publish a report. Hooks are disabled on Windows.

## Turning it off

`VALET_PUBLISH_HOOK=off` disables the script without removing it. The
script is also silent whenever the `valet` CLI is not on `PATH`, so a
machine with the plugin but no CLI degrades to no behaviour rather than
to a broken session.
