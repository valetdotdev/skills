## Pre-Deploy Verification with valet exec

`valet exec` is the **only way** to run local commands with Valet-managed secrets injected. Secrets are stored in the control plane — they are **not** available as shell environment variables. Always test secret-backed commands before deploying.

There are two modes:

### Connector mode (no `--`)

The first argument is looked up as a connector name. If a `command` connector is found, its secrets are fetched and injected, and the connector's configured command is executed. Extra arguments are appended after the connector's configured args:

```
# Run the "gh" command connector (looks up connector named "gh")
valet exec -a my-agent gh pr list

# Use linked agent from current directory
valet exec gh pr list
```

### Explicit secrets mode (with `--`)

Secret names are passed as a comma-separated positional argument before `--`. The command and its arguments follow after `--`:

```
valet exec [-a <agent>] SECRET[,SECRET...] -- command [args...]
```

Fetches the requested secret values and executes the given command with those secrets injected into the environment. The current process is replaced by the command.

```
# Run gh with GITHUB_TOKEN injected as an env var
valet exec -a my-agent GITHUB_TOKEN -- gh pr list

# Pass a secret as a CLI argument using {{}} syntax
valet exec -a my-agent API_KEY -- curl -H "Authorization: Bearer {{API_KEY}}" https://api.example.com

# Multiple secrets in one command
valet exec -a my-agent GITHUB_TOKEN,SLACK_TOKEN -- env
```

Flag: `--agent` or `-a`: Agent that owns the secrets (uses linked agent if omitted). Run `valet exec --help` for full details.

### Template syntax for CLI arguments

Use `{{SECRET_NAME}}` in command arguments to substitute secret values directly. This is useful for tools that accept credentials as flags or in URLs rather than reading from the environment. Works in both modes.

### Running MCP servers locally

To test an MCP server that requires secret-backed environment variables:

```
valet exec -a my-agent SLACK_BOT_TOKEN,SLACK_TEAM_ID -- \
  npx -y @modelcontextprotocol/server-slack

Without `valet exec`, the MCP server would start without the required tokens and fail to authenticate.

### Why valet exec is required

Regular shell commands (`curl`, `npx`, `node`, etc.) cannot access Valet secrets. This will **not** work:

```
# WRONG — $API_KEY is not set in your shell
curl https://api.example.com/data?key=$API_KEY

# CORRECT — valet exec injects the secret (explicit secrets mode)
valet exec -a my-agent API_KEY -- curl https://api.example.com/data?key={{API_KEY}}

# OR use connector mode if you have a command connector configured
valet exec -a my-agent my-connector-name
```

The same applies to any connector command. If your connector's `--command` or `--args` reference environment variables backed by secrets, test the exact command through `valet exec` before deploying.

