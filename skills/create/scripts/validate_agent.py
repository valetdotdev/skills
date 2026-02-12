#!/usr/bin/env python3
"""
Validate a generated agent package.

Checks the agent directory structure, SOUL.md sections, EVAL.md sections,
subagent spec frontmatter, and optionally generated skill files.

Usage:
  python3 validate_agent.py <agent-dir> [skill-name ...]

Arguments:
  agent-dir      Path to the agent directory (e.g., .claude/agents/my-agent)
  skill-name     Optional names of generated skill subdirs to validate
                 (under <agent-dir>/skills/). Omit to skip skill validation
                 — use this to avoid validating imported/copied skills.

Examples:
  python3 validate_agent.py .claude/agents/daily-digest
  python3 validate_agent.py .claude/agents/daily-digest slack reddit-mcp-buddy
"""

import sys
import os
import re
from pathlib import Path


def extract_frontmatter(content):
    """Extract and parse YAML frontmatter from markdown content."""
    if not content.startswith("---"):
        return None, "No YAML frontmatter found (file must start with ---)"
    match = re.match(r"^---\n(.*?)\n---", content, re.DOTALL)
    if not match:
        return None, "Invalid frontmatter format (missing closing ---)"
    text = match.group(1)
    # Simple YAML parsing without pyyaml dependency
    result = {}
    current_key = None
    current_value_lines = []
    for line in text.split("\n"):
        # Handle top-level key: value
        kv = re.match(r"^(\w[\w-]*):\s*(.*)", line)
        if kv:
            if current_key:
                result[current_key] = "\n".join(current_value_lines).strip()
            current_key = kv.group(1)
            current_value_lines = [kv.group(2)]
        elif current_key and (line.startswith("  ") or line.startswith("\t")):
            current_value_lines.append(line.strip())
        elif current_key and line.strip() == "":
            current_value_lines.append("")
    if current_key:
        result[current_key] = "\n".join(current_value_lines).strip()
    return result, None


def check_sections(content, required_sections, file_label):
    """Check that markdown content contains required ## sections."""
    errors = []
    # Normalize: extract all ## headings (level 2)
    headings = re.findall(r"^##\s+(.+)$", content, re.MULTILINE)
    heading_names = [h.strip().lower() for h in headings]
    for section in required_sections:
        if section.lower() not in heading_names:
            errors.append(f"{file_label}: missing required section '## {section}'")
    return errors


def check_section_not_empty(content, section_name, file_label):
    """Check that a ## section has content (not just a heading)."""
    pattern = rf"^##\s+{re.escape(section_name)}\s*\n(.*?)(?=^##\s|\Z)"
    match = re.search(pattern, content, re.MULTILINE | re.DOTALL)
    if match:
        body = match.group(1).strip()
        if not body:
            return f"{file_label}: section '## {section_name}' is empty"
    return None


def validate_soul(agent_dir):
    """Validate SOUL.md structure and content."""
    errors = []
    soul_path = agent_dir / "SOUL.md"
    if not soul_path.exists():
        return ["SOUL.md: file not found (required)"]

    content = soul_path.read_text()

    # Must have a top-level heading
    if not re.search(r"^#\s+\S", content, re.MULTILINE):
        errors.append("SOUL.md: missing top-level heading (# Title)")

    # Required sections
    required = ["Purpose", "Workflow", "Invocation", "Guardrails"]
    errors.extend(check_sections(content, required, "SOUL.md"))

    # Check key sections are not empty
    for section in ["Purpose", "Workflow"]:
        err = check_section_not_empty(content, section, "SOUL.md")
        if err:
            errors.append(err)

    # Guardrails should have Always and/or Never subsections
    if "## Guardrails" in content:
        guardrails_match = re.search(
            r"^##\s+Guardrails\s*\n(.*?)(?=^##\s[^#]|\Z)",
            content,
            re.MULTILINE | re.DOTALL,
        )
        if guardrails_match:
            guardrails_body = guardrails_match.group(1)
            has_always = re.search(r"^###\s+Always", guardrails_body, re.MULTILINE)
            has_never = re.search(r"^###\s+Never", guardrails_body, re.MULTILINE)
            if not has_always and not has_never:
                errors.append(
                    "SOUL.md: Guardrails section should contain '### Always' and/or '### Never' subsections"
                )

    return errors


def validate_eval(agent_dir):
    """Validate EVAL.md structure and content."""
    errors = []
    eval_path = agent_dir / "EVAL.md"
    if not eval_path.exists():
        return ["EVAL.md: file not found (required)"]

    content = eval_path.read_text()

    # Must have a top-level heading
    if not re.search(r"^#\s+\S", content, re.MULTILINE):
        errors.append("EVAL.md: missing top-level heading (# Title)")

    # Required sections
    required = ["Overview", "Success Criteria", "Failure Modes"]
    errors.extend(check_sections(content, required, "EVAL.md"))

    # Success Criteria should have checklist items
    criteria_match = re.search(
        r"^##\s+Success Criteria\s*\n(.*?)(?=^##\s[^#]|\Z)",
        content,
        re.MULTILINE | re.DOTALL,
    )
    if criteria_match:
        criteria_body = criteria_match.group(1)
        if "- [ ]" not in criteria_body and "- [x]" not in criteria_body:
            errors.append(
                "EVAL.md: Success Criteria should contain checklist items (- [ ] ...)"
            )

    return errors


