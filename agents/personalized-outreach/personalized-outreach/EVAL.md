# Evaluation: Personalized Outreach

## Overview

A successful run sends personalized emails to all specified recipients using an approved template, with correct names and any per-recipient modifications applied.

## Success Criteria

### Required Outcomes

- [ ] Inbox is verified before sending
- [ ] Draft email is presented to user before any sends
- [ ] User explicitly approves the template before first send
- [ ] Each recipient receives an individually addressed email
- [ ] Recipient first names are correctly extracted and used in greetings
- [ ] Email addresses match exactly what the user provided
- [ ] Subject line is consistent across all sends (unless user changes it)
- [ ] Per-recipient modifications are applied only to the specified recipient

### Quality Criteria

- [ ] Template changes mid-batch are applied to all subsequent sends (not retroactively)
- [ ] Agent does not re-ask for the template when the user provides a new recipient
- [ ] Agent handles rapid-fire "now do X" requests without unnecessary confirmation
- [ ] Copy is clean — no extra formatting, signatures, or boilerplate added

## Evaluation Method

### Inputs

- Sending inbox ID (e.g., `sender@example.com`)
- Email template text (subject + body)
- List of recipients: name + email address
- Optional per-recipient modifications

### Expected Outputs

- One `send_message` call per recipient
- Each email personalized with the recipient's first name
- Confirmation message after each send

### Diagnostic Checklist

| Check | Pass | Fail |
|-------|------|------|
| Template reviewed before sending | User sees draft and says "sure" / "send" / approves | Email sent without showing draft |
| Name personalization | "Hey Alex!" for Alex Johnson | "Hey!" or "Hey Alex Johnson!" |
| Per-recipient tweak | Modification appears only in that recipient's email | Modification bleeds into other emails or is missing |
| Template update mid-batch | All subsequent emails use updated copy | Some emails use old copy after update |
| Email address accuracy | Exact match to user-provided address | Typo, domain change, or guess |

## Failure Modes

- **Wrong name extraction**: If the user provides "Sam Rivera" and email only, agent might not extract "Sam" correctly. Mitigation: parse the name before the email, use the first word as the greeting name.
- **Template drift**: After many sends, agent might forget the current template state. Mitigation: maintain the latest approved template and apply changes incrementally.
- **Sending without approval**: Agent might skip review for subsequent recipients. Mitigation: only the first email needs explicit approval; subsequent sends use the locked template.
- **Per-recipient tweak persisting**: A one-off modification (e.g., "if you're in SF") might accidentally carry to the next recipient. Mitigation: explicitly reset to base template after each per-recipient tweak unless user says otherwise.
