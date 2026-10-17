# Problems and refusals

Valet reports a problem as `<code>: <message>`, such as
`deploy.draft_open: support-bot has changes open from another deploy`.
The message names the service and the next step. Read it, do that step,
and stop guessing: never retry with other flags, and never weaken a
setting to get past a refusal.

A message that says the problem is on Valet's side, or nothing was
deployed, means what it says. Retry once. If it fails again, tell the
person and give them the code; they can email support@valet.dev.

## Codes that need a decision

| Code | Do |
|---|---|
| `deploy.draft_open` | Another session left changes open. Ask the person before replacing them with `discard_draft` on `publish_app` or `publish_agent`. A publish with `push` never meets this. |
| `deploy.needs_setup` | Set up the connectors, channels, or skills it names, then deploy again. Deploy without them only if the person agrees. |
| `org.billing_required` | Only the person can add a payment method. Tell them, and stop. |
| `org.cap_reached` | Ask the person what to destroy, or tell them to ask support@valet.dev to raise the limit. |
| `org.ambiguous` | Pass `--org` or `org_name`. |
| `name.taken`, `name.retired`, `name.reserved`, `name.invalid` | Choose another name. A name is 3 to 63 lowercase letters, digits, and hyphens. |
| `account.not_logged_in`, `account.login_expired` | `valet auth login`, or let the MCP call start its sign-in. |
| `account.suspended` | Tell the person, and stop. |

## Push refusals

A refused push or publish deploys nothing, and the live release keeps
serving. The message names the push, the commit, and the path or limit
at fault.

| Code | Do |
|---|---|
| `deploy.source_moved` | Someone published the service after your push was created. For a site or app, reconcile: `references/publish.md` § Reconcile a refused push. Over `files`, read the source again so your publish keeps the other change, then publish again. `valet deploy` retries by itself. |
| `deploy.push_expired` | The push passed its hour, or a publish already used it. If your change is live, stop. Otherwise `create_push` again, push your commit to the new push, and publish. If Git refuses that push as not a fast-forward, reconcile as for `deploy.source_moved`. |
| `deploy.push_mismatch` | The push holds another commit than the one you named. Check that `git push` succeeded, then publish the commit `git rev-parse HEAD` prints. |
| `deploy.push_unrelated` | Your commit does not build on the push's branch. Fetch the branch, commit your files on top of it, as the directory recipe does, and push again. |
| `deploy.too_many_pushes` | The service holds 10 open pushes. Publish one you opened, or wait until the time the message names. |
| `deploy.source_invalid` | The source holds a symbolic link, a submodule or nested `.git`, a path under `.git` or `.valet`, or a Git LFS pointer file. Replace the link or pointer with the real file, or remove the entry. Commit, push to the same push, and publish the new commit. |
| `deploy.too_large` | A file or the whole source is over the kind's limit, which `create_push` returns as `limits`, or an app's `Procfile` or `valet.yaml` is over 1 MB. Remove or shrink files, commit, push to the same push, and publish the new commit. |
| `deploy.procfile_missing` | An app's source has no root `Procfile`. Add one that declares a `web` process, commit, push to the same push, and publish the new commit. |
| `deploy.procfile_invalid` | A `Procfile` line is not `type: command`. The message quotes the line. Fix it, commit, push to the same push, and publish the new commit. |

## Codes that name their own fix

| Family | What it covers | Usual step |
|---|---|---|
| `build.*` | An app's build failed, ran too long, ran out of memory, or grew too large | Read the build log, fix the source, and publish again. Nothing was deployed. |
| `app.*` | A process exited, did not listen on `$PORT`, timed out, or is scaled to zero | Read the logs; the `apps` skill covers start-up. |
| `site.*` | A site has no release, a file is missing, or a request was refused | `site.static_only` means a form posted to a site; send it to an app. |
| `manifest.*` | `valet.yaml` is invalid, or an agent has no `SOUL.md` | Fix each listed line; run `valet manifests validate`. |
| `connector.*` | A connector's credential, command, or server failed | `references/connectors.md` § Repair and remove. |
| `channel.*` | A channel's name, type, scope, secret, or signature is wrong | `references/channels.md`. |
| `agent.*`, `message.*`, `conversation.*` | An agent failed to start, run, or reply | `get_logs` or `valet logs`, then the session with `get_session`. |
| `skill.*`, `resource.*`, `logs.*`, `release.*` | Less common refusals | Follow the message. |

## CLI-only refusals

`cli.upgrade_required` means the installed `valet` is older than 0.1.89
and can no longer deploy. Run `valet update`, then the command again.

The anonymous-site refusals are in `references/publish.md`. For any
other command, `valet <command> --help` describes its flags and states.
