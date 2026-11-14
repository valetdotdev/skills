# Valet Skills

The retired [Valet](https://valet.dev) plugin for Claude Code and Codex.

> **This repository is a generated mirror.** The source of truth lives in Valet's `ark` monorepo under `valet-skills/`, and changes are synced here automatically on merge. Please don't open PRs against this repo — reach us at [support@valet.dev](mailto:support@valet.dev).

## Retired

Valet works through its MCP server, which carries its own tools and
guidance. This plugin's last release holds only a `valet` skill that
says so, so installed copies stop carrying stale instructions. It
declares no MCP server and carries no hook.

## Add Valet's MCP server

Claude Code:

```
claude mcp add --transport http valet https://api.valet.dev/mcp
```

Codex:

```
codex mcp add valet --url https://api.valet.dev/mcp
codex mcp login valet
```

claude.ai, Claude Desktop, ChatGPT, and other clients: add
`https://api.valet.dev/mcp` as a custom connector. The server registers
the client itself, so there is no client ID or secret to create.

## Remove the plugin

Claude Code:

```
claude plugin uninstall valet@valet
claude plugin marketplace remove valet
```

Codex:

```
codex plugin remove valet@valet
codex plugin marketplace remove valet
```

A copy installed with `npx skills add` lives in `~/.agents/skills/valet/`
or `~/.claude/skills/valet/`; delete that directory.

## Docs

[valet.dev/docs/mcp](https://www.valet.dev/docs/mcp)

## Support

[support@valet.dev](mailto:support@valet.dev)
