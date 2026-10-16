# Sites

A site is static files served at its own URL. Read the `sites` skill
before building one: it owns the artifact plan, the HTML contract, link
previews, and how to name and share the site. Read `design-system` for
the organization's identity. `references/publish.md` says how to publish
and update a site; this file covers the rest of its life.

## Share and set access

The `security` skill says which access to choose. These are the
mechanics.

| Task | CLI | MCP |
|---|---|---|
| Share with named people | `valet sites share <name> <email>... [--message <text>] [--expires-in <dur>] [--expires-after-open <dur>]` | `share_service` with `emails` (1 to 10), `message`, `expires_in`, and `access_ttl` |
| List or end shares | `valet sites shares <name>`, `valet sites unshare <name> <email>` | `get_service`, `unshare_service` |
| Show access | `valet sites access <name>` | `get_service` |
| Set access | `valet sites access <name> private\|password\|public` | `set_service_access` with `mode` |

A share emails each address a link that opens the site without a Valet
account. The link is a bearer credential: forwarding the email forwards
access. Neither deadline has a default, so an unflagged share never
expires. Sharing an address again re-sends its existing link.

**Keep a visitor password out of the conversation.** On the CLI, ask the
person to run `valet sites access <name> password` in their own
terminal; it prompts without echoing. Wait for them to confirm. Over
MCP, `set_service_access` takes the password as an argument, at most 72
bytes, so it stays in the transcript. Tell the person, and offer the CLI.

## Rename and remove

```
valet sites rename <name> <new-name>   # MCP: rename_service
valet sites destroy <name>             # MCP: destroy_service
```

Renaming moves the site to the address the new name gives it. Destroying
a site cannot be undone; confirm with the person first.

## Live data

A page that reads current numbers calls a connector attached to its
site. `references/connectors.md` says how to attach one and sample it.
`examples/system-health.html` is a complete page built that way.

## Test WebMCP at the site's own address

A site renders as a top-level document, so a browser that discovers
WebMCP tools only at the top level, such as Codex's built-in browser,
finds them there. When the work registers tools with
`document.modelContext.registerTool`:

- Test at the project's local development URL first when you can.
- After publishing, open the site's own address. A private site asks the
  visitor to sign in to Valet before it shows anything.

Never make a site public to make testing easier.
