"""The shape standards/agents.md fixes for every file under .claude/agents/."""

import json
import re
from pathlib import Path

import pytest

AGENTS_DIR = Path(__file__).resolve().parents[1]

FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n(.*)\Z", re.DOTALL)
FIELD = re.compile(r"^([a-z_]+):[ ]*(.*)$")
HEADING = re.compile(r"^## (.+)$", re.MULTILINE)

REQUIRED_FIELDS = ["name", "description", "model", "color", "tools"]
STAGE_FIELD = "stage"
MODEL_CLASSES = {"opus", "sonnet", "haiku"}
SCHEMA = AGENTS_DIR.parents[1] / "specflow" / "references" / "findings-schema.json"
REQUIRED_HEADINGS = [
    "When to invoke",
    "Inputs",
    "Process",
    "Stop conditions",
    "Self-check",
    "Output format",
]
DESCRIPTION_MIN_WORDS = 40
DESCRIPTION_MAX_WORDS = 70
BOUNDARY_CLAUSE = "not for"

# bdd-orchestrator carries "## Process (dispatch order)", which
# test_dispatch_order.py matches verbatim. Compare the heading by its opening
# word so both tests hold the same file.
HEADING_PREFIXES = {"Process"}


def agent_files() -> list[Path]:
    """Return every agent definition, sorted by name."""
    return sorted(AGENTS_DIR.glob("*.md"))


def split_frontmatter(agent_file: Path) -> tuple[str, str]:
    """Return an agent file's frontmatter and body.

    Raises `AssertionError` when the file opens with no YAML frontmatter.
    """
    parsed = FRONTMATTER.match(agent_file.read_text())
    assert parsed, f"{agent_file.name} opens with no YAML frontmatter"
    return parsed.group(1), parsed.group(2)


def field_order(frontmatter: str) -> list[str]:
    """Return the frontmatter field names, in the order they appear."""
    return [
        match.group(1)
        for line in frontmatter.splitlines()
        if (match := FIELD.match(line))
    ]


def field_value(frontmatter: str, name: str) -> str:
    """Return one frontmatter field's raw value."""
    for line in frontmatter.splitlines():
        match = FIELD.match(line)
        if match and match.group(1) == name:
            return match.group(2).strip()
    raise AssertionError(f"no {name}: field in the frontmatter")


def headings(body: str) -> list[str]:
    """Return the body's level-two headings, in order, trimmed to their prefix."""
    found = []
    for heading in HEADING.findall(body):
        first_word = heading.split()[0]
        found.append(first_word if first_word in HEADING_PREFIXES else heading)
    return found


