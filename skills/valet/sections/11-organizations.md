## Organizations

Organizations own agents, connectors, channels, and secrets. All agents belong to an org.

```
valet orgs create <name>           # Create a new org
valet orgs                         # List your orgs
valet orgs info <name>             # Show org details
valet orgs destroy <name>          # Delete an org
valet orgs members <name>          # List members
valet orgs invite <name> <email>   # Invite a member
valet orgs join <code>             # Accept an invitation
valet orgs leave <name>            # Leave an org
valet orgs remove <name> <email>   # Remove a member
valet orgs revoke <name> <email>   # Cancel an invitation
```

**Org tips**: The default org is set automatically when you create or join an org — you don't need `--org` on every command.

