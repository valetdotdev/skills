#!/usr/bin/env python3
"""Parse a Claude Code JSONL session log and extract structured data for agent generation.

Usage: python3 parse_session.py <session-file.jsonl>

Outputs JSON with: summary, user_prompts, mcp_tools, invoked_skills, builtin_tools, corrections.
Stops parsing at the /learn invocation to exclude the learning session itself.
"""

import json
import sys

session_file = sys.argv[1]

user_prompts = []
mcp_tools = {}        # {server: {tool: [input_samples]}}
invoked_skills = set()
builtin_tools = set()
corrections = []
summary = ""

with open(session_file) as f:
    for line in f:
        line = line.strip()
        if not line:
            continue
        try:
            entry = json.loads(line)
        except json.JSONDecodeError:
            continue

        # Stop at /learn invocation
        if entry.get("type") == "assistant":
            msg = entry.get("message", {})
            content = msg.get("content", [])
            if isinstance(content, list):
                found_learn = False
                for item in content:
                    if (isinstance(item, dict) and item.get("type") == "tool_use"
                            and item.get("name") == "Skill"
                            and item.get("input", {}).get("skill") == "learn"):
                        found_learn = True
                        break
                if found_learn:
                    break

        # User prompts (string content only, not tool results)
        if entry.get("type") == "user":
            msg = entry.get("message", {})
            content = msg.get("content")
            if isinstance(content, str) and content.strip():
                user_prompts.append(content[:500])
                lower = content.lower()
                if any(phrase in lower for phrase in [
                    "no,", "don't", "instead", "actually", "wrong",
                    "not that", "change", "stop", "undo", "revert"
                ]):
                    corrections.append(content[:300])

        # Assistant messages with tool calls
        if entry.get("type") == "assistant":
            msg = entry.get("message", {})
            content = msg.get("content", [])
            if isinstance(content, list):
                for item in content:
                    if not isinstance(item, dict) or item.get("type") != "tool_use":
                        continue
                    name = item.get("name", "")
                    inp = item.get("input", {})

                    if name == "Skill":
                        skill_name = inp.get("skill", "")
                        if skill_name and skill_name != "learn":
                            invoked_skills.add(skill_name)
                        continue

                    if name.startswith("mcp__"):
                        parts = name.split("__", 2)
                        if len(parts) == 3:
                            server = parts[1]
                            tool = parts[2]
                            if server not in mcp_tools:
                                mcp_tools[server] = {}
                            if tool not in mcp_tools[server]:
                                mcp_tools[server][tool] = []
                            if len(mcp_tools[server][tool]) < 3:
                                mcp_tools[server][tool].append(inp)
                        continue

                    builtin_tools.add(name)

# Summary: use first user prompt
if user_prompts:
    summary = user_prompts[0][:200]

# For long sessions, sample first/last prompts
if len(user_prompts) > 20:
    sampled_prompts = user_prompts[:3] + user_prompts[-3:]
else:
    sampled_prompts = user_prompts

result = {
    "summary": summary,
    "user_prompts": sampled_prompts,
    "mcp_tools": {
        server: {tool: samples for tool, samples in tools.items()}
        for server, tools in mcp_tools.items()
    },
    "invoked_skills": sorted(invoked_skills),
    "builtin_tools": sorted(builtin_tools),
    "corrections": corrections
}

print(json.dumps(result, indent=2, default=str))
