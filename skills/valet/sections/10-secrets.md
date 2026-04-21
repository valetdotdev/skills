## Secrets

Secrets are credentials (API tokens, service keys, signing secrets) used by connectors and channels at runtime. The agent can invoke tools that depend on secrets but never sees the values — they flow through connectors and channels, not through the agent's environment. Reference a secret in connector or channel configuration with `{{NAME}}` syntax.

**NEVER ask the user for secret values within the LLM session.** Direct them to run `valet secrets set NAME=VALUE --org <org>` in their terminal and wait for confirmation before proceeding.

### Set secrets

```
valet secrets set <NAME=VALUE>... [--org <org>] [--agent <agent>] [--no-wait]
```

Must specify exactly one scope: `--org` or `--agent` (or run from a linked agent directory). Agent-scoped secrets trigger a redeploy; org-scoped do not.

### {{NAME}} template syntax

Use `{{NAME}}` in connector `--env`, `--header`, or `--url` values to reference a secret. Templates are resolved at deploy time and can appear anywhere in a value:

```
--url https://{{DB_HOST}}/api
--header "Authorization=Bearer {{API_TOKEN}}"
--env SLACK_BOT_TOKEN={{SLACK_BOT_TOKEN}}
```

When directing the user to set secrets, **always tell them what format the value should be in**, including any prefix the service expects.

### List and remove

```
valet secrets [--agent <name> | --org <name>]
valet secrets unset <NAME> [--agent <name> | --org <name>] [--force]
```

