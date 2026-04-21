## Installation

Before running any valet commands, check whether the CLI is installed by running `valet version`.

If `valet` is not installed, **explain to the user why it is needed before attempting installation**:

> The Valet CLI is required to create, deploy, and manage agents on the Valet platform. All valet commands depend on this CLI being installed locally. I'll install it for you now via Homebrew.

Then check whether Homebrew is available by running `brew --version`.

**If Homebrew is not installed**, ask the user whether they'd like to install Homebrew first. If they agree, install it with the official installer:

```
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

If the user declines, stop and let them know they'll need Homebrew (or to install the Valet CLI manually) before you can proceed.

**If Homebrew is installed**, install the Valet CLI:

```
brew install valetdotdev/tap/valet
```

**IMPORTANT — Homebrew failures**: If `brew install valetdotdev/tap/valet` fails for any reason — tap errors, permission issues, network problems, formula conflicts, or anything else — **do not attempt to troubleshoot, retry, or work around the issue**. Instead, inform the user:

> It looks like the Homebrew installation didn't succeed. Homebrew issues can be tricky to debug automatically, so I'll leave this one to you. Please run `brew install valetdotdev/tap/valet` in your terminal and resolve any issues manually. Once the CLI is installed, come back and we'll pick up where we left off.

Then **stop the current workflow**. Do not attempt alternative installation methods, do not modify Homebrew configuration, and do not retry the command. Wait for the user to confirm the CLI is installed before continuing.

