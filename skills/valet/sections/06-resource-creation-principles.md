## Resource Creation Principles

These principles apply to all connectors, channels, and secrets. Follow this priority order every time:

1. **Catalog first**: Check `valet connectors catalog` or `valet channels catalog` before creating from scratch. Catalog entries handle transport, commands, and secret slots automatically.
2. **Reuse existing**: Check `valet connectors --org <org>` or `valet channels --org <org>` for resources that already provide what you need. Attach rather than duplicate.
3. **Org-scoped by default**: Create resources at the org level (`--org`) so they can be shared across agents. Only use agent-scoped resources when a resource is truly single-agent.
4. **Secrets at org level**: Default to `--org` for secrets so connectors and channels shared across agents can all access them. Agent-scoped secrets override org-scoped ones of the same name when needed.
5. **Verify before deploying**: Test every secret-backed command locally with `valet exec` before deploying (see "Pre-Deploy Verification").

