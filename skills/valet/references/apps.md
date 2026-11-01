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
run it themselves.

Share an app with named people as a website is shared. A person it is
shared with can use everything the app does, so say so before sharing
an app that changes data.

| Task | CLI | MCP |
|---|---|---|
| Share with named people | `valet apps share <name> <email>... [--message <text>] [--expires-in <dur>] [--expires-after-open <dur>]` | `share_service` with `emails` (1 to 10), `message`, `expires_in`, and `access_ttl` |
| List or end shares | `valet apps shares <name>`, `valet apps unshare <name> <email>` | `get_service`, `unshare_service` |

## Webhooks and schedules

An app takes `webhook`, `cron`, and `heartbeat` channels;
`references/channels.md` says how to create one with a `path`. Valet
posts each delivery to that route with an `X-Valet-Visitor` token of
kind `channel`, whose `channel` claim holds `id`, `name`, and `type`.
The token names no person. The handler:

- verifies the token as the `apps` skill describes, and accepts kind
  `channel` only on that route;
- treats `delivery_key` as an idempotency key, because deliveries
  repeat and arrive out of order;
- returns 2xx once the work is done. Any other answer, a 404 included,
  retries with growing waits for about a day.

Keep the app private. A sleeping app wakes for a delivery, and a
heartbeat under about 35 minutes keeps it awake.

A Stripe webhook. Set the signing secret, then create the channel:

```
set_env_vars   name=billing vars={"STRIPE_WEBHOOK_SECRET": "whsec_..."}
create_channel name=billing channel=stripe-events channel_kind=webhook \
  path=/webhooks/stripe verify_scheme=stripe secret_name=STRIPE_WEBHOOK_SECRET
```

Valet checks Stripe's signature, so the handler does not. It verifies
the visitor token and skips events it has seen:

```js
app.post("/webhooks/stripe", express.json(), async (req, res) => {
  const v = await visitor(req); // the jose helper in the apps skill
  if (v.kind !== "channel") return res.sendStatus(403);
  if (await seen(v.delivery_key)) return res.sendStatus(200);
  await handleEvent(req.body); // for example, mark an invoice paid
  await markSeen(v.delivery_key);
  res.sendStatus(200);
});
```

A thrown error before `res.sendStatus(200)` answers 500, so Valet
retries the delivery.

## Run it

| Task | CLI | MCP |
|---|---|---|
| Read output | `valet logs --app <name> [-f]` | `get_logs` |
| See processes | `valet ps --app <name>` | `get_service` |
| List releases | `valet releases --app <name>` | `list_releases` |
| Start a worker | `valet ps scale worker=1 --app <name>` | `scale_service` |
| Restart | `valet ps restart --app <name>` | `restart_service` |
| Rename | `valet apps rename <name> <new-name>` | `rename_service` |
| Remove | `valet apps destroy <name>` | `destroy_service` |

Removing an app keeps its resources; `references/resources.md` says how
to let them go. The `apps` skill says how to undo a release.
