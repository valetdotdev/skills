#!/usr/bin/env bash
# Regenerates skills/valet/SKILL.md by concatenating every file in
# sections/ in lexicographic order. SKILL.md is a build artifact —
# edit the matching section file instead, then re-run this script.
#
# Usage:
#   ./build.sh           # Rewrite SKILL.md from sections/
#   ./build.sh --check   # Exit non-zero if SKILL.md is stale
set -euo pipefail

cd "$(dirname "$0")"

if [[ ! -d sections ]]; then
    echo "error: sections/ directory not found next to build.sh" >&2
    exit 1
fi

shopt -s nullglob
# Only concatenate numbered section files. Non-numbered files (e.g.
# README.md for section maintainers) live alongside the sections but
# are not part of the skill.
files=(sections/[0-9]*.md)
if (( ${#files[@]} == 0 )); then
    echo "error: no section files matching sections/[0-9]*.md" >&2
    exit 1
fi

tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
cat "${files[@]}" > "$tmp"

if [[ "${1:-}" == "--check" ]]; then
    if ! diff -q SKILL.md "$tmp" >/dev/null; then
        echo "error: SKILL.md is out of sync with sections/. Run ./build.sh and commit." >&2
        diff -u SKILL.md "$tmp" | head -40 >&2 || true
        exit 1
    fi
    echo "✅ SKILL.md is in sync with sections/"
    exit 0
fi

mv "$tmp" SKILL.md
trap - EXIT
echo "✅ Regenerated $(wc -l < SKILL.md) lines of SKILL.md from ${#files[@]} sections"
