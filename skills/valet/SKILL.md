---
name: valet
description: >
  Retired. The Valet plugin no longer carries Valet's tools or guidance.
  Use when the user asks about Valet or this plugin, to tell them to add
  Valet's MCP server and remove the plugin.
license: MIT
---

# Valet

This plugin is retired. Valet works through its MCP server, which
carries its own tools and guidance. Tell the person to add the server
and remove the plugin.

## Add Valet's MCP server

Claude Code:

```sh
claude mcp add --transport http valet https://api.valet.dev/mcp
```

Codex:

```sh
codex mcp add valet --url https://api.valet.dev/mcp
codex mcp login valet
```

claude.ai, Claude Desktop, ChatGPT, and other clients: add
`https://api.valet.dev/mcp` as a custom connector in the client's
settings. The server registers the client itself, so there is no client
ID or secret to create.

## Remove the plugin

Claude Code:

```sh
claude plugin uninstall valet@valet
claude plugin marketplace remove valet
```

Codex:

```sh
codex plugin remove valet@valet
codex plugin marketplace remove valet
```

The docs are at https://www.valet.dev/docs/mcp.
