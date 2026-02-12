#!/usr/bin/env python3
"""
Tests for validate_agent.py.

Usage: python3 test_validate_agent.py

Creates temporary agent packages, runs validation against them, and asserts
expected pass/fail outcomes and error messages.
"""

import os
import sys
import shutil
import tempfile
from pathlib import Path

# Import the validator from the same directory
sys.path.insert(0, os.path.dirname(__file__))
from validate_agent import validate_agent, extract_frontmatter


# ---------------------------------------------------------------------------
# Test fixtures
# ---------------------------------------------------------------------------

VALID_SOUL = """\
# Test Agent

## Purpose

This agent does test things. It validates agent packages.

## Personality

Methodical, thorough, precise.

## Workflow

### Phase 1: Setup

Load tools and prepare environment.

### Phase 2: Execute

Run the core task.

## Skills Used

### Built-in Tools

- **Read** — reading config files

## Invocation

```
Run the test agent
```

## Guardrails

### Always
Follow the validation rules.

### Never
Skip validation steps.
"""

VALID_EVAL = """\
# Evaluation: Test Agent

## Overview

A successful run produces validated output.

## Success Criteria

### Required Outcomes

- [ ] Agent package passes validation
- [ ] All files are generated

### Quality Criteria

- [ ] Clear error messages on failure

## Evaluation Method

### Inputs

An agent directory path.

### Expected Outputs

Validation pass/fail with error details.

### Diagnostic Checklist

| Check | Pass | Fail |
|-------|------|------|
| SOUL.md exists | File present | File missing |

## Failure Modes

- **Missing files**: Check directory structure
- **Invalid frontmatter**: Check YAML syntax
"""

VALID_SPEC = """\
---
name: {name}
description: A test agent for validation. Use when asked to test validation.
---

Read and follow the instructions in `.claude/agents/{name}/SOUL.md`.
"""

VALID_SKILL = """\
---
name: slack
description: Slack integration for posting messages
---

# Slack — Skills for Test Agent

## Tools Used

### slack_post_message

**Purpose**: Post messages to Slack channels
"""


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

class TestContext:
    """Manages a temp directory with an agent package."""

    def __init__(self, agent_name="test-agent"):
        self.tmpdir = Path(tempfile.mkdtemp())
        self.agent_name = agent_name
        self.agents_dir = self.tmpdir / ".claude" / "agents"
        self.agent_dir = self.agents_dir / agent_name
        self.agent_dir.mkdir(parents=True)

    def write_soul(self, content=VALID_SOUL):
        (self.agent_dir / "SOUL.md").write_text(content)

    def write_eval(self, content=VALID_EVAL):
        (self.agent_dir / "EVAL.md").write_text(content)

    def write_spec(self, content=None):
        if content is None:
            content = VALID_SPEC.format(name=self.agent_name)
        (self.agents_dir / f"{self.agent_name}.md").write_text(content)

    def write_skill(self, skill_name="slack", content=VALID_SKILL):
        skill_dir = self.agent_dir / "skills" / skill_name
        skill_dir.mkdir(parents=True, exist_ok=True)
        (skill_dir / "SKILL.md").write_text(content)

    def write_valid_package(self):
        self.write_soul()
        self.write_eval()
        self.write_spec()

    def cleanup(self):
        shutil.rmtree(self.tmpdir)


def capture_output(func, *args, **kwargs):
    """Capture stdout from a function call."""
    from io import StringIO
    old_stdout = sys.stdout
    sys.stdout = StringIO()
    try:
        result = func(*args, **kwargs)
        output = sys.stdout.getvalue()
    finally:
        sys.stdout = old_stdout
    return result, output


# ---------------------------------------------------------------------------
# Tests
# ---------------------------------------------------------------------------

passed = 0
failed = 0


def assert_test(name, condition, detail=""):
    global passed, failed
    if condition:
        passed += 1
        print(f"  PASS: {name}")
    else:
        failed += 1
        print(f"  FAIL: {name}")
        if detail:
            print(f"        {detail}")


