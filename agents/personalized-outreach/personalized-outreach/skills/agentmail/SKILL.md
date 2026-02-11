---
name: agentmail
description: Send and manage emails via the agentmail service for personalized outreach
allowed-tools: mcp__agentmail__*
---

# Agentmail — Skills for Personalized Outreach

## Tools Used

### list_inboxes

**Purpose**: Verify the sending inbox exists and retrieve its ID before sending emails.

**Typical Input**:
```json
{}
```

**Expected Output**: List of inbox objects with `inboxId`, `displayName`, and metadata.

**Workflow Integration**: Used in Phase 1 of SOUL.md — confirms the inbox ID is valid before composing emails.

**Error Patterns**: None observed. If inbox doesn't exist, agent should inform user rather than attempting to create one.

### send_message

**Purpose**: Send an individually personalized email to a single recipient.

**Typical Input**:
```json
{
  "inboxId": "<sender-inbox-id>",
  "to": ["<recipient-email>"],
  "subject": "<email-subject>",
  "text": "<personalized-email-body>"
}
```

**Expected Output**: Object with `messageId` and `threadId` confirming successful send.

**Workflow Integration**: Used in Phase 3 of SOUL.md — called once per recipient with personalized greeting and any per-recipient modifications applied.

**Error Patterns**: None observed. Potential issues: invalid inbox ID, malformed email address. Agent should surface errors to user rather than retrying silently.
