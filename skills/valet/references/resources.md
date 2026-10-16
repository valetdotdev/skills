# Resources

A resource is something the organization holds, such as a database or
an AI model, that an app reads through environment variables. Read the
`resources` skill first: it owns choosing a kind, naming and sharing
one, and letting it go. `list_catalog_resources` gives each kind's guide
for this installation; follow it rather than memory.

| Task | CLI | MCP |
|---|---|---|
| See the kinds and plans | `valet resources catalog` | `list_catalog_resources` |
| See what the organization holds | `valet resources`, `valet resources info <name>` | `list_resources` |
| Create and attach | `valet resources create <provider>:<plan> <name> --app <app> [--prefix <word>]` | `attach_resource` |
| Attach an existing one | `valet resources attach <name> --app <app> [--prefix <word>]` | `attach_resource` |
| Detach, keeping the data | `valet resources detach <name> --app <app>` | `detach_resource` |
| Destroy, with its data | `valet resources destroy <name>` | `destroy_resource` |

`--prefix` is the CLI's `env_prefix`: `--prefix EVENTS` sets
`EVENTS_DATABASE_URL` rather than `DATABASE_URL`. Attaching fails when a
name it would set already exists on the app or its organization.
