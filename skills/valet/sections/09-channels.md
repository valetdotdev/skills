## Channels

Channels are message entry points for agents. Follow the Resource Creation Principles above — the catalog encodes signing schemes and service-specific behaviors for webhook channels.

### Browse the catalog

```
valet channels catalog
valet channels catalog get <name>
```

The catalog contains Valet-curated channel definitions for well-known services (GitHub webhooks, Slack Events API, Stripe, etc.). Each entry defines signing scheme, event taxonomy, and required secret slots.

### Create from the catalog (preferred for webhooks)

```
valet channels create <entry> [--org <org>] [--agent <agent>] [--as <name>]
```

Creates a channel from the catalog. Use `--as` to rename the instance. If the catalog entry defines secret slots (e.g. `WEBHOOK_SECRET`), managed secrets are auto-generated and stored in `valet secrets`. The `managed` field in the output is the secret name — use `valet secrets set` to rotate it.

Example:
```
valet secrets set GITHUB_WEBHOOK_SECRET=whsec_abc123 --org acme
valet channels create github-webhook --org acme
```

### Attach / Detach

Attach an org channel to an agent. Use `--events` to filter which event types are delivered:

```
valet channels attach <name> [--agent <agent>] [--as <alias>] [--events <types>] [--bot-name <name>]
valet channels detach <name> [--agent <agent>] [--force]
```

For Slack channels, `--bot-name` sets the bot display name (defaults to agent name). After attaching, the CLI opens a browser for the Slack OAuth install flow and shows the bot name and workspace.

For Slack channels, detaching destroys the per-agent Slack bot. The CLI prompts for confirmation before proceeding. Use `--force` to skip the prompt.

Example:
```
valet channels attach github-webhook --agent my-reviewer --events pull_request,issue_comment
valet channels attach slack --agent my-agent --bot-name my-bot
valet channels detach slack --force
```

### Create a webhook channel

```
valet channels create webhook [name] \
  [--agent <agent-name>] [--org <org>] \
  [--verify <scheme>]
```

Verification schemes: `hmac-sha256` (default), `slack`, `stripe`, `svix`, `static-token`, `none`. Key flags: `--secret-name` (name of an existing secret from `valet secrets` to use instead of auto-generating; required for `slack`, `stripe`, and `svix`), `--signature-header` (not used with `slack` or `svix`), `--delivery-key-header`, `--delivery-key-path`, `--prompt`. For `hmac-sha256` and `static-token`, a managed secret is auto-generated if `--secret-name` is omitted. The `slack` scheme implements Slack's Events API signing protocol and handles `url_verification` challenges automatically. Run `valet channels create webhook --help` for full details.

The command outputs the **webhook URL**, **signing secret**, and (if applicable) **managed secret name** — always save and report these to the user.

### Create a Slack channel

```
valet channels create slack [name] \
  [--agent <agent-name>] [--org <org>] \
  [--bot-name <display-name>]
```

Creates a Slack channel that enables agents to participate in your Slack workspace. Before creating the channel, the CLI automatically checks whether the org has a connected Slack workspace. If not connected, it prompts you to connect via OAuth, opens a browser window for authorization, and polls until the connection is confirmed. The `--bot-name` flag sets the Slack bot display name (default: agent name, resolved server-side). The command outputs the bot name and workspace after setup. Run `valet channels create slack --help` for all flags.

### Create a Telegram channel

```
valet channels create telegram [name] \
  [--agent <agent-name>]
```

Creates a Telegram channel and outputs a deep link (`t.me/...`) for connecting the bot. Run `valet channels create telegram --help` for all flags.

### Create a heartbeat channel

```
valet channels create heartbeat [name] --agent <agent-name> --every 5m
```

Fires a prompt on a fixed interval. Run `valet channels create heartbeat --help` for all flags.

### Create a cron channel

```
valet channels create cron [name] --agent <agent-name> --schedule "every day at 9am"
# Or with a raw crontab expression:
valet channels create cron [name] --agent <agent-name> --cron "0 9 * * *"
```

Run `valet channels create cron --help` for all flags (`--timezone`, `--prompt`, etc.).

### List, inspect, destroy

```
valet channels [--org <org>] [--agent <agent>]
valet channels info <name>
valet channels destroy <name>
```

For Slack channels, `valet channels` shows the workspace name in the listing. Destroying an org-level Slack channel cascades — all per-agent Slack bots are destroyed first, then the org Slack connection is removed.