def declared_stages() -> set[str]:
    """Return the stage values findings-schema.json allows a reviewer to write."""
    schema = json.loads(SCHEMA.read_text())
    return set(schema["properties"]["stage"]["enum"])


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_frontmatter_carries_the_five_fields_in_order(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    fields = [name for name in field_order(frontmatter) if name != STAGE_FIELD]
    assert fields == REQUIRED_FIELDS, (
        f"{agent_file.name} frontmatter is {field_order(frontmatter)}; "
        f"expected {REQUIRED_FIELDS} with an optional trailing {STAGE_FIELD}. "
        "See Frontmatter in standards/agents.md."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_stage_when_present_is_last_and_declared_by_the_schema(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    order = field_order(frontmatter)
    if STAGE_FIELD not in order:
        pytest.skip(f"{agent_file.stem} writes no findings document")
    assert order[-1] == STAGE_FIELD, (
        f"{agent_file.name} puts {STAGE_FIELD} at position {order.index(STAGE_FIELD)}; "
        "it comes last."
    )
    stage = field_value(frontmatter, STAGE_FIELD)
    assert stage in declared_stages(), (
        f"{agent_file.name} declares stage {stage!r}, which "
        "specflow/references/findings-schema.json does not list. The merge gate "
        f"rejects that document. Allowed: {sorted(declared_stages())}."
    )


def test_every_declared_schema_stage_has_a_reviewer():
    claimed = set()
    for path in agent_files():
        frontmatter, _ = split_frontmatter(path)
        if STAGE_FIELD in field_order(frontmatter):
            claimed.add(field_value(frontmatter, STAGE_FIELD))
    orphaned = declared_stages() - claimed
    assert orphaned == set(), (
        f"findings-schema.json declares {sorted(orphaned)} with no agent writing "
        "them. Add the reviewer, or remove the stage from the schema enum."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_name_matches_the_file_name(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    assert field_value(frontmatter, "name") == agent_file.stem


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_model_names_a_class_adr_0003_allows(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    model = field_value(frontmatter, "model")
    assert model in MODEL_CLASSES, (
        f"{agent_file.name} routes to model {model!r}; expected one of "
        f"{sorted(MODEL_CLASSES)} per ADR-0003 as amended by ADR-0014."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_tools_is_a_json_array_of_strings(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    raw = field_value(frontmatter, "tools")
    try:
        tools = json.loads(raw)
    except json.JSONDecodeError:
        raise AssertionError(
            f"{agent_file.name} tools is {raw!r}; expected a JSON array such as "
            '["Read", "Grep"]. See Frontmatter in standards/agents.md.'
        )
    assert isinstance(tools, list) and all(isinstance(tool, str) for tool in tools)
    assert tools, f"{agent_file.name} lists no tool"


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_description_falls_in_the_routing_word_range(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    words = len(field_value(frontmatter, "description").split())
    assert DESCRIPTION_MIN_WORDS <= words <= DESCRIPTION_MAX_WORDS, (
        f"{agent_file.name} description is {words} words; expected "
        f"{DESCRIPTION_MIN_WORDS} to {DESCRIPTION_MAX_WORDS}. It is the only text "
        "a dispatcher matches on."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_description_names_the_boundary_it_refuses(agent_file):
    frontmatter, _ = split_frontmatter(agent_file)
    description = field_value(frontmatter, "description").lower()
    assert BOUNDARY_CLAUSE in description, (
        f"{agent_file.name} description has no {BOUNDARY_CLAUSE!r} clause, so it "
        "collides with its neighbours on every request."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_body_carries_every_required_heading(agent_file):
    _, body = split_frontmatter(agent_file)
    missing = [name for name in REQUIRED_HEADINGS if name not in headings(body)]
    assert missing == [], (
        f"{agent_file.name} is missing {missing}. See Body sections in "
        "standards/agents.md."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_required_headings_keep_their_order(agent_file):
    _, body = split_frontmatter(agent_file)
    found = [name for name in headings(body) if name in REQUIRED_HEADINGS]
    assert found == REQUIRED_HEADINGS, (
        f"{agent_file.name} orders its required headings {found}; expected "
        f"{REQUIRED_HEADINGS}. An agent may add a section of its own between "
        "them, but not reorder these."
    )


@pytest.mark.parametrize("agent_file", agent_files(), ids=lambda path: path.stem)
def test_body_opens_with_a_role_paragraph(agent_file):
    _, body = split_frontmatter(agent_file)
    role = body.split("## ")[0].strip()
    assert role, f"{agent_file.name} states no role above its first heading"
    assert role.startswith("You "), (
        f"{agent_file.name} opens with {role[:40]!r}; a role addresses the agent "
        'as "You".'
    )


def test_no_agent_keeps_a_core_responsibilities_heading():
    offenders = [
        path.name for path in agent_files()
        if "## Core responsibilities" in path.read_text()
    ]
    assert offenders == [], (
        f"{offenders} still list capabilities; standards/agents.md replaces the "
        "section with an ordered ## Process."
    )


def test_a_stage_outside_the_schema_enum_is_rejected(tmp_path):
    invented = tmp_path / "invented.md"
    invented.write_text(
        '---\nname: invented\ndescription: d\nmodel: haiku\ncolor: red\n'
        'tools: ["Read"]\nstage: invented-stage\n---\n\nYou do one thing.\n'
    )
    frontmatter, _ = split_frontmatter(invented)
    assert field_value(frontmatter, STAGE_FIELD) not in declared_stages()


def test_field_order_check_rejects_a_shuffled_frontmatter(tmp_path):
    shuffled = tmp_path / "shuffled.md"
    shuffled.write_text(
        '---\nname: shuffled\nmodel: haiku\ndescription: d\ncolor: red\n'
        'tools: ["Read"]\n---\n\nYou do one thing.\n'
    )
    frontmatter, _ = split_frontmatter(shuffled)
    assert field_order(frontmatter) != REQUIRED_FIELDS