def test_valid_package():
    """A complete, valid agent package should pass."""
    ctx = TestContext()
    ctx.write_valid_package()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("valid package passes", result is True, output)
    assert_test("output says PASS", "PASS" in output, output)
    ctx.cleanup()


def test_valid_package_with_skill():
    """Valid package with a generated skill should pass."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill("slack")
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["slack"]
    )
    assert_test("valid package with skill passes", result is True, output)
    ctx.cleanup()


def test_missing_soul():
    """Missing SOUL.md should fail."""
    ctx = TestContext()
    ctx.write_eval()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("missing SOUL.md fails", result is False, output)
    assert_test(
        "error mentions SOUL.md",
        "SOUL.md: file not found" in output,
        output,
    )
    ctx.cleanup()


def test_missing_eval():
    """Missing EVAL.md should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("missing EVAL.md fails", result is False, output)
    assert_test(
        "error mentions EVAL.md",
        "EVAL.md: file not found" in output,
        output,
    )
    ctx.cleanup()


def test_missing_subagent_spec():
    """Missing subagent spec should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    # Don't write spec
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("missing subagent spec fails", result is False, output)
    assert_test(
        "error mentions spec",
        "Subagent spec: file not found" in output,
        output,
    )
    ctx.cleanup()


def test_soul_missing_sections():
    """SOUL.md without required sections should fail."""
    ctx = TestContext()
    ctx.write_soul(
        "# Agent\n\n## Purpose\n\nDoes stuff.\n\n## Workflow\n\n### Phase 1\n\nDo things.\n"
    )
    ctx.write_eval()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("SOUL.md missing sections fails", result is False, output)
    assert_test(
        "mentions missing Invocation",
        "Invocation" in output,
        output,
    )
    assert_test(
        "mentions missing Guardrails",
        "Guardrails" in output,
        output,
    )
    ctx.cleanup()


def test_soul_empty_purpose():
    """SOUL.md with empty Purpose section should fail."""
    ctx = TestContext()
    ctx.write_soul(
        "# Agent\n\n## Purpose\n\n## Workflow\n\nSteps.\n\n"
        "## Invocation\n\n```\nrun it\n```\n\n"
        "## Guardrails\n\n### Always\nBe good.\n\n### Never\nBe bad.\n"
    )
    ctx.write_eval()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("empty Purpose fails", result is False, output)
    assert_test(
        "mentions empty Purpose",
        "Purpose" in output and "empty" in output,
        output,
    )
    ctx.cleanup()


def test_soul_guardrails_no_subsections():
    """Guardrails without Always/Never subsections should fail."""
    ctx = TestContext()
    ctx.write_soul(
        "# Agent\n\n## Purpose\n\nDoes things.\n\n"
        "## Workflow\n\nSteps.\n\n"
        "## Invocation\n\n```\nrun it\n```\n\n"
        "## Guardrails\n\nJust some text with no subsections.\n"
    )
    ctx.write_eval()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("guardrails without subsections fails", result is False, output)
    assert_test(
        "mentions Always/Never",
        "Always" in output or "Never" in output,
        output,
    )
    ctx.cleanup()


def test_soul_missing_title():
    """SOUL.md without a top-level heading should fail."""
    ctx = TestContext()
    ctx.write_soul(
        "## Purpose\n\nDoes things.\n\n"
        "## Workflow\n\nSteps.\n\n"
        "## Invocation\n\n```\nrun it\n```\n\n"
        "## Guardrails\n\n### Always\nBe good.\n\n### Never\nBe bad.\n"
    )
    ctx.write_eval()
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("missing title fails", result is False, output)
    assert_test(
        "mentions top-level heading",
        "top-level heading" in output,
        output,
    )
    ctx.cleanup()


def test_eval_missing_sections():
    """EVAL.md without required sections should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval("# Eval\n\n## Overview\n\nTest.\n")
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("EVAL.md missing sections fails", result is False, output)
    assert_test(
        "mentions Success Criteria",
        "Success Criteria" in output,
        output,
    )
    assert_test(
        "mentions Failure Modes",
        "Failure Modes" in output,
        output,
    )
    ctx.cleanup()


