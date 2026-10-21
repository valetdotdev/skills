# Policies

A **release policy** runs a **checker** on every release in the
organization before it goes live. A Monitor policy records what it finds.
A Block policy refuses a release with a finding at or above its severity.
Valet ships two checkers, `catalog:osv` and `catalog:secrets`. A **custom
checker** is an HTTPS endpoint the organization writes; a policy names it
as `org:<name>`.

The spec is <https://www.valet.dev/docs/custom-checkers>, and the
policies guide is <https://www.valet.dev/docs/policies>. Any page there
answers `Accept: text/markdown` with a Markdown copy.

## Policies

| Task | CLI | MCP |
|---|---|---|
| List policies, checkers, and 30-day counts | `valet policies`, `valet policies checkers` | `list_policies` |
| Add or replace a policy | `valet policies add <name> --checker <checker> --monitor` or `--block-at high` | `set_policy` |
| Pass a setting | `--set name=value` | `settings` |
| Remove a policy | `valet policies remove <name>` | `destroy_policy` |
| Read a release's evaluation | `valet policies show -a <name>` | `get_evaluation` with `wait_seconds` |

Adding a name that exists replaces the policy, settings included, so
pass every setting again. Start a new policy in Monitor, read what it
finds, and make it block only when the person says so.

## A blocked release

A publish holds a built release while blocking policies evaluate it. It
ends in one of two errors, and either way the live release is unchanged:

- `deploy.policy_blocked`: a finding is at or above the policy's
  severity. Read the findings with `get_evaluation` or
  `valet policies show`, fix what they name, and publish again.
- `deploy.policy_errored`: the checker could not evaluate the release.
  Publish again. If it keeps erroring, tell the person; a member can
  change or remove the policy.

Never remove or weaken a policy to get a release through unless the
person asks. Switching a policy to Monitor does not release a deploy it
already holds; publish again after the change.

## Build a custom checker

A checker is a small HTTPS service. Valet sends it `POST` requests to
`<url>/v1/describe`, `/v1/validate`, `/v1/start`, and `/v1/poll`, with
the headers the checker was added with. Read the whole spec before
writing code. These are the parts that are easy to get wrong:

- **Answer within 30 seconds.** A scan that takes longer answers
  `start` with `accepted` and reports later, by `poll` with a `handle`
  or by the callback with no handle.
- **Replay idempotency keys.** Valet retries `start` with the same
  `idempotency_key`. Answer a repeated key as the first time, and do not
  start the work twice.
- **Fetch archives with `GET` before they expire.** A link lasts an
  hour, and each `poll` carries fresh ones. A 404 means the link is
  dead, whatever the reason.
- **Treat a callback's 409 as done.** Retry the callback on 503 and on a
  connection failure only.
- **Report `failed` when you cannot evaluate.** Valet treats it as
  errored, never as passed.
- **Use the five severities.** Any other severity blocks as critical.
  A `done` answer with no findings passes the release.
- **Skip what you have no opinion on.** Every policy evaluates every
  release; answer `done` with no findings for a service kind or file set
  the rule ignores.
- **Ask for the least.** `describe`'s `inputs` names `source`, `build`,
  or both. Valet sends only the approved file sets.

### Authenticate

The checker must refuse a call without its credential, answering 401.
Read the expected token from an env var, such as `CHECKER_TOKEN`, and
compare it in constant time. Never log the `Authorization` header, the
`start` or `poll` body, an archive URL, or a callback URL: the URLs are
credentials too.

### Test it

Write tests that play Valet's side of each operation: a `describe`, a
valid and an invalid `validate`, a `start` answered inline, a repeated
`idempotency_key`, a `poll` with its handle, a callback that answers 409,
and a call without the header. Serve the archive from the test so the
checker fetches it as it would from Valet.

### Deploy it

A checker can be a Valet app; read `references/apps.md` and the `apps`
skill. Valet calls it as an outside caller, so the app needs **public**
access and checks the header itself. A private app answers 401 to Valet.

1. Create and deploy the app, and confirm it is `up`.
2. Have the person set the token, on the app and on the organization,
   in their own terminal: `valet env set CHECKER_TOKEN=... --app <app>`
   and `valet env set CHECKER_TOKEN=... --org <org>`.
   `references/env.md` says why the value never passes through you.
3. Add the checker. A credential header must be a `{{NAME}}` reference
   to a secret org env var:
   `valet policies checkers add <name> --url <app-url> --header 'Authorization: Bearer {{CHECKER_TOKEN}}'`,
   or `set_checker`. Tell the person which files it receives; adding
   it agrees to send them to that URL.
4. Verify it: `valet policies checkers verify <name> --set key=value`.
   MCP has no verify tool; `list_policies` shows the checker's
   `last_error`.
5. Add a policy in Monitor: `valet policies add <name> --checker org:<name> --monitor`.
6. Publish a test site that should produce a finding, and read its
   evaluation. Publish one that should pass, and read that too.

Report the evaluations to the person. Leave the policy in Monitor until
they ask for it to block.

A Block policy also evaluates the checker app's own releases. If the
checker is broken, a fix to it waits on the broken checker: remove the
policy, deploy the fix, and add the policy back.

### Change or remove it

Adding a checker with a name that exists replaces it. Pass every header
again. A new URL or new headers restart its running evaluations at the
new endpoint.

Remove the policies that name a checker before the checker:
`valet policies checkers remove <name>`, or `destroy_checker`. While a
policy names it, Valet refuses with `policy.checker_in_use`.
