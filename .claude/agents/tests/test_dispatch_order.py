"""Structure of the dispatch order in .claude/agents/bdd-orchestrator.md, read as Markdown."""

import re
from pathlib import Path

import pytest

AGENTS_DIR = Path(__file__).resolve().parents[1]
ORCHESTRATOR = AGENTS_DIR / "bdd-orchestrator.md"
DISPATCH_HEADING = "## Process (dispatch order)"
PHASE_COUNT = 16

EXPECTED_ORDER = [
    "requirements-analyst",
    "gherkin-writer",
    "scenario-critic",
    "step-definition-scaffolder",
    "red-phase-verifier",
    "task-decomposer",
    "implementation-engineer",
    "green-phase-verifier",
    "refactor-specialist",
    "unit-test-augmenter",
    "code-reviewer",
    "spec-alignment-auditor",
    "regression-runner",
    "documentation-scribe",
    "work-verifier",
    "release-reporter",
]

# Routing per ADR-0003 as amended by ADR-0014 in decisions.md.
OPUS_AGENTS = {
    "requirements-analyst",
    "scenario-critic",
    "spec-alignment-auditor",
    "work-verifier",
    "code-reviewer",
}
SONNET_AGENTS = {
    "gherkin-writer",
    "step-definition-scaffolder",
    "task-decomposer",
    "implementation-engineer",
    "refactor-specialist",
    "unit-test-augmenter",
}
HAIKU_AGENTS = {
    "red-phase-verifier",
    "green-phase-verifier",
    "regression-runner",
    "documentation-scribe",
    "release-reporter",
}
EXPECTED_MODEL = {
    **{name: "opus" for name in OPUS_AGENTS},
    **{name: "sonnet" for name in SONNET_AGENTS},
    **{name: "haiku" for name in HAIKU_AGENTS},
}

NUMBERED_ITEM = re.compile(r"^(\d+)\. (.*)$")
BACKTICKED_TOKEN = re.compile(r"`([^`]+)`")
FRONTMATTER = re.compile(r"\A---\n(.*?)\n---\n", re.DOTALL)
MODEL_FIELD = re.compile(r"^model:\s*(\S+)\s*$", re.MULTILINE)


def dispatch_section(markdown: str) -> str:
    """Return the body of the dispatch-order section, up to the next heading."""
    _, heading, rest = markdown.partition(DISPATCH_HEADING)
    assert heading, f"{DISPATCH_HEADING!r} is missing from the orchestrator prompt"
    body, _, _ = rest.partition("\n## ")
    return body


def dispatched_agents(markdown: str) -> list[str]:
    """Return the first backticked token of each numbered item in the dispatch section."""
    agents = []
    for line in dispatch_section(markdown).splitlines():
        item = NUMBERED_ITEM.match(line)
        if item is None:
            continue
        token = BACKTICKED_TOKEN.search(item.group(2))
        assert token, f"dispatch item {item.group(1)} names no backticked agent: {line!r}"
        agents.append(token.group(1))
    return agents


def frontmatter_model(agent_file: Path) -> str:
    """Return the `model:` value from an agent file's YAML frontmatter."""
    frontmatter = FRONTMATTER.match(agent_file.read_text())
    assert frontmatter, f"{agent_file.name} has no YAML frontmatter"
    model = MODEL_FIELD.search(frontmatter.group(1))
    assert model, f"agent {agent_file.stem} has no model: field in its frontmatter"
    return model.group(1)


def assert_expected_order(markdown: str) -> None:
    """Assert that the dispatch section lists EXPECTED_ORDER in that sequence."""
    assert dispatched_agents(markdown) == EXPECTED_ORDER


@pytest.fixture
def orchestrator_markdown() -> str:
    return ORCHESTRATOR.read_text()


def test_lists_sixteen_phases(orchestrator_markdown):
    assert len(dispatched_agents(orchestrator_markdown)) == PHASE_COUNT


def test_every_phase_names_an_existing_agent(orchestrator_markdown):
    missing = [
        name for name in dispatched_agents(orchestrator_markdown)
        if not (AGENTS_DIR / f"{name}.md").is_file()
    ]
    assert missing == [], f"no agent file under .claude/agents/ for: {missing}"


def test_dispatch_order_matches_expected_sequence(orchestrator_markdown):
    assert_expected_order(orchestrator_markdown)


def test_order_check_fails_when_two_phases_are_swapped(tmp_path, orchestrator_markdown):
    swapped = orchestrator_markdown.replace(
        "5. `red-phase-verifier`", "5. `implementation-engineer`"
    ).replace(
        "7. `implementation-engineer`", "7. `red-phase-verifier`"
    )
    assert swapped != orchestrator_markdown
    copy = tmp_path / "bdd-orchestrator.md"
    copy.write_text(swapped)
    with pytest.raises(AssertionError):
        assert_expected_order(copy.read_text())


def test_red_phase_precedes_implementation(orchestrator_markdown):
    agents = dispatched_agents(orchestrator_markdown)
    assert agents.index("red-phase-verifier") < agents.index("implementation-engineer")


def test_work_verifier_precedes_release_reporter(orchestrator_markdown):
    agents = dispatched_agents(orchestrator_markdown)
    assert agents.index("work-verifier") < agents.index("release-reporter")


@pytest.mark.parametrize("agent", EXPECTED_ORDER)
def test_phase_agent_routes_to_its_adr_model(agent):
    assert frontmatter_model(AGENTS_DIR / f"{agent}.md") == EXPECTED_MODEL[agent], (
        f"{agent} is routed off the ADR-0003/ADR-0014 model class"
    )


def test_missing_model_field_names_the_agent(tmp_path):
    agent_file = tmp_path / "nameless-runner.md"
    agent_file.write_text("---\nname: nameless-runner\n---\n\nBody.\n")
    with pytest.raises(AssertionError, match="nameless-runner"):
        frontmatter_model(agent_file)