def test_eval_no_checklist():
    """EVAL.md Success Criteria without checklist items should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval(
        "# Eval\n\n## Overview\n\nTest.\n\n"
        "## Success Criteria\n\nJust text, no checklist items.\n\n"
        "## Failure Modes\n\n- **Oops**: Fix it.\n"
    )
    ctx.write_spec()
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("eval without checklist fails", result is False, output)
    assert_test(
        "mentions checklist items",
        "checklist" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_spec_bad_name():
    """Subagent spec with non-kebab-case name should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    ctx.write_spec(
        "---\nname: My_Bad_Agent\ndescription: test\n---\n\n"
        "Read and follow SOUL.md.\n"
    )
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("bad spec name fails", result is False, output)
    assert_test(
        "mentions kebab-case",
        "kebab-case" in output,
        output,
    )
    ctx.cleanup()


def test_spec_empty_description():
    """Subagent spec with empty description should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    ctx.write_spec(
        "---\nname: test-agent\ndescription:\n---\n\n"
        "Read and follow the instructions in `.claude/agents/test-agent/SOUL.md`.\n"
    )
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("empty spec description fails", result is False, output)
    assert_test(
        "mentions description empty",
        "description" in output.lower() and "empty" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_spec_no_soul_reference():
    """Subagent spec body without SOUL.md reference should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    ctx.write_spec(
        "---\nname: test-agent\ndescription: A test agent.\n---\n\n"
        "Just do the thing.\n"
    )
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("spec without SOUL.md reference fails", result is False, output)
    assert_test(
        "mentions SOUL.md reference",
        "SOUL.md" in output and "reference" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_spec_no_frontmatter():
    """Subagent spec without frontmatter should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    ctx.write_spec("Just a plain markdown file with no frontmatter.\n")
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("spec without frontmatter fails", result is False, output)
    assert_test(
        "mentions frontmatter",
        "frontmatter" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_spec_name_too_long():
    """Subagent spec with name > 64 chars should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    long_name = "a" * 65
    ctx.write_spec(
        f"---\nname: {long_name}\ndescription: test\n---\n\n"
        "Read and follow the instructions in `.claude/agents/x/SOUL.md`.\n"
    )
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("long spec name fails", result is False, output)
    assert_test("mentions max 64", "64" in output, output)
    ctx.cleanup()


def test_spec_consecutive_hyphens():
    """Subagent spec name with consecutive hyphens should fail."""
    ctx = TestContext()
    ctx.write_soul()
    ctx.write_eval()
    ctx.write_spec(
        "---\nname: bad--name\ndescription: test\n---\n\n"
        "Read and follow the instructions in `.claude/agents/x/SOUL.md`.\n"
    )
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("consecutive hyphens fails", result is False, output)
    assert_test(
        "mentions consecutive hyphens",
        "consecutive" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_generated_skill_valid():
    """Valid generated skill should pass."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill("slack", VALID_SKILL)
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["slack"]
    )
    assert_test("valid generated skill passes", result is True, output)
    ctx.cleanup()


def test_generated_skill_no_frontmatter():
    """Generated skill without frontmatter should fail."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill("bad-server", "no frontmatter here\n")
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["bad-server"]
    )
    assert_test("skill without frontmatter fails", result is False, output)
    assert_test(
        "mentions skill frontmatter",
        "bad-server" in output and "frontmatter" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_generated_skill_empty_body():
    """Generated skill with empty body should fail."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill(
        "empty-server",
        "---\nname: empty-server\ndescription: test\n---\n",
    )
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["empty-server"]
    )
    assert_test("skill with empty body fails", result is False, output)
    assert_test(
        "mentions empty body",
        "empty" in output.lower() and "body" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_generated_skill_missing_name():
    """Generated skill without name in frontmatter should fail."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill(
        "no-name",
        "---\ndescription: test\n---\n\n# Tools\n\nSome tools.\n",
    )
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["no-name"]
    )
    assert_test("skill missing name fails", result is False, output)
    assert_test(
        "mentions missing name",
        "name" in output.lower() and "missing" in output.lower(),
        output,
    )
    ctx.cleanup()


