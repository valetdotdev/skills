## Writing Channel Files

Channel files tell the agent what to do when a message arrives. They are instructions TO the agent, written as direct imperatives.

### Webhook payload location (critical)

The JSON webhook payload is appended inline after the channel file in the user message. Every channel file **must** start with:

```
The JSON webhook payload is appended directly after these instructions
in the user message. Parse it inline — do not fetch, list, or search
for the payload elsewhere. Do NOT use tools to read the payload.
```

Without this, agents waste turns searching for the payload with tool calls.

### Structure

1. **Payload location** — the instruction above
2. **What happened** — describe the event
3. **What to extract** — which payload fields identify the transaction (IDs, refs)
4. **Scope boundary** — all actions must be scoped to those identifiers
5. **What to do** — step-by-step processing instructions

### Example

```markdown
# New Email Received

The JSON webhook payload is appended directly after these instructions
in the user message. Parse it inline — do not fetch, list, or search
for the payload elsewhere. Do NOT use tools to read the payload.

You received a webhook for a single new email.

## Scope

Extract the `thread_id` from the payload. All actions are scoped to
this thread. Do not list, read, or act on any other threads.

## Steps

1. Extract `thread_id`, `from_`, `subject`, and `text` from the payload.
2. [... task-specific steps ...]
```

### Reinforcing scope in SOUL.md

For webhook-driven agents, add to SOUL.md:

```markdown
## Webhook Scope Rule

When you receive a webhook, your scope of work is defined by the
identifiers in the payload. Use any tools to fully understand and act
on that specific content, but do not act on unrelated content.
```

