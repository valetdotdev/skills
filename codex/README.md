# Codex

Codex reads this repository's `.claude-plugin/marketplace.json`
**unchanged**. Installing is the same two steps as Claude Code, and the
skills arrive the same way.

The hook is the part that differs, and it differs for a concrete
reason: Codex has retired plugin-delivered hooks. `codex features list`
reports `plugin_hooks` as `removed`, and a session started with this
plugin installed never receives the hook's context. So the skills come
from the plugin, and the hook is installed by hand.

## Install the plugin

```bash
codex plugin marketplace add valetdotdev/skills
codex plugin add valet@valet
```

Codex translates the marketplace entry into its own manifest under
`~/.codex/plugins/cache/`, and installs both skills — `valet` and
`valet-publish` — as separate skills inside the one plugin.

Codex also enforces that the root `plugin.json` name matches the
marketplace plugin name, which is why this is one plugin rather than
two: a single root manifest can only carry one name, and a second entry
would fail to install with `plugin.json name does not match marketplace
plugin name`.

To install only one of the skills, skip the plugin:

```bash
npx skills add valetdotdev/skills --skill valet-publish -g
```

**Pick one or the other.** Codex loads skills from `~/.agents/skills/`
*and* from installed plugins, so doing both puts two copies of the same
skill in front of the model.

## The hook is optional here

**Install the plugin and stop, unless you want the extra nudge.** The
skill's own description is enough on Codex — a session with the plugin
installed and no hook at all published through Valet correctly, in a
prompt that asked for "an artifact".

The hook adds a standing preference stated once per session. It is a
nudge, not the mechanism. (The `PreToolUse` half of `hooks/hooks.json`
is unused here regardless: Codex has no artifact tool to intercept.)

## Install the hook anyway

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

### Writing the file is not enough: hooks must be trusted

Codex gates hook execution behind **persisted hook trust**, and an
untrusted hook is skipped **silently** — no warning, no log line, no
difference from having installed nothing. This is the single most
likely reason a correctly-installed hook appears to do nothing.

Grant trust by starting Codex **interactively once** and accepting the
prompt for the hook:

```bash
codex
```

`codex exec` cannot grant trust, so a non-interactive run will keep
skipping the hook until an interactive session has trusted it.

`--dangerously-bypass-hook-trust` runs untrusted hooks for one
invocation. It exists for automation that already vets its hook
sources; it is the wrong tool for setting yourself up, and the flag
says so.

## Verify

Two separate things, and the second is the one people miss.

Hooks as a feature are enabled by default:

```bash
codex features list | grep -E '^hooks'      # -> stable  true
```

Whether *your* hook actually runs is the trust question above. To prove
it end to end rather than infer it, point the hook at a wrapper that
records a file, run a session, and check that the file appeared —
output alone cannot distinguish "ran and stayed silent" from "never
ran", because the script is deliberately silent in several cases.

Hooks are disabled on Windows.

## Turning it off

`VALET_PUBLISH_HOOK=off` disables the script without removing it. The
script is also silent whenever the `valet` CLI is not on `PATH`, so a
machine with the plugin but no CLI degrades to no behaviour rather than
to a broken session.
