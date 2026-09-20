"""Keep complexity labels and implementation-agent routing aligned."""

import json
import re
from pathlib import Path


AGENTS_DIR = Path(__file__).resolve().parents[1]
IMPLEMENTATION = AGENTS_DIR / "implementation-engineer.md"
DECOMPOSER = AGENTS_DIR / "task-decomposer.md"

EXPECTED_AGENTS = {
    "SIMPLE": ("simple-implementation-engineer", "haiku"),
    "MEDIUM": ("medium-implementation-engineer", "sonnet"),
    "COMPLEX": ("complex-implementation-engineer", "opus"),
}


def frontmatter(path: Path) -> str:
    """Return the YAML frontmatter from an agent prompt."""
    match = re.match(r"\A---\n(.*?)\n---\n", path.read_text(), re.DOTALL)
    assert match, f"{path.name} has no YAML frontmatter"
    return match.group(1)


def test_each_complexity_has_an_agent_with_expected_model():
    for complexity, (agent, model) in EXPECTED_AGENTS.items():
        path = AGENTS_DIR / f"{agent}.md"
        assert path.is_file(), f"missing agent for {complexity}: {path.name}"
        metadata = frontmatter(path)
        assert f"name: {agent}" in metadata
        assert f"model: {model}" in metadata


def test_decomposer_requires_complexity_on_each_item():
    prompt = DECOMPOSER.read_text()
    assert "Classify every item as `SIMPLE`, `MEDIUM`, or `COMPLEX`" in prompt
    assert "`[SIMPLE]`, `[MEDIUM]`, or" in prompt
    assert "source scenario ids" in prompt
    assert "one concrete verification" in prompt


def test_dispatcher_maps_each_complexity_to_its_agent():
    prompt = IMPLEMENTATION.read_text()
    for complexity, (agent, _) in EXPECTED_AGENTS.items():
        assert re.search(rf"`\[{complexity}\]` items to\s+`{agent}`", prompt)


def test_dispatcher_owns_completion_and_has_todo_tool():
    dispatcher = IMPLEMENTATION.read_text()
    assert 'tools: ["Task", "TodoWrite"' in dispatcher
    assert "dispatcher, not the delegated agent, marks the item complete" in dispatcher

    for complexity, (agent, _) in EXPECTED_AGENTS.items():
        child = (AGENTS_DIR / f"{agent}.md").read_text()
        assert "Do not mark the item complete" in child
        assert f"LABEL: {complexity}" in child
        assert "STATUS: COMPLETE|ESCALATE|BLOCKED" in child
        assert "RECOMMENDED_LABEL:" in child


def test_repo_reviewers_use_declared_schema_stages():
    schema = json.loads((AGENTS_DIR.parent / "review" / "schema.json").read_text())
    stages = set(schema["properties"]["stage"]["enum"])
    expected = {
        "payload-compatibility-reviewer": "payload-compatibility",
        "release-archive-reviewer": "release-archive",
    }
    for agent, stage in expected.items():
        metadata = frontmatter(AGENTS_DIR / f"{agent}.md")
        assert f"stage: {stage}" in metadata
        assert stage in stages
        assert ".claude/review/schema.json" in (AGENTS_DIR / f"{agent}.md").read_text()
