## Onboarding

### Scaffold a new agent project

Create a new agent project directory without running the full setup flow:

```
valet new <name> [--dir <path>]
```

Creates `<name>/` (or the path specified by `--dir`) containing `SOUL.md`, `AGENTS.md`, `skills/`, and `channels/`. The project is ready to edit — update `SOUL.md` to define your agent, then run `valet agents create` to deploy it.

Flags:
- `--dir`: Directory to create the project in (default: `./<name>`)

