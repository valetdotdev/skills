## Writing valet.yaml

`valet.yaml` is the agent manifest. It enables 1-click deployment through the dashboard setup flow. **Do not generate `valet.yaml` automatically.** Only write it when the user explicitly asks for it — trigger phrases include "yaml", "deploy button", "dashboard setup", "1-click deploy", or "setup on web".

### Catalog items only

The manifest only supports connectors and channels that exist in the Valet catalog. Custom connectors and channels cannot be represented in `valet.yaml` — the dashboard setup flow looks up each `catalog` value and fails if the entry doesn't exist.

**Before writing valet.yaml**, run `valet connectors catalog` and `valet channels catalog` to check which of the agent's connectors and channels are in the catalog.

- **Mix of catalog and custom resources**: Include only the catalog items in `valet.yaml`. Document the custom resources in `AGENTS.md` with CLI setup instructions. Users will configure catalog resources through the dashboard flow and create custom resources manually with the CLI afterward.
- **Only custom resources**: Still write `valet.yaml` with the four required top-level fields and omit the `connectors` and `channels` arrays. The dashboard uses this metadata to display the agent's name, description, and category.
- **Missing catalog entries**: If a connector or channel should be in the catalog but isn't, direct the user to email support@valet.dev to request it be added.

### Template

```yaml
name: <agent-name>
display_name: <Human-Readable Name>
description: >-
  <What the agent does — shown in the dashboard
  during setup>
category: <category>
connectors:
  - catalog: <catalog-entry-name>
    description: >-
      <Agent-specific context for this connector>
    slot_descriptions:
      <SLOT_NAME>: <Label shown in the setup flow>
channels:
  - catalog: <catalog-entry-name>
    description: >-
      <Agent-specific context for this channel>
    events:
      - <event_type>
    slot_descriptions:
      <SLOT_NAME>: <Label shown in the setup flow>
```

### Rules

- **`name`** must match the agent name used in `valet agents create`.
- **`catalog` values must come from the catalog.** Run `valet connectors catalog` and `valet channels catalog` to verify. Only include connectors/channels that exist in the catalog — omit custom ones from the yaml and document them in `AGENTS.md` instead.
- **`slot_descriptions` keys must match slot names from the catalog entry.** Run `valet connectors catalog get <name>` or `valet channels catalog get <name>` to discover slot names.
- **`description`** should be a complete sentence suitable for display in the dashboard.
- **`category`** should be a descriptive term (e.g. `development`, `ops`, `utilities`, `developer-tools`, `testing`).
- Omit `connectors` and `channels` arrays entirely if the agent has none.
- Omit optional fields (`description`, `events`, `slot_descriptions`) when the catalog defaults are sufficient.

### Validation checklist

After writing the file, verify:
1. All four top-level fields are present and non-empty
2. Every `catalog` value was confirmed to exist by running `valet connectors catalog` / `valet channels catalog`
3. Every `slot_descriptions` key matches a slot defined in the catalog entry
4. Custom (non-catalog) connectors/channels are omitted from the yaml and documented in `AGENTS.md`

