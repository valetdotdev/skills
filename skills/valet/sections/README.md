# Valet skill sections

`SKILL.md` in the parent directory is the single file the skill
runtime consumes. It's generated — don't edit it directly.

To change the skill, edit the matching file in this directory and
run `./build.sh` in the parent directory. The build script
concatenates every `*.md` file in this directory in lexicographic
order and overwrites `SKILL.md`.

## File naming

Each section file is numbered so the lexicographic sort matches the
order the content should appear in `SKILL.md`:

- `00-frontmatter.md` — YAML frontmatter + opening paragraph
- `01-installation.md` through `24-execution-guidelines.md` — one
  top-level `##` section per file, numbered in document order

When adding a new section, pick a number that places it where it
belongs and leave a gap (e.g. `08b-webhook-scope.md` between `08`
and `09`) or renumber. The numbers are structural, not semantic —
renumbering is fine as long as `./build.sh --check` still passes.

## Workflow

```bash
# Edit a section
$EDITOR sections/09-channels.md

# Regenerate SKILL.md from sections
./build.sh

# CI check: fails if SKILL.md drifted from sections/
./build.sh --check
```

## Why split

`SKILL.md` is ~56 KB. The Claude streaming API truncates tool-call
input arguments larger than ~30 KB, which makes the full file
unsafe to pass through `Write` or the GitHub Contents API. Splitting
into <5 KB chunks lets the doc-sync bot (and humans) edit any
section through normal tools.