def validate_subagent_spec(agent_dir):
    """Validate the subagent spec file (.claude/agents/<name>.md)."""
    errors = []
    spec_path = agent_dir.parent / f"{agent_dir.name}.md"
    if not spec_path.exists():
        return [
            f"Subagent spec: file not found at {spec_path.name} (required sibling of agent directory)"
        ]

    content = spec_path.read_text()
    frontmatter, err = extract_frontmatter(content)
    if err:
        return [f"Subagent spec: {err}"]

    if "name" not in frontmatter:
        errors.append("Subagent spec: missing 'name' in frontmatter")
    elif not frontmatter["name"]:
        errors.append("Subagent spec: 'name' is empty")
    else:
        name = frontmatter["name"]
        if not re.match(r"^[a-z0-9][a-z0-9-]*[a-z0-9]$|^[a-z0-9]$", name):
            errors.append(
                f"Subagent spec: name '{name}' should be kebab-case (lowercase, digits, hyphens; no leading/trailing hyphens)"
            )
        if "--" in name:
            errors.append(
                f"Subagent spec: name '{name}' contains consecutive hyphens"
            )
        if len(name) > 64:
            errors.append(
                f"Subagent spec: name is too long ({len(name)} chars, max 64)"
            )

    if "description" not in frontmatter:
        errors.append("Subagent spec: missing 'description' in frontmatter")
    elif not frontmatter["description"]:
        errors.append("Subagent spec: 'description' is empty")

    # Body should reference SOUL.md
    body = re.sub(r"^---\n.*?\n---\n?", "", content, count=1, flags=re.DOTALL)
    if "SOUL.md" not in body:
        errors.append(
            "Subagent spec: body should reference SOUL.md (e.g., 'Read and follow the instructions in .claude/agents/<name>/SOUL.md')"
        )

    return errors


def validate_generated_skill(skill_dir):
    """Validate a generated MCP server SKILL.md (not imported/copied skills)."""
    errors = []
    label = f"skills/{skill_dir.name}/SKILL.md"
    skill_md = skill_dir / "SKILL.md"
    if not skill_md.exists():
        return [f"{label}: file not found"]

    content = skill_md.read_text()
    frontmatter, err = extract_frontmatter(content)
    if err:
        return [f"{label}: {err}"]

    if "name" not in frontmatter:
        errors.append(f"{label}: missing 'name' in frontmatter")
    elif not frontmatter["name"]:
        errors.append(f"{label}: 'name' is empty")

    if "description" not in frontmatter:
        errors.append(f"{label}: missing 'description' in frontmatter")
    elif not frontmatter["description"]:
        errors.append(f"{label}: 'description' is empty")

    # Body should document at least one tool
    body = re.sub(r"^---\n.*?\n---\n?", "", content, count=1, flags=re.DOTALL)
    if not body.strip():
        errors.append(f"{label}: body is empty (should document tools)")

    return errors


def validate_agent(agent_dir_path, generated_skill_names=None):
    """Run all validations on an agent package."""
    agent_dir = Path(agent_dir_path).resolve()
    errors = []
    warnings = []

    # Check agent directory exists
    if not agent_dir.is_dir():
        print(f"FAIL: Agent directory not found: {agent_dir}")
        return False

    # Core validations
    errors.extend(validate_soul(agent_dir))
    errors.extend(validate_eval(agent_dir))
    errors.extend(validate_subagent_spec(agent_dir))

    # Validate generated skill files (not imported/copied)
    if generated_skill_names:
        skills_dir = agent_dir / "skills"
        for skill_name in generated_skill_names:
            skill_dir = skills_dir / skill_name
            if skill_dir.is_dir():
                errors.extend(validate_generated_skill(skill_dir))
            else:
                warnings.append(
                    f"skills/{skill_name}/: directory not found (skipping)"
                )

    # Check for skills/ dir with no generated skills specified
    skills_dir = agent_dir / "skills"
    if skills_dir.is_dir() and not generated_skill_names:
        skill_subdirs = [d.name for d in skills_dir.iterdir() if d.is_dir()]
        if skill_subdirs:
            warnings.append(
                f"skills/ contains {len(skill_subdirs)} subdirectory(ies) but none were specified for validation. "
                f"Pass generated skill names as arguments to validate them: {', '.join(skill_subdirs)}"
            )

    # Report
    if warnings:
        for w in warnings:
            print(f"  WARN: {w}")

    if errors:
        print(f"\nFAIL: {len(errors)} error(s) found:\n")
        for e in errors:
            print(f"  ERROR: {e}")
        return False
    else:
        print("PASS: Agent package is valid!")
        return True


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python3 validate_agent.py <agent-dir> [generated-skill-name ...]")
        print()
        print("  agent-dir            Path to .claude/agents/<name>/ directory")
        print("  generated-skill-name Names of skill subdirs to validate (optional)")
        print()
        print("Examples:")
        print("  python3 validate_agent.py .claude/agents/daily-digest")
        print("  python3 validate_agent.py .claude/agents/daily-digest slack reddit")
        sys.exit(1)

    agent_dir = sys.argv[1]
    generated_skills = sys.argv[2:] if len(sys.argv) > 2 else None

    valid = validate_agent(agent_dir, generated_skills)
    sys.exit(0 if valid else 1)
