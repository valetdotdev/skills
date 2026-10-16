# The valet CLI

Run `valet` with the terminal tool for the person's operating system.

## Install

Run `valet version` first. If `valet` is missing, say why the work needs
it and ask before installing:

> This needs the Valet CLI, because it publishes files the connected
> tools cannot carry. May I install the official release for your
> operating system?

After the person agrees:

```sh
curl -fsSL https://valet.dev/install.sh | sh   # macOS or Linux
```

```powershell
irm https://valet.dev/install.ps1 | iex        # Windows PowerShell
```

Run `valet version` again. If a Unix shell has not reloaded its `PATH`,
use `$HOME/.local/bin/valet` for the rest of the session. Do not
reinstall.

`valet version` prints `valet/<version> <os>-<arch> <go>`. If a command
needs a newer CLI, or fails with `unknown flag`, ask before updating,
then run `valet update`. The updater keeps the install method: a direct
install updates itself, and a Homebrew install updates through Homebrew.

If installing or updating fails, report the error and stop. Never
download a raw binary, change a package manager's configuration, or
build the CLI from source.

## Sign in

Any command that reads or writes an account needs a session. `valet
version`, help, and `valet manifests validate --offline` do not.

1. Run `valet auth whoami`. It shows the account, the default
   organization, and any linked project.
2. If signed out, say that a browser window will open, then run
   `valet auth login`.

If sign-in fails, run no account command. An anonymous site needs no
sign-in; see `references/publish.md`.

## Help

```
valet help <command>               # e.g. valet help channels
valet <command> <subcommand> --help
valet topics                       # list the guides
valet topics <name>                # getting-started, agent-lifecycle, channels,
                                   # connectors-overview, resolution
```

Read the help before guessing a flag. It matches the installed CLI.

## Link a directory

A linked directory holds `.valet/config.json`, which names the service
and its organization. Commands run inside it target that service.
`valet sites create`, `valet apps create`, and `valet agents create` link
the directory they run in.

```
valet sites link <name>
valet apps link <name>
valet agents link <name> [--org <org>] [--force]
```

Link only a directory that already holds the service's complete source:
the next deploy replaces the service with it. `valet agents link` needs
`--org` when you belong to several organizations, and `--force` to
replace an existing link. `references/orgs.md` says how a command picks
its organization and service when no directory is linked.

## Deploy

```
valet deploy [-a <agent>] [--org <org>] [--no-wait] [--force]
```

`valet deploy` publishes the linked site, app, or agent. It commits the
directory and pushes it with Git, so it needs Git 2.32 or later; it
checks before it changes anything. An anonymous site's deploy needs no
Git. `references/publish.md` says what it
uploads and how each kind confirms.

- If the source matches what is already deployed, deploy exits 0 and
  ships nothing. `--force` rebuilds it.
- If someone published the service during the deploy, deploy pushes
  again over their change by itself. The directory is the whole source,
  so their change is replaced; read the service first when that matters.
- If an agent's `valet.yaml` names connectors or channels that are not
  attached, deploy stops and lists them. Attach them, or pass
  `--allow-unsatisfied` to run without them.

### Drafts

A draft is an agent's change that is not yet published, such as one
from a dashboard session. `valet deploy` does not use one. Use drafts to
review a change before it ships:

```
valet drafts [--agent <name>]              # list open drafts
valet drafts create [--agent <name>]       # prints the draft id
valet drafts push <id> [--dir <path>] [-m <message>]
valet drafts publish <id>
valet drafts discard <id>
```

An agent has at most one open draft.

## Run and watch

| Command | Does |
|---|---|
| `valet logs [-n <lines>] [-f]` | Prints the last 100 lines and exits; `-f` keeps streaming, `-n 0` skips history |
| `valet ps` | Lists processes and their state, `idle` included |
| `valet ps restart` | Restarts processes without a new release |
| `valet ps scale <type>=<value>` | Sets a process count, or an agent's model |
| `valet run <prompt>` | Sends one prompt to an agent |
| `valet console [--resume <session-id>]` | Opens a conversation with an agent |
| `valet sessions` | Lists, shows, and deletes an agent's sessions |
| `valet drains` | Sends logs to an OTLP HTTP endpoint |

Outside a linked directory, name the service with `-a <agent>` or
`--app <app>`, and `--org <org>`.
Deleting a session deletes its transcript; confirm first.

To watch an agent while the person triggers it, run `valet logs -n 0 -f`
in the background with its output going to a file, then read the file. Healthy
runs show few turns, paired `mcp_call_tool_start` and
`mcp_call_tool_done` events, and `dispatch_complete`. Many turns with
only built-in tools mean the agent is looping. No `dispatch_complete`
means it stalled.

### Scaling

`valet ps scale` sets an app's process counts and an agent's model:

```
valet ps scale worker=1                   # start an app's worker
valet ps scale agent=glm-5.3              # change the model, keep the count
valet ps scale agent=0                    # stop the agent, keep the model
valet ps scale agent=claude-sonnet-5:1    # both at once
```

An agent's count is 0 or 1. Changing one setting keeps the other.
Scaling restarts processes; it does not make a release. Run
`valet help ps scale` for the current models rather than quoting one
from memory. A site has no processes and cannot be scaled.
