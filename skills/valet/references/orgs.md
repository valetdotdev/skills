# Organizations

An organization owns every site, app, agent, connector, channel,
resource, skill, and environment variable. Its members can read and
change all of them.

```
valet orgs                         # list yours; MCP: list_orgs
valet orgs create <name>
valet orgs info <name>
valet orgs set-default <name>
valet orgs members <name>
valet orgs invite <name> <email>
valet orgs join <code>
valet orgs revoke <name> <email>   # cancel an invitation
valet orgs remove <name> <email>
valet orgs leave <name>
valet orgs destroy <name>
```

An organization's name is reserved for good, so confirm it with the
person before `valet orgs create`. Creating or joining one makes it the
default. Confirm before removing a member or destroying an organization.

## How a command picks its target

The CLI takes the organization and the service from the first of these
that applies, and never mixes them:

1. **Flags:** `--org`, and `--agent` or `--app`.
2. **The linked directory:** `.valet/config.json` names both.
3. **The default organization,** with no service.

So:

- Pass `--org` whenever you know it and the person may belong to more
  than one organization.
- Inside a linked directory, pass neither; a flag overrides the whole
  link.
- If `--agent X` alone fails with `agent exists in multiple orgs`, add
  `--org`.

`valet auth whoami` shows the default organization and any link, so you
can see what a bare command will target. `valet topics resolution` has
the full rules.

Over MCP, `org_name` picks the organization. Without it, a tool uses the
organization the account joined first, and every result names the
organization it used.
