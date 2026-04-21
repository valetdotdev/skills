## Execution Guidelines

- Always run commands via the Bash tool.
- **Be explanatory**: Before running any valet command, briefly tell the user *what* you're about to do and *why*. Don't silently execute commands — the user should always understand the purpose of each step.
- **Installation guardrails**: Follow the Installation section strictly. If the CLI is not installed, explain why it's needed and attempt installation via Homebrew. If Homebrew fails, **stop immediately** — do not retry, work around, or troubleshoot brew issues. Let the user resolve it manually.
- **Authentication first**: Always verify the user is logged in (`valet auth whoami`) before running any non-auth valet commands. If not logged in, explain that authentication is required and run `valet auth login`. Do not proceed until authentication succeeds.
- **Use `valet help` proactively**: When you encounter a command, flag, or feature you're unsure about, run `valet help <command>` before guessing. The CLI help is the authoritative source.
- **Never ask for secret values inside the LLM session.** Direct the user to run `valet secrets set NAME=VALUE` in their own terminal and wait for confirmation.
- **Always verify privileged commands with `valet exec` before deploying.** After the user sets secrets and you create connectors, test the underlying command locally using `valet exec <names> -- <command>`. This is the only way to run commands with Valet-managed secrets locally. Do not deploy until the command succeeds. Use `{{SECRET_NAME}}` template syntax to embed secrets in URLs, headers, or env values.
- When the user asks to create an agent from scratch, follow "Designing a New Agent".
- When the user asks to capture the current session as an agent, follow "Learning from the Current Session".
- When writing SOUL.md, follow the template and synthesis rules. Never leave Purpose or Workflow empty.
- When authoring a `valet.yaml` for a catalog-published agent, follow "Authoring the agent story". Run `valet manifest validate` after every edit — length caps and the 3-step role order are non-negotiable.
- For destructive commands (`destroy`, `remove`, `revoke`), always confirm with the user first.
- When creating webhook channels, report the webhook URL and signing secret. When writing channel files, include the payload location instruction.
- After deploying an agent with channels for the first time, run the interactive test loop.
- If a command fails, read the error and troubleshoot. Common issues: not logged in, no `SOUL.md`, not linked, agent crashed. For Homebrew errors, **stop and let the user resolve manually**.

