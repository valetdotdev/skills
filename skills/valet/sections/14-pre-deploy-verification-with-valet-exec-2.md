## Pre-Deploy Verification with valet exec

**Before deploying an agent, locally test every command that requires secrets using `valet exec`.** This catches authentication failures, wrong secret names, malformed URLs, and missing dependencies before they cause the agent to crash in production.

### What to test

Any connector command that references secrets in its `--env` flags should be verified locally. Reproduce the exact command the connector will run, wrapping it in `valet exec`:

```
# If the connector is defined as:
valet connectors create github-server \
  --transport stdio \
  --command npx \
  --args -y,@modelcontextprotocol/server-github \
  --env GITHUB_PERSONAL_ACCESS_TOKEN={{GITHUB_TOKEN}}

# Test the underlying command locally:
valet exec -a my-agent GITHUB_TOKEN -- \
  npx -y @modelcontextprotocol/server-github
```

For remote connectors (SSE/streamable-http) with secret-backed headers or URLs, test with curl:

```
# If the connector uses --header Authorization={{API_TOKEN}} --url https://mcp.example.com/mcp
# Test the endpoint is reachable and the token works:
valet exec -a my-agent API_TOKEN -- \
  curl -s -o /dev/null -w "%{http_code}" -H "Authorization: {{API_TOKEN}}" https://mcp.example.com/mcp
```

Also test any webhook endpoint you plan to call with secrets in the URL:

```
valet exec -a my-agent WEBHOOK_SECRET -- \
  curl -X POST https://hooks.example.com/{{WEBHOOK_SECRET}}/notify -d '{"test": true}'
```

### Verification checklist

Before running `valet agents deploy`, confirm:

1. All secrets are set: `valet secrets --agent <name>` and `valet secrets --org <org>` list every name referenced by connectors
2. Each connector's command succeeds locally via `valet exec`
3. Any secret-backed URLs resolve and authenticate correctly

Do not deploy until all `valet exec` tests pass.

