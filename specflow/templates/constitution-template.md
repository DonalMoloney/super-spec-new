<!-- specflow template: constitution-template 1.1.0 -->
# [PROJECT_NAME] Constitution

## Core Principles

### [PRINCIPLE_1_NAME]
<!-- Example: I. Library-First -->
[PRINCIPLE_1_DESCRIPTION]
<!-- Example: Every feature starts as a standalone library. Each library stays self-contained, independently testable, and documented. An organizational-only library has no clear purpose and does not ship. -->

### [PRINCIPLE_2_NAME]
<!-- Example: II. CLI Interface -->
[PRINCIPLE_2_DESCRIPTION]
<!-- Example: Every library exposes its functionality through a CLI. Input arrives as text on stdin or args; output goes to stdout, errors to stderr. The CLI supports JSON and a human-readable format. -->

### [PRINCIPLE_3_NAME]
<!-- Example: III. Test-First (NON-NEGOTIABLE) -->
[PRINCIPLE_3_DESCRIPTION]
<!-- Example: TDD is mandatory. Write the tests, get them approved, watch them fail, then implement. The Red-Green-Refactor cycle is enforced without exception. -->

### [PRINCIPLE_4_NAME]
<!-- Example: IV. Integration Testing -->
[PRINCIPLE_4_DESCRIPTION]
<!-- Example: Integration tests cover four areas: a new library's contract tests, a contract change, inter-service communication, and a shared schema. -->

### [PRINCIPLE_5_NAME]
<!-- Example: V. Observability, VI. Versioning & Breaking Changes, VII. Simplicity -->
[PRINCIPLE_5_DESCRIPTION]
<!-- Example: Text I/O makes the system debuggable. Structured logging is required. Or: version with MAJOR.MINOR.BUILD. Or: start simple and apply YAGNI. -->

## Technology Stack

<!-- Name the project's core technology choices below. -->

| Layer | Technology | Purpose |
|-------|-----------|---------|
| [LAYER_1] | [TECHNOLOGY] | [PURPOSE] |
| [LAYER_2] | [TECHNOLOGY] | [PURPOSE] |

## Development Workflow

<!--
  The steps below tie the project to the specflow pipeline.
  Edit them to match the team's actual process.
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

- No code is written before a spec is approved
- Every spec goes through at least one brainstorm session
- An implementation plan must pass a constitution compliance check
- Every phase boundary needs explicit human approval

## Quality Gates

<!--
  Name the review and testing gates that apply to this project.
  The /speckit.specflow.review and /speckit.specflow.execute commands read these.
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
  Name a model class, never a specific model or agent: the class has to resolve
  on whichever agent CLI the project uses.
-->

| Stage | When it runs | Model class |
|-------|--------------|-------------|
| Pre-mortem | Before implementation starts, against plan.md | fast |
| Single reviewer | On every change | standard |
| Panel | On a change the risk rules mark high | strongest |

### Deployment Gates

- [ ] All tests pass
- [ ] All review items are resolved
- [ ] The constitution compliance check passes
- [ ] [PROJECT-SPECIFIC GATE]

## Governance

This constitution governs every development activity in the project.
An amendment requires:

- A documented rationale for the change
- Updated specs and plans
- Confirmation that no principle is violated

**Version**: [CONSTITUTION_VERSION] | **Ratified**: [RATIFICATION_DATE] | **Last Amended**: [LAST_AMENDED_DATE]

## Code Review Rules

- **Error handling**: Follow [ERROR_HANDLING_CONVENTION].
- **Test command**: Run [TEST_COMMAND] before accepting a change.
- **Forbidden dependencies**: Reject [FORBIDDEN_DEPENDENCIES].
- **Security rules**: Enforce [SECURITY_RULES].
- **Spec approved**: Require human approval before implementation. Record [SPEC_APPROVAL_EVIDENCE].
- **Merge approved**: Require human approval before merging. Record [MERGE_APPROVAL_EVIDENCE].

Test command: [TEST_COMMAND]
