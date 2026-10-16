# Connectors

A connector is the organization's link to another tool, with the
credential Valet holds for it. Sites and agents hold connectors. Read the
`connectors` skill first: it owns where to look, what attaching grants,
and how to build a page on live data. This file gives the commands.

## Find one

| Task | CLI | MCP |
|---|---|---|
| The organization's connectors | `valet connectors --org <org>`; add `--sites` for those a site can hold | `list_connectors` |
| Valet's catalog | `valet connectors catalog`, `valet connectors catalog get <entry>` | `list_catalog_connectors` |
| One connector's state | `valet connectors info <name>` | `get_connector` |

`catalog get` shows an entry's transport and its secret slots, marking
the optional ones.

## Create one

Create connectors in the organization with `--org`, so every site and
agent can attach the same one. Use `--agent` only when one agent needs
it alone, such as a throwaway test agent.

**From the catalog,** after the person sets the slots it needs:

```
valet env set GITHUB_TOKEN=<value> --org acme   # the person runs this
valet connectors create github --org acme [--as <name>]
```

Over MCP, `create_connector` takes the entry and a `secrets` object of
slot to value, and creates nothing while a required slot is missing.
An entry that signs in through a browser needs the person: the CLI
prints a link and waits, and `create_connector` names the dashboard's
Integrations page, `https://dashboard.valet.dev/<org>/integrations`.
Send the person there and wait until they say it is done.

**Custom,** only when the catalog has no entry:

```
valet connectors create mcp-server <name> --org acme \
  --transport stdio --command npx --args -y,@example/mcp-server \
  --env API_KEY={{API_KEY}}

valet connectors create mcp-server <name> --org acme \
  --transport streamable-http --url https://mcp.example.com/mcp \
  --header "Authorization=Bearer {{API_TOKEN}}"

valet connectors create command <name> --org acme \
  --command gh --secrets GITHUB_TOKEN
```

- `--args` takes comma-separated values.
- `{{NAME}}` in `--env`, `--header`, or `--url` refers to an
  environment variable; `references/env.md` says how to set one.
- A remote server protected by OAuth needs no credential flags. The CLI
  creates it pending, opens a browser, and waits for the grant.
- **Name a command connector after the command the agent types.** The
  name becomes the program on the agent's `PATH` that injects its
  secrets. The `agentmail-cli` npm package runs as `agentmail`, so name
  the connector `agentmail` with `--command npx --args -y,agentmail-cli`.

A site can hold only an HTTP MCP server, on the `sse` or
`streamable-http` transport.

## Attach one

```
valet connectors attach <name> --site <site>      # MCP: attach_connector
valet connectors attach <name> --agent <agent> [--as <alias>]
valet connectors detach <name> --agent <agent>    # MCP: detach_connector
```

Attaching one that is already attached changes nothing.

## Sample and call one

```
valet sites info <site> --schemas                 # MCP: list_connector_tools
valet connectors call <connector> <tool> [--args '<json>'] --site <site>
                                                  # MCP: call_connector
```

`valet connectors call` runs the tool for real. It prints the
connector's answer, and when the connector refuses, prints its sentence
and exits 1. That sentence usually names the fix.

A page calls its site's connectors through the helper in the
`connectors` skill's `client.md` and `helper.js`. Read them with
`get_skill`, passing `skill: connectors` and `path`.
`examples/system-health.html` carries a copy from this release.

## Repair and remove

`valet connectors info` shows `active` or `pending`, and for a
connector holding a credential, its auth state: `pending`, `active`,
`needs_reauth`, or `revoked`, with the provider's reason when a grant
broke.

```
valet connectors reauthorize <name>    # MCP: reauthorize_connector
valet connectors destroy <name>        # MCP: destroy_connector
```

## Verify an agent's command connectors

After deploying, ask the agent to use each command connector once. Its
answer shows the connector can sign in without showing its secret. Do
not copy a Valet-held secret into a local shell to test it.
