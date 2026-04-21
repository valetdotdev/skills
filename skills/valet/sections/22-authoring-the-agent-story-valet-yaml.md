## Authoring the agent story (valet.yaml)

Agents published to the Valet catalog ship with a `valet.yaml`
manifest. The Valet dashboard reads it to render the friendly
`agents/new` configuration wizard. Standalone agents (deployed only
via `valet agents create` without catalog publication) do not need
one.

When authoring `valet.yaml`, fill in four things:

1. **Top-level metadata** — `name`, `display_name`, `description`, `category`.
2. **`story` block** — slot-driven narrative copy.
3. **`connectors[]` and `channels[]`** — dependencies with per-agent UI
   overrides.
4. **Catalog references (`catalog:`) must match existing Valet catalog
   entries** — otherwise the wizard can't resolve icons or brand copy.

### The `story` block

The story is a 3-step narrative that answers: *what's the trigger*,
*what does the agent do*, *what is the outcome*. Every field has a
hard length cap enforced by `valet manifest validate`. Do not exceed
it.

```yaml
story:
  hero: "Let's get AskADev answering questions for your team."
  subheadline: "Watches one Slack channel. Searches GitHub. Replies in-thread."
  steps:
    - role: trigger
      title: "Your team asks a question in Slack."
      body: "Someone posts 'where do we handle the Stripe webhook retry logic?'"
      catalog: slack-webhook
    - role: action
      title: "AskADev reads your code."
      body: "Searches the repo. Finds the handler and surrounding comments."
      catalog: github
    - role: outcome
      title: "And answers — with sources."
      body: "Replies in-thread, linking to the exact file, line, and commit."
      catalog: slack-mcp
```

**Role contract:** exactly three steps in order: `trigger`, `action`,
`outcome`. Nothing else.

**`catalog:` on a step:** optional. When set, it must match a
`catalog:` declared on one of this manifest's `connectors` or
`channels`. The wizard renders that service's icon as the step glyph.
Leave empty to render the agent monogram (useful for the middle
"the agent thinks" step that has no external service).

### Drafting copy from SOUL.md

Do not invent copy from scratch — derive it from the agent's
SOUL.md. The Purpose and Workflow sections already describe the
agent's trigger, action, and outcome in prose; your job is to
distill that prose into the slot-driven format.

Work in this order (top-down matches what the user reads in the
wizard):

1. **Extract the three beats.** Open SOUL.md. The `Purpose` sentence
   names the trigger, the action, and the outcome — usually in that
   order. If Purpose is vague, fall back to the Workflow phases:
   Phase 1 → trigger, Phase 2 → action, Phase 3 → outcome.
2. **Find the hook.** What makes this agent specific? A concrete
   time (*"8am hits"*), a concrete place (*"posts to #ai-news"*), or
   a concrete constraint (*"only after you approve"*). Write the hook
   down — it anchors the hero and subheadline and often becomes the
   outcome body.
3. **Draft the trigger, action, and outcome steps first.** Concrete
   details are easier to write than the hero. Use the tone rules
   below. Aim for the sweet-spot lengths in the next table.
4. **Write the outcome `done_note`s next.** These are short — one
   line each. They fall out of step 3.
5. **Write the subheadline.** One concrete sentence that names the
   services and the reward. The subheadline is the "elevator pitch"
   beneath the hero.
6. **Write the hero last.** The hero is the most compressed, most
   brand-defining line. Writing it after the steps gives you
   material to compress from.
7. **Run `valet manifest validate`.** Non-negotiable. The dashboard
   rejects invalid manifests at render time.
8. **Read it aloud.** Every line should sound like something a human
   could read out loud without flinching. If it sounds like a
   marketing page, rewrite.

### Length targets (what looks good, not just what validates)

The caps are hard limits enforced by `valet manifest validate`. The
sweet-spot ranges are what actually renders well in the wizard — use
them as targets, not the caps.

| Field | Sweet spot | Hard cap | Too short | Too long |
|-------|-----------|----------|-----------|----------|
| `hero` | 45–75 chars | 80 | Hollow, generic | Wraps awkwardly on narrow viewports |
| `subheadline` | 110–170 chars | 200 | Reads like a slogan, not an explainer | Crammed, unreadable at a glance |
| step `title` | 25–50 chars | 60 | Lacks grip | Runs onto two lines, breaks the rhythm |
| step `body` | 80–130 chars | 140 | Feels like filler | Looks dense under the title |
| ui `headline` | 30–55 chars | — | Generic ("Connect GitHub") | Repeats the step title |
| ui `blurb` | 80–140 chars | — | No agent-specific angle | Reads like the catalog description |
| ui `done_note` | 20–45 chars | — | No concrete "it works" signal | Belongs in a status page |

Length cap > sweet spot: use the sweet spot. Only push toward the
cap when the extra characters carry real information (a
channel name, a specific time, a named artifact). Never pad.

### Voice and style

**Always:**

- Write in present tense, active voice. *"Posts the briefing"*, not
  *"Will post the briefing"* or *"The briefing is posted"*.
- Name the agent at least once in the hero. The user is meeting it
  for the first time.
