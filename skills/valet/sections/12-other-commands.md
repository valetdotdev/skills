## Other Commands

| Command | Purpose | Help |
|---------|---------|------|
| `valet run <prompt>` | Send a single prompt to an agent; supports `--org` | `valet help run` |
| `valet console` | Start an interactive REPL with an agent; supports `--org` | `valet help console` |
| `valet exec` | Run a command with secrets injected into its environment | `valet help exec` |
| `valet logs [-n <num>]` | Stream live logs; shows 100 historical lines by default (`-n 0` for live only); supports `--org` | `valet help logs` |
| `valet ps` | List agent processes (can show `idle` state); supports `--org` | `valet help ps` |
| `valet drains` | Configure log drains (OTLP HTTP) | `valet help drains` |

