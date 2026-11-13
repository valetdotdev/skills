# Environment variables

An environment variable is a named value an app or agent reads, set on
the organization or on one service. A site has none. Each has a kind:

- **Secret,** the default on the CLI: a credential. A connector or channel uses it
  through `{{NAME}}`, and an app reads it from its environment. An agent
  never sees it, and lists mask it.
- **Plain:** configuration such as a region or a base URL. An agent
  reads it as `$NAME`, and its name appears in the agent's prompt.

## Set, list, unset

```
valet env set <NAME=VALUE>... [--plain] [--org <org> | --agent <agent> | --app <app>]
valet env [--org <org> | --agent <agent> | --app <app>]
valet env unset <NAME> [--org <org> | --agent <agent> | --app <app>] [--force]
```

Over MCP: `set_env_vars`, `list_env_vars`, and `unset_env_vars`.

- One `set` applies one kind to every name in it, and prints the kind.
  Setting a name with the other kind changes its kind.
- Each change restarts the services it reaches. For an agent or an
  app, the CLI waits until it runs again; `--no-wait` skips that.
- A name set on a service overrides the organization's. `valet env`
  marks it `overrides org`.
- `valet env unset` refuses while a connector or channel uses the name,
  and names it. `--force` only after the person agrees those may break.
- Plain variables may not use names Valet reserves, such as `VALET_*`,
  `LD_*`, `PATH`, and `HOME`.

## Who types a secret

The person sets secrets, not you: in their own terminal with
`valet env set`, or on a request page. You may set plain values yourself.

Over MCP, `set_env_vars` takes `plain_vars` for plain values, which it applies
at once. For secrets it takes `secret_names`, an array of names, and a
`reason`, one sentence the person reads. It sets no secret. It returns
a `request` with a `url`, which opens a dashboard page for a signed-in
member of the organization. The link holds no credential, and it
expires in 15 minutes. Tell the person the variable's name and the
format its value takes, including any prefix the service expects. Give
them the link. Then call `get_request` with the request's `id` and
`wait_seconds` 20 until the state is `completed`, `declined`, or
`expired`.

Completing the request needs the Developer role. A member without it
sees the page and can forward the link. The services restart when the
person completes the request, not before. Passing the old `secret`
boolean is refused.

## Set on the organization by default

Set a variable with `--org` so every service that needs it shares it,
and rotation is one command. When one agent needs a different value for
a name an organization connector uses, set that name on the agent with
`--agent`. The connector picks up the agent's value. Do not create a
second connector.

## Use one in a connector

`{{NAME}}` in a connector's `--env`, `--header`, or `--url` refers to a
variable of either kind, anywhere in the value:

```
--url https://{{DB_HOST}}/api
--header "Authorization=Bearer {{API_TOKEN}}"
```
