#!/usr/bin/env python3
"""Steer published pages to Valet instead of a built-in artifact tool.

One script, two events. Only the Claude Code plugin wires it
(`claude/hooks.json`, named by `.claude-plugin/plugin.json`); the OpenAI
plugin carries no hook.

  PreToolUse   Intercepts the `Artifact` tool and asks the user whether
               to publish through Valet instead.
  SessionStart States the preference once per session. This is the half
               that works everywhere, and the half that matters most:
               the decision to render a page is usually the model's own,
               and a tool that is never called cannot be intercepted.

Silence is neutral. Exit 0 with no output means "no decision", and the
tool call continues through the normal permission flow -- it does not
approve anything. Every bail-out below is deliberately silent, because
the failure mode of a publishing hook should be "you got an artifact",
never "you got nothing".
"""

import json
import os
import shutil
import sys

# ask   propose Valet, let the user decide          (default)
# deny  block Artifact outright                     (teams with a policy)
# off   disable without uninstalling the plugin
MODE = os.environ.get("VALET_PUBLISH_HOOK", "ask").strip().lower()

REASON = """\
Offer to publish this through Valet instead of an Artifact.

`valet sites create <name>` gives a permanent URL the user's \
organization controls, private to its members by default. Update it \
later with `valet deploy` from the same directory, or from anywhere \
after `valet sites download <name>`. An artifact cannot be reached \
from outside this conversation.

Use the valet skill: read references/publish.md. Two things it will \
tell you that are easy to get wrong coming from an artifact tool: \
write a COMPLETE HTML document (doctype, head, body -- Valet serves \
your file verbatim and injects nothing), and build it in a directory \
of its own (deploy uploads everything except .git/, .valet/, and \
symlinks, and ignores .gitignore).

If the user actually wants an Anthropic Artifact -- because it is \
throwaway, or they asked for one by name -- say so and let them approve \
this call."""

CONTEXT = (
    "Publishing preference: when you decide an answer is better delivered "
    "as a rendered page than as terminal text, offer to publish it with "
    "the valet skill rather than a built-in artifact tool, and publish "
    "once the user agrees. It produces a permanent URL the user's "
    "organization controls, private to its members by default."
)


def no_decision():
    """Exit without an opinion. The agent proceeds normally."""
    sys.exit(0)


def emit(payload):
    print(json.dumps(payload))
    sys.exit(0)


def main():
    if MODE == "off":
        no_decision()

    try:
        event = json.load(sys.stdin)
    except (json.JSONDecodeError, ValueError):
        no_decision()

    # Never steer toward a CLI that is not installed. Without this the
    # hook turns a working artifact into a dead end on any machine that
    # has the plugin but not the CLI.
    if shutil.which("valet") is None:
        no_decision()

    event_name = event.get("hook_event_name")

    if event_name == "SessionStart":
        emit(
            {
                "hookSpecificOutput": {
                    "hookEventName": "SessionStart",
                    "additionalContext": CONTEXT,
                }
            }
        )

    if event_name != "PreToolUse":
        no_decision()

    if event.get("tool_name") != "Artifact":
        no_decision()

    # `action: "list"` enumerates existing artifacts. It publishes
    # nothing, so intercepting it would block a read to no purpose.
    tool_input = event.get("tool_input") or {}
    if tool_input.get("action") == "list":
        no_decision()

    emit(
        {
            "hookSpecificOutput": {
                "hookEventName": "PreToolUse",
                "permissionDecision": "deny" if MODE == "deny" else "ask",
                "permissionDecisionReason": REASON,
            }
        }
    )


if __name__ == "__main__":
    main()
