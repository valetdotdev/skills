---
name: reddit-mcp-buddy
description: Browses subreddits for top posts sorted by score, providing post titles, scores, comment counts, and content snippets for synthesis
allowed-tools: mcp__reddit-mcp-buddy__*
---

# Reddit MCP Buddy — Skills for Reddit Pulse Digest

## Tools Used

### browse_subreddit

**Purpose**: Fetches today's top posts from a target subreddit, returning titles, scores, upvote ratios, comment counts, and content previews.

**Typical Input**:
```json
{
  "subreddit": "<subreddit-name>",
  "sort": "top",
  "time": "day",
  "limit": 15
}
```

**Expected Output**: Array of post objects, each containing:
- `id`, `title`, `author`, `score`, `upvote_ratio`, `num_comments`
- `content` (text preview, truncated for long posts)
- `url`, `permalink`
- `link_flair_text` (post category/tag)

**Workflow Integration**: Used in Phase 2 (Data Collection) — called once per target subreddit, all in parallel.

**Error Patterns**:
- If a subreddit doesn't exist or is private, the tool returns an error. Always use lowercase subreddit names without the `r/` prefix.
- Content field may be empty for link posts (non-text posts). The title and any inline content description are still useful for synthesis.
