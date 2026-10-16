# Codex

Codex installs the plugin from this repository's
`.agents/plugins/marketplace.json`. Claude Code reads
`.claude-plugin/marketplace.json` from the same directory. When
`.agents/plugins/marketplace.json` exists, Codex reads it. It falls back to
`.claude-plugin/marketplace.json` only when the `.agents` file is missing.
Both files name one plugin, `valet`, with source `./`, and they agree on
name and version.

## Install the plugin

```bash
codex plugin marketplace add valetdotdev/skills
codex plugin add valet@valet
```

Codex reads the root `plugin.json`, installs the `valet` skill, and
reads the MCP server from `mcp.json`. Each server there carries only
`type` and `url`: Codex refuses a server with any other field and then
loads none. Codex finds Valet's authorization server from the 401
challenge and registers its own client; `codex mcp login valet` signs
in. The `interface` block in `plugin.json` supplies the directory
listing.

Codex also enforces that the root `plugin.json` name matches the
marketplace plugin name. A second entry would fail to install with
`plugin.json name does not match marketplace plugin name`.

To install the skill without the plugin:

```bash
npx skills add valetdotdev/skills --skill valet -g
```

**Pick one or the other.** Codex loads skills from `~/.agents/skills/`
*and* from installed plugins, so doing both puts two copies of the same
skill in front of the model.

## No hook

The OpenAI plugin carries no hook. Codex looks for `hooks/hooks.json` when
the manifest names no hook, and OpenAI excludes plugins with lifecycle
hooks from its public directory. The Claude Code hook lives at
`claude/hooks.json`, which only `.claude-plugin/plugin.json` names, so
Codex never finds it.

The skill's description selects the publishing workflow without a hook.

## References

- [Building plugins](https://developers.openai.com/codex/plugins/build/)
- [Public skills README](../README.md)
