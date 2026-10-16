# Skills

Two kinds of skill live on Valet:

- **The organization's skills** tell coding agents, you included, how
  the organization works. `governance` is the first of them, and the
  organization can add its own.
- **An agent's skills** are bundles a Valet agent loads at deploy.

## Read the organization's skills

| Task | MCP | CLI |
|---|---|---|
| Read one | `get_skill` with `skill` | `valet skills show <name> --org <org>` |
| Read a skill's supporting file | `get_skill` with `skill` and `path` | `valet skills show <name> --path <file> --org <org>` |
| List them | `list_skills` | `valet skills --org <org>`, then `valet skills info <name>` |

The answer says whether you hold the organization's version or Valet's
default. `valet skills show` prints the `SKILL.md`, or with `--path` the
supporting file, to standard output and its source to standard error.

## Change an organization skill

`publish_skill` creates or replaces one of the organization's skills.
Publishing `governance` or `design-system` changes what every agent in
the organization reads. Do it only when the person asked to change how
the organization works, and show them the content first.

## Give an agent a skill

A skill only one agent needs lives in its source at
`skills/<name>/SKILL.md`. A skill several agents share is attached:

| Source | Means |
|---|---|
| `catalog:<name>` | A skill from Valet's curated catalog |
| `org:<name>` | A skill the organization published; over MCP, a bare name works too |

Add `@vN` to pin a version. With no version, or `@latest`, the deploy
takes the newest.

```
valet skills catalog                                   # browse
valet skills attach catalog:research --agent assistant # MCP: attach_skill
valet skills detach catalog:research --agent assistant # MCP: detach_skill
valet skills --agent assistant                         # what it holds
```

An agent's `valet.yaml` can name catalog skills too, as
`references/agents.md` describes.
