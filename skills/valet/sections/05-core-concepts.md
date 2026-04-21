## Core Concepts

- **Agent**: An AI agent defined by a `SOUL.md` file in a project directory. Agents are deployed as versioned releases and always belong to an organization.
- **Organization**: A team workspace that owns agents, connectors, channels, and secrets. All agents belong to an org — the default org is used when `--org` is omitted.
- **Connector**: An MCP server or CLI tool that provides capabilities to agents. Types: `mcp-server` (MCP tools via client) and `command` (CLI with secret injection). Transports: `stdio`, `sse`, `streamable-http`.
- **Channel**: A message entry point for agents. Types: `webhook`, `slack`, `telegram`, `heartbeat`, `cron`. Each channel has a session strategy and a prompt path.
- **Secret**: An encrypted credential scoped to an org or agent. Referenced with `{{NAME}}` template syntax in connector and channel configurations. Agent-scoped secrets override org-scoped secrets of the same name.
- **Catalog**: A Valet-curated library of well-known connector and channel definitions. Browse with `valet connectors catalog` or `valet channels catalog`. Add from the catalog instead of configuring from scratch.
- **Shared resources**: Connectors, channels, and secrets can be scoped to an org and shared across agents. The pattern is: add from catalog (or create) at the org level, then attach to agents that need them. This maximizes reuse and simplifies credential rotation.
- **Channel file**: A markdown file at `channels/<channel-name>.md` that tells the agent how to handle incoming messages.