- Name concrete things: services (*Slack*, *GitHub*), artifacts
  (*#ai-news*, *pull request*), times (*8am*, *every Friday*). Never
  *"messaging platforms"* or *"on a schedule"*.
- Use em dashes (*—*) for rhythm when a thought has two beats. The
  wizard font renders them well.
- Address the reader as *you*. *"Your team asks"*, *"You paste a
  message"*. Never *"the user"*.

**Never:**

- Use buzzwords: *seamless*, *leverages*, *empowers*, *intelligent*,
  *cutting-edge*, *streamlines*, *unlocks*, *powerful*, *robust*.
- Use passive voice for the action step. *"AskADev reads your
  code"* — not *"Your code is read by AskADev"*.
- Describe mechanism when a result would do. *"Authenticates via
  OAuth"* is mechanism; *"Uses OAuth — no API token needed"* is a
  result. *"Parses the payload"* is mechanism; *"Reads the PR"* is
  a result.
- Write copy that could belong to a different agent. If you can
  swap *AskADev* for *Code Reviewer* without the sentence breaking,
  the copy is generic — add the hook.
- Use emoji unless the agent's personality demands it and you've
  stress-tested it across viewports.

### Tone rules (per field)

These override any other guidance. They're optimized for the way
the wizard renders each field.

- **Hero** is imperative or present-indicative, names the agent.
  Write *"Let's get AskADev answering questions for your team."* —
  not *"AskADev is an AI agent that answers questions"*.
- **Subheadline** is one concrete sentence naming the services and
  the reward. No lists, no semicolons.
- **Trigger title** starts with the user or the channel event:
  *"Your team asks…"*, *"A PR is opened."*, *"8am hits."*
- **Action title** uses active voice, names the agent:
  *"AskADev reads your code."*
- **Outcome title** names the concrete artifact the user sees:
  *"Replies in-thread, linking to the file."*

### Good vs. bad examples

| Field | ❌ Bad | ✅ Good | Why |
|-------|-------|--------|-----|
| hero | *"AskADev is an AI-powered Slack assistant that answers code questions."* | *"A Slack bot that reads your code before it answers."* | Bad leads with category + buzzword. Good leads with behavior and names the hook ("before it answers"). |
| subheadline | *"Uses GitHub MCP and Slack MCP to provide intelligent responses to developer questions."* | *"Ask a question about a GitHub repo in Slack. AskADev researches the actual code and commit history, then replies in-thread."* | Bad names the plumbing. Good names the action and the reward. |
| trigger title | *"Webhook event received"* | *"A PR is opened."* | Bad names the mechanism. Good names what happened in the user's world. |
| action title | *"Diff analysis"* | *"Code Reviewer reads the diff."* | Bad is a noun phrase. Good is a sentence with a subject and verb. |
| outcome title | *"Review submitted"* | *"Inline comments — or an approve."* | Bad is passive mechanism. Good names the two concrete outputs. |
| step body | *"The agent processes the incoming webhook payload and performs configured actions."* | *"Checks correctness, security, maintainability, and test coverage. Reads full files when context matters."* | Bad is generic. Good enumerates specifics. |
| ui blurb | *"Connect your GitHub account to give the agent access to your repositories."* | *"AskADev reads your code when it answers — like a new hire would."* | Bad could belong to any GitHub connector. Good is about *this* agent's use of GitHub. |
| ui done_note | *"Successfully connected"* | *"Listening in #engineering"* | Bad is a status. Good is the concrete outcome the user wanted. |

### Per-service `ui:` block

Each `connectors[]` and `channels[]` entry can carry a `ui:` block
that overrides generic catalog copy with agent-specific copy:

```yaml
connectors:
  - catalog: github
    description: "GitHub MCP server for browsing repos and reading files"
    ui:
      headline: "Point AskADev at your repo."
      blurb: "AskADev reads your code when it answers — like a new hire would."
      done_note: "Connected to your repo"

channels:
  - catalog: slack-webhook
    description: "Receives Slack messages and app mentions"
    ui:
      headline: "Let AskADev hear your team in Slack."
      blurb: "We'll add AskADev as a normal Slack app. You pick the channel."
      done_note: "Listening in the channel you invite it to"
```

- `headline` replaces the step's default headline. Write it as a
  verb + service imperative: *"Let AskADev hear your team in Slack."*
- `blurb` is a one-paragraph summary of *this specific agent's* use
  of the service. Not a generic Slack/GitHub explainer — that's what
  the catalog `description` is for.
- `done_note` is the one-line summary shown on the deploy screen
  once the service is connected. Write what the user will see after
  deploy: *"Listening in #engineering"*, *"Connected to valetdotdev/ark"*.

**What NOT to put in `ui:`:** permissions, restrictions, safety
chips, "why", verb, minutes. Those are catalog-owned fields filled
in by the Valet team — do not duplicate them per-agent.

### Keep `valet.yaml` and `README.md` in sync

The agent's `README.md` tagline (the one-liner under the project
title) and the `valet.yaml` `subheadline` are the same piece of
marketing copy, surfaced on two different surfaces — GitHub and the
dashboard wizard. Keep them **word-for-word identical**. When you
update one, update the other in the same commit.

Do the same for the `README.md` project title and the
`display_name`: they should match exactly. Users who click through
from GitHub to the wizard should see the same name and the same
pitch in both places — drift is the surest way to make an agent
look unmaintained.

```markdown
<!-- README.md -->
# Deep Researcher

Every morning, Deep Researcher scans the AI news landscape,
summarizes the 5 most important stories, and posts the briefing
to #ai-news.
```

```yaml
# valet.yaml
display_name: Deep Researcher
story:
  subheadline: "Every morning, Deep Researcher scans the AI news landscape, summarizes the 5 most important stories, and posts the briefing to #ai-news."
```

### Validating

After writing or editing a `valet.yaml`, always validate:

```bash
valet manifest validate
```

Or with an explicit path:

```bash
valet manifest validate path/to/valet.yaml
```

`valet manifest validate` enforces length caps, the 3-step contract,
and the step-catalog reference rule. If it fails, fix the reported
errors before deploying — the dashboard wizard will reject invalid
manifests.

