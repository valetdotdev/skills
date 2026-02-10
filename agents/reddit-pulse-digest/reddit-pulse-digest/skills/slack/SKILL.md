---
name: slack
description: Finds the target Slack channel by name and posts the formatted Reddit Pulse digest message
allowed-tools: mcp__slack__*
---

# Slack — Skills for Reddit Pulse Digest

## Tools Used

### slack_list_channels

**Purpose**: Lists all public Slack channels in the workspace to find the channel ID for a given channel name.

**Typical Input**:
```json
{
  "limit": 200
}
```

**Expected Output**: Array of channel objects with `id`, `name`, `is_member`, `num_members`, etc.

**Workflow Integration**: Used in Phase 2 (Data Collection) — called in parallel with Reddit browsing to resolve `#<channel-name>` to a channel ID before posting.

**Error Patterns**:
- If the channel doesn't appear in results, it may be private or the bot may not have access. Report this clearly to the user.
- Pagination: if the workspace has >200 channels, a `cursor` is returned for the next page. For most workspaces, 200 is sufficient.

### slack_post_message

**Purpose**: Posts the final formatted digest message to the target Slack channel.

**Typical Input**:
```json
{
  "channel_id": "<channel-id>",
  "text": "<formatted-digest-message>"
}
```

**Expected Output**: Confirmation with `ok: true`, the posted message timestamp, and channel ID.

**Workflow Integration**: Used in Phase 4 (Compose & Post) — called exactly once with the fully formatted digest.

**Error Patterns**:
- `channel_not_found`: The channel ID is invalid. Always resolve via `slack_list_channels` first.
- `not_in_channel`: The bot isn't a member of the channel. The user needs to invite the bot.
- Message too long: Slack has a ~4000 character limit. Keep bullets concise to stay within bounds.
- Use Slack mrkdwn format: `*bold*`, `_italic_`, `:emoji_name:`. Standard markdown (`**bold**`) won't render.