def test_generated_skill_dir_not_found():
    """Specifying a nonexistent generated skill should warn."""
    ctx = TestContext()
    ctx.write_valid_package()
    result, output = capture_output(
        validate_agent, str(ctx.agent_dir), ["nonexistent"]
    )
    assert_test(
        "nonexistent skill dir still passes (warns)",
        result is True,
        output,
    )
    assert_test("warns about missing dir", "WARN" in output, output)
    ctx.cleanup()


def test_unvalidated_skills_warning():
    """Skills present but not specified should produce a warning."""
    ctx = TestContext()
    ctx.write_valid_package()
    ctx.write_skill("slack")
    result, output = capture_output(validate_agent, str(ctx.agent_dir))
    assert_test("unvalidated skills warns", "WARN" in output, output)
    assert_test(
        "warning mentions skill names",
        "slack" in output,
        output,
    )
    ctx.cleanup()


def test_agent_dir_not_found():
    """Nonexistent agent directory should fail."""
    result, output = capture_output(
        validate_agent, "/tmp/nonexistent-agent-dir-12345"
    )
    assert_test("nonexistent agent dir fails", result is False, output)
    ctx = None  # no cleanup needed


def test_extract_frontmatter_valid():
    """extract_frontmatter should parse simple YAML."""
    fm, err = extract_frontmatter(
        "---\nname: test\ndescription: hello world\n---\n\nBody."
    )
    assert_test("extracts frontmatter", fm is not None and err is None)
    assert_test("name correct", fm.get("name") == "test")
    assert_test("description correct", fm.get("description") == "hello world")


def test_extract_frontmatter_multiline_description():
    """extract_frontmatter should handle multi-line YAML values."""
    fm, err = extract_frontmatter(
        "---\nname: test\ndescription: >\n  line one\n  line two\n---\n\nBody."
    )
    assert_test("multiline frontmatter parses", fm is not None and err is None)
    assert_test(
        "multiline description captured",
        fm is not None and "line one" in fm.get("description", ""),
    )


def test_extract_frontmatter_no_delimiters():
    """extract_frontmatter should fail without --- delimiters."""
    fm, err = extract_frontmatter("name: test\ndescription: hello\n")
    assert_test("no delimiters fails", fm is None)
    assert_test("error mentions frontmatter", "frontmatter" in err.lower())


# ---------------------------------------------------------------------------
# Runner
# ---------------------------------------------------------------------------

if __name__ == "__main__":
    print("Running validate_agent.py tests...\n")

    test_valid_package()
    test_valid_package_with_skill()
    test_missing_soul()
    test_missing_eval()
    test_missing_subagent_spec()
    test_soul_missing_sections()
    test_soul_empty_purpose()
    test_soul_guardrails_no_subsections()
    test_soul_missing_title()
    test_eval_missing_sections()
    test_eval_no_checklist()
    test_spec_bad_name()
    test_spec_empty_description()
    test_spec_no_soul_reference()
    test_spec_no_frontmatter()
    test_spec_name_too_long()
    test_spec_consecutive_hyphens()
    test_generated_skill_valid()
    test_generated_skill_no_frontmatter()
    test_generated_skill_empty_body()
    test_generated_skill_missing_name()
    test_generated_skill_dir_not_found()
    test_unvalidated_skills_warning()
    test_agent_dir_not_found()
    test_extract_frontmatter_valid()
    test_extract_frontmatter_multiline_description()
    test_extract_frontmatter_no_delimiters()

    print(f"\n{'=' * 40}")
    print(f"Results: {passed} passed, {failed} failed")
    print(f"{'=' * 40}")
    sys.exit(0 if failed == 0 else 1)
