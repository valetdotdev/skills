## Connectors

Connectors give agents access to MCP tools and CLI commands. Follow the Resource Creation Principles above.

### Browse the catalog

```
valet connectors catalog
valet connectors catalog get <name>
```

The catalog contains Valet-curated connector definitions for well-known services (GitHub, Slack, Sentry, Linear, etc.). Each entry defines transport, command, and required secret slots. Optional slots are labeled `(optional)` in the output of `valet connectors catalog get <name>`.

### Create from the catalog (preferred)

```
valet connectors create <entry> [--org <org>] [--agent <agent>] [--as <name>]
```

Creates a connector from the catalog. Use `--as` to rename the instance (useful for multiple instances with different credentials). Required secrets must already be set.

Example:
```
valet secrets set GITHUB_TOKEN=ghp_abc123 --org acme
valet connectors create github --org acme
```

### Create a custom connector

Only use type-specific subcommands when the catalog doesn't have what you need:

```
# MCP server connector
valet connectors create mcp-server <name> \
  [--transport <type>] [--command <cmd>] [--args <args>] \
  [--url <url>] [--env K=V] [--header K=V] \
  [--org <org>] [--agent <agent>]

# Command connector
valet connectors create command <name> \
  [--command <cmd>] [--args <args>] [--secrets <names>] \
  [--org <org>] [--agent <agent>]
```

**Important**: `--args` takes comma-separated values. Use `{{NAME}}` to reference secrets in `--env` and `--header` values.

```
# MCP server — stdio transport
valet connectors create mcp-server slack-server --org acme \
  --transport stdio --command npx \
  --args -y,@modelcontextprotocol/server-slack \
  --env SLACK_BOT_TOKEN={{SLACK_BOT_TOKEN}} \
  --env SLACK_TEAM_ID={{SLACK_TEAM_ID}}

# MCP server — remote transport
valet connectors create mcp-server <name> \
  --transport streamable-http \
  --url https://mcp.example.com/mcp \
  --header Authorization={{API_TOKEN}}
```

**Command connectors** wrap CLI tools. They require `--command` and accept `--secrets` (comma-separated secret names injected at runtime).

**Naming rule**: Name the connector after the CLI command the agent will type. The connector name becomes the executable on the agent's PATH, so it must match the command exactly. For tools installed via npx, the CLI command may differ from the npm package name — always use the CLI command.

```
# "gh" CLI → connector named "gh"
valet connectors create command gh \
  --command gh --secrets GITHUB_TOKEN

# "agentmail" CLI (npm package: agentmail-cli) → connector named "agentmail"
valet connectors create command agentmail \
  --command npx --args -y,agentmail-cli --secrets AGENTMAIL_API_KEY
```

**How command connectors surface to agents**: At runtime, the supervisor generates a wrapper script in `~/bin/` named after the **connector name**. The connector name becomes an executable on the agent's PATH that transparently injects secrets and runs the configured command. Only the connector name is on PATH — the agent runs `agentmail inboxes list`, not `npx agentmail-cli inboxes list` (which bypasses the wrapper and gets no secrets).

Run `valet connectors create --help` for all flags.

### Attach / Detach

Attach an org connector to an agent. Use `--as` for a custom alias:

```
valet connectors attach <name> [--agent <agent>] [--as <alias>]
valet connectors detach <name> [--agent <agent>]
```

### List and inspect

```
valet connectors [--org <org>] [--agent <agent>]
valet connectors info <name>
```

`valet connectors info` shows name, type, transport, command, args, URL, env, headers, secrets (for connectors with `--secrets` configured), and catalog origin.

### Destroy a connector

```
valet connectors destroy <name>
```

