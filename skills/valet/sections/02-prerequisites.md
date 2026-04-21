## Prerequisites

After the CLI is installed, the user **must be authenticated** before any other command will work. Explain this to the user:

> Before we can create or manage agents, you need to be logged in to your Valet account. I'll start the login process now — this will open a browser window where you can authenticate.

Then run:

```
valet auth login
```

After login, verify the session is active with `valet auth whoami`. If authentication fails, let the user know and do not proceed with any other valet commands until they are successfully logged in.

