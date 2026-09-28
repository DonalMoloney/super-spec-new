<!-- specflow template: constitution-template 1.1.0 -->
# [PROJECT_NAME] Constitution

## Core Principles

### [PRINCIPLE_1_NAME]
<!-- Example: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: Every feature starts as a standalone library. Each library stays self-contained and independently testable, and each library ships with its own documentation. A library that exists only to organize code serves no clear purpose, so it does not ship. -->

### [PRINCIPLE_2_NAME]
<!-- Example: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Every library exposes its functionality through a CLI. Input arrives as text on stdin or as arguments. Output goes to stdout; errors go to stderr. The CLI supports JSON and a human-readable format. -->

### [PRINCIPLE_3_NAME]
<!-- Example: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: TDD is mandatory. Write the tests, get them approved, watch them fail, then implement. Red-Green-Refactor must run without exception. -->

### [PRINCIPLE_4_NAME]
<!-- Example: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: Integration tests cover four areas: a new library's contract tests, a contract change, communication between services, and a shared schema. -->

### [PRINCIPLE_5_NAME]
<!-- Example: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Example: Text I/O lets a person debug the system. The system must log in a structured format. Or version numbers follow MAJOR.MINOR.BUILD. Or start simple and apply YAGNI. -->

## Technology Stack

<!-- Name the project's core technology choices below. -->

| Layer | Technology | Purpose |
|-------|-----------|---------|
| [LAYER_1] | [TECHNOLOGY] | [PURPOSE] |
| [LAYER_2] | [TECHNOLOGY] | [PURPOSE] |

## Development Workflow

<!--
  These steps connect the project to the specflow pipeline.
  Edit them to match the team's process.
-->

This project follows **specification-driven development** through the specflow pipeline:

1. **Constitution** (`/speckit.constitution`): Set and keep these governance principles
2. **Specification** (`/speckit.specify`): Write feature requirements before any code
3. **Brainstorming** (`/speckit.specflow.brainstorm`): Question assumptions and find edge cases
4. **Planning** (`/speckit.plan`): Design the technical approach and check it against the constitution
5. **Task Decomposition** (`/speckit.specflow.tasks`): Split the plan into executable, trackable tasks
6. **Execution** (`/speckit.specflow.execute`): Build with the discipline the task needs (TDD, subagents)
7. **Review** (`/speckit.specflow.review`): Check the implementation against the spec and the constitution

### Workflow Rules

- No code precedes an approved spec
- Every spec needs at least one brainstorm session
- An implementation plan must pass a constitution compliance check
- Every phase boundary needs explicit human approval

## Quality Gates

<!--
  Name the review and testing gates that apply to this project.
  The /speckit.specflow.review command reads these. So does /speckit.specflow.execute.
-->

### Testing Requirements

- [ ] **Unit tests**: [REQUIRED/OPTIONAL], [coverage target or "none specified"]
- [ ] **Integration tests**: [REQUIRED/OPTIONAL], [scope description]
- [ ] **Contract tests**: [REQUIRED/OPTIONAL], [API boundary description]
- [ ] **TDD discipline**: [REQUIRED/OPTIONAL], tasks marked `[TDD]` must follow RED-GREEN-REFACTOR

### Review Requirements

- [ ] **Code review**: [REQUIRED/OPTIONAL], [who reviews, what criteria]
- [ ] **Spec compliance**: [REQUIRED/OPTIONAL], check that every acceptance scenario passes
- [ ] **Security review**: [REQUIRED/OPTIONAL], [scope description]
- [ ] **Performance review**: [REQUIRED/OPTIONAL], [benchmarks or targets]

### Review Stages

<!--
  Set which review stages this project runs and how strong a model each needs.
  Name a model class, never a specific model or agent: the class must resolve
  on whichever agent CLI the project uses. /speckit.specflow.review runs the
  four stages below; the risk classifier decides whether Stage 2 and Stage 3
  run.
-->

| Stage | When it runs | Model class |
|-------|--------------|-------------|
| Stage 0: spec red team and threat model | After /speckit.clarify, before any code exists | strongest |
| Stage 1: conformance | On every change, against the acceptance scenarios in spec.md | standard |
| Stage 2: panel (correctness, security, maintainability, performance) | On a change the risk classifier marks HIGH | standard |
| Stage 3: critic | After the panel, over the panel's findings | strongest |

### Deployment Gates

- [ ] All tests pass
- [ ] No review item stays open
- [ ] The constitution compliance check passes
- [ ] [PROJECT-SPECIFIC GATE]

## Code Review Rules

- **Error handling**: Follow [ERROR_HANDLING_CONVENTION].
- **Forbidden dependencies**: Reject [FORBIDDEN_DEPENDENCIES].
- **Security rules**: Enforce [SECURITY_RULES].
- **Spec approved**: Get human approval before implementation. Record [SPEC_APPROVAL_EVIDENCE].
- **Merge approved**: Get human approval before merging. Record [MERGE_APPROVAL_EVIDENCE].

<!--
  The test gate runs the command on the line below before it lets a task be
  ticked. Keep the line's "Test command:" prefix and put the command after it.
-->

Test command: [TEST_COMMAND]

## Governance

This constitution governs every development activity in the project.
An amendment needs:

- A documented rationale for the change
- Updated specs and plans
- Confirmation that the amendment violates no principle

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]
