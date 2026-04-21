## Common Workflows

### Full agent setup (org-first, preferred)

Follow Resource Creation Principles — set up org-scoped resources first, then attach to the agent.

1. Direct the user to set org-scoped secrets in their terminal
2. Add connectors (catalog first, then custom if needed) at the org level
3. Add channels (catalog first for webhooks) at the org level
4. Create the agent and attach org resources:
   ```
   valet secrets set GITHUB_TOKEN=<their-token> --org acme
   ```

2. Add connectors from the catalog at the org level:
   ```
   valet connectors catalog
   valet connectors create github --org acme
   ```

3. If no catalog entry exists, create a custom connector at the org level:
   ```
   valet connectors create mcp-server my-tool --org acme \
     --transport stdio \
     --command npx \
     --args -y,@example/mcp-server \
     --env API_KEY={{API_KEY}}
   ```

4. Add channels from the catalog at the org level (for webhooks):
   ```
   valet channels create github-webhook --org acme
   ```

5. Create the agent and attach org resources:
   ```
   cd my-agent-project
   valet agents create my-agent --org acme \
     --attach-connector github \
     --attach-channel github-webhook
   ```
   Or attach after creation:
   ```
   valet connectors attach github --agent my-agent
   valet channels attach github-webhook --agent my-agent --events pull_request
   ```

6. **Verify each connector command locally with `valet exec`** before proceeding:
   ```
   valet exec GITHUB_TOKEN -- \
     npx -y @modelcontextprotocol/server-github
   ```
   If this fails (bad token, missing dependency, wrong command), fix it now.

7. Create the channel file at `channels/<channel-name>.md` (see "Writing Channel Files").

8. Deploy to pick up the channel file:
   ```
   valet agents deploy
   ```

9. Validate end-to-end with an interactive test loop (see below).

### One-off agent setup (agent-scoped)

For standalone agents that don't need to share resources:

1. Create the agent:
   ```
   cd my-agent-project
   valet agents create my-agent
   ```

2. Set agent-scoped secrets and create agent-scoped connectors:
   ```
   valet secrets set API_KEY=<value> --agent my-agent
   valet connectors create mcp-server my-tool --agent my-agent \
     --transport stdio --command npx \
     --args -y,@example/server \
     --env API_KEY={{API_KEY}}
   ```

3. Create channels, channel files, deploy, and test as above.

### Interactive test loop (mandatory for first-time channel setup)

1. Start streaming logs in the background:
   ```
   valet logs > /tmp/valet-test-<agent-name>.log 2>&1
   ```
   (Run via Bash with `run_in_background: true`.)

2. Ask the user to trigger the channel (send the email, push to GitHub, etc.). Be specific about what they need to do.

3. Wait for the user to confirm the trigger completed.

4. Stop the background log stream and read the log file.

5. Review the logs:
   - **Healthy**: Few turns, `mcp_call_tool_start`/`mcp_call_tool_done` pairs, `dispatch_complete`.
   - **Unhealthy**: Many turns with only built-in tools (agent looping), no `mcp_call_tool_start` (can't find tools), no `dispatch_complete` (timeout/stuck).

6. If problems, fix SOUL.md or channel prompt, redeploy, and repeat. Each change triggers a full VM reboot — wait for it to complete and stream fresh logs before evaluating.

### Teardown (order matters)

Detach org resources first, then destroy agent-scoped resources, then the agent:
```
# Detach org resources (they remain available for other agents)
valet connectors detach github --agent my-agent
valet channels detach github-webhook --agent my-agent

# Destroy agent-scoped resources
valet channels destroy <agent-channel>
valet connectors destroy <agent-connector>

# Destroy the agent
valet agents destroy <agent-name>
```

### Debugging

```
valet agents info my-agent                   # Check state, channels, connectors
valet agents info my-agent --org my-org      # Specify org when looking up by name
valet logs --agent my-agent                  # Stream live logs (last 100 lines, then live)
valet logs --agent my-agent -n 0             # Live logs only, skip history
valet ps restart -a my-agent                 # Restart without redeploying
valet ps restart -a my-agent --org my-org    # Restart with explicit org
```

