## Agent Lifecycle

### Create an agent

The current directory must contain a `SOUL.md` file. This creates the agent, links the directory, deploys v1, and waits for readiness:

```
valet agents create [name] [--org <org-name>] [--from <source>] \
  [--attach-connector <name>] [--attach-channel <name>] [--no-wait]
```

Name is optional (auto-generated if omitted). When `--org` is omitted, the default org is used. The default org is set automatically when you create or join an org.

Sources for `--from`:
- **Current directory (default)** — uses the `SOUL.md` in the current directory
- **Local path** — `--from .` or `--from ./path/to/agent`
- **Git URL** — `--from github.com/user/repo` clones and deploys from a remote repo
- **Catalog** — `--from catalog:name` creates from a Valet-curated agent template

Use `--attach-connector` and `--attach-channel` to wire org-scoped resources to the agent at creation time (repeatable flags).

### Manifest inline channels (cron and heartbeat)

When a `valet.yaml` manifest declares `cron` or `heartbeat` channels using `type:` instead of `catalog:`, `valet agents create --from` automatically creates those channels during the deploy flow — no separate `valet channels create` step needed:

```yaml
channels:
  - type: cron
    schedule: "every day at 9am"
    timezone: America/New_York
  - type: heartbeat
    every: 5m
```

Use `type` (mutually exclusive with `catalog`) to declare inline channels. Supported fields: `schedule` (human-readable), `cron` (raw crontab expression), `every` (heartbeat interval), `timezone` (IANA timezone, default UTC). Run `valet agents create --help` for all options.

### Link a directory

```
valet agents link <name>
```

Creates `.valet/config.json` so subsequent commands auto-detect the agent. Not needed if you created the agent from this directory.

### Deploy changes

After editing `SOUL.md`, channel files, or other project files:

```
valet agents deploy [-a <name>] [--org <org>] [--no-wait]
```

Use `--org` to specify the target organization when you belong to multiple orgs. When omitted, the default org from your config is used.

### List agents

```
valet agents [--org <name> | -o <name>]
```

Lists agents in the default org, or the org specified with `--org` / `-o`. Errors with a helpful message if no default org is configured. Run `valet agents --help` for all options.

### Show agent details

```
valet agents info <name> [--org <org>]
```

Displays owner, current release, process state (including `idle`), channels, and connectors. Use `--org` when looking up by name and you belong to multiple organizations. When `--agent` is a UUID, `--org` is not required. Run `valet agents info --help` for all options.

### Destroy an agent

```
valet agents destroy <name> [--org <org>]
```

Permanently removes the agent and all releases. Use `--org` to scope the lookup to a specific organization. Cannot be undone.

