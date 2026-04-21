## Agent Project Structure

```
my-agent/
  valet.yaml           # Manifest for 1-click dashboard setup (required)
  AGENTS.md            # Setup guide for future developers (required)
  SOUL.md              # Agent identity and behavior (required)
  valet.yaml           # Manifest — required for catalog-published agents
  channels/            # Channel files (for webhook/trigger-driven agents)
    <channel-name>.md
  skills/              # Agent-scoped skill documentation (optional)
    <connector-name>/
      SKILL.md
  .valet/
    config.json        # Auto-managed by CLI
```

All deployed files are **read-only** at runtime. The agent can write new files (e.g., MEMORY.md), but written files **do not survive deploys**.

