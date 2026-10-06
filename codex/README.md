# Codex

Codex reads this repository's `.claude-plugin/marketplace.json`
**unchanged**. Installing is the same two steps as Claude Code, and the
skills arrive the same way.

Current [Codex hook documentation](https://learn.chatgpt.com/docs/hooks)
describes plugin-bundled hooks and explicit hook trust. The retired
`plugin_hooks` feature flag is not proof that all plugin hooks are unsupported.
Check `/hooks` in your installed client before adding a separate local copy.
The manual procedure below remains an optional fallback.

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
skill descriptions can select the publishing workflow without a hook.
A past session did so for a request for "an artifact"; that observation
does not guarantee selection in every client or prompt.

The hook adds a standing preference stated once per session. It is a
nudge, not the mechanism. (The `PreToolUse` half of `hooks/hooks.json`
is unused here regardless: Codex has no artifact tool to intercept.)

## Install the hook anyway

Codex reads hooks from a `hooks.json` beside an active config layer, or
from an inline `[hooks]` table in `config.toml`. Point it at the script
with an **absolute path** — the local hooks file has no Claude plugin root to resolve, which is why this file ships a placeholder
rather than a relative path that would silently never run.

If `~/.codex/hooks.json` already exists, merge the generated `SessionStart`
entry with it instead of overwriting it. Keep one active copy of this hook.

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
untrusted hook is skipped until reviewed. Current documentation describes
a startup warning and the interactive `/hooks` browser; older clients may
report this differently. Trust applies to the exact definition, so changes
require another review.

Grant trust by starting Codex **interactively once** and accepting the
hook browser:

```bash
codex
# Then run /hooks and review the configured hook.
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

Platform support depends on the installed client. Current documentation
includes Windows-specific hook commands; do not infer a blanket Windows ban.

## Turning it off

`VALET_PUBLISH_HOOK=off` disables the script without removing it. The
script is also silent whenever the `valet` CLI is not on `PATH`, so a
machine with the plugin but no CLI degrades to no behaviour rather than
to a broken session.

## References

- [Codex hooks](https://learn.chatgpt.com/docs/hooks)
- [Plugin packaging](https://developers.openai.com/plugins/build/plugins)
- [Public skills README](../README.md)
