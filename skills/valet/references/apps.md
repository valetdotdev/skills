# Apps

An app is a `Procfile` and Node, Python, or Go source that Valet builds
and runs. Read the `apps` skill before building one: it owns the
Procfile, each language's layout, start-up, configuration, and data.
Read `dependencies` before touching a manifest. `references/publish.md`
says how to publish and update an app.

## Lockfiles

Follow the `dependencies` skill on lockfiles. A CLI deploy uploads
whatever lockfile sits in the directory, so when that skill says to
leave a lockfile out, delete it from the directory before deploying.

## Access

Who can open a new app depends on the installation, so never assume
it. Read it after the first publish: `valet apps create` prints an
`Access` line, and `get_service` reports `access`. The `security` skill
says which mode to choose.

```
valet apps access <name>                         # show
valet apps access <name> private|password|public # set; MCP: set_service_access
```

On a terminal, password mode prompts without echoing; ask the person to
run it themselves. An app has no per-person shares.

## Run it

| Task | CLI | MCP |
|---|---|---|
| Read output | `valet logs --app <name> [-f]` | `get_logs` |
| See processes | `valet ps --app <name>` | `get_service` |
| Start a worker | `valet ps scale worker=1 --app <name>` | `scale_service` |
| Restart | `valet ps restart --app <name>` | `restart_service` |
| Rename | `valet apps rename <name> <new-name>` | `rename_service` |
| Remove | `valet apps destroy <name>` | `destroy_service` |

Removing an app keeps its resources; `references/resources.md` says how
to let them go. The `apps` skill says how to undo a release.
