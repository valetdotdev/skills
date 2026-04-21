## Writing AGENTS.md

`AGENTS.md` is the **last file written** before the session ends. It lives in the root of the agent project directory and serves as a human- and LLM-readable setup guide for anyone who needs to deploy this agent in the future.

**NEVER include secret values, API keys, or tokens in AGENTS.md.** Only describe what is needed and why.

### Template

```markdown
This folder contains the source for a Skilled Agent originally built for the Valet runtime. Changes should follow the Skilled Agent open standard.

## Setup

### Connectors

- **<connector-name>**: <plain-English description of what it provides and why the agent needs it>
  [Repeat for each connector]

### Channels

- **<channel-name>** (<channel-type>): <what triggers this channel and what the agent does when it fires>
  [Repeat for each channel]

### Secrets

- **<SECRET_NAME>**: <what this secret is for, where to obtain it, and any scopes or permissions required>
  [Repeat for each secret]

### External Setup

[If the agent requires any configuration outside of Valet — third-party service setup, OAuth apps, cloud console steps, DNS records, etc. — describe each step here in plain English. Be specific enough that a person unfamiliar with the project can follow along.]
```

### Rules

- Write in plain English — describe requirements as nouns with reasons, not CLI commands
- Be specific about secrets — include required scopes/permissions and where to obtain them
- Include external setup steps (OAuth apps, cloud consoles, webhook registrations, etc.)
- Omit sections that don't apply. Write this file last.

