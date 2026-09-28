#!/usr/bin/env python3
"""Validate extension metadata and public docs stay aligned with spec-kit.

The spec-kit catalog enforces that an extension's command and hook namespace
matches its catalog id (``speckit.<extension.id>.*``). This script
re-implements that rule statically to catch namespace and slug drift in CI
before a user fails to install from the catalog.
"""

from __future__ import annotations

import json
import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parents[1]

REQUIRED_HOOKS = ("after_tasks", "before_implement", "after_implement")

PUBLIC_DOCS = (
    "README.md",
    "SKILL.md",
    "references/superpowers-mapping.md",
    "references/workflow-guide.md",
    "templates/constitution-template.md",
    "templates/spec-template.md",
    "templates/plan-template.md",
    "templates/tasks-template.md",
    "templates/checklist-template.md",
)

# The old namespace, replaced by speckit.<extension.id>.* in every command and hook.
LEGACY_NAMESPACE = "speckit.superpowers."

DEV_INSTALL_COMMAND = "specify extension add ./specflow --dev"


class MetadataValidationError(Exception):
    """Extension metadata or a public doc fails a spec-kit alignment check."""


def read_extension_file(relative_path: str) -> str:
    """Return the text at relative_path, read relative to the extension root.

    Raises `FileNotFoundError` when relative_path does not exist.
    """
    return (ROOT / relative_path).read_text(encoding="utf-8")


def extract_extension_id(manifest: str) -> str:
    """Return the ``extension.id`` value declared in an extension.yml manifest.

    Raises `MetadataValidationError` when the manifest has no top-level
    ``extension.id`` field.
    """
    # A regex avoids a PyYAML dependency for one field.
    match = re.search(
        r"^extension:\n(?:[ \t]+.+\n)*?[ \t]+id:[ \t]*[\"']?([A-Za-z0-9_-]+)[\"']?",
        manifest,
        re.MULTILINE,
    )
    if not match:
        raise MetadataValidationError("extension.yml must declare extension.id")
    return match.group(1)


def check_hooks_declared_at_top_level(manifest: str) -> None:
    """Raise when extension.yml declares hooks in the wrong place.

    Raises `MetadataValidationError` when hooks are declared under
    provides.hooks, or no top-level hooks section exists.
    """
    if re.search(r"^provides:\n(?:  .+\n)*  hooks:", manifest, re.MULTILINE):
        raise MetadataValidationError(
            "extension.yml must not declare hooks under provides.hooks"
        )
    if not re.search(r"^hooks:\n", manifest, re.MULTILINE):
        raise MetadataValidationError("extension.yml must declare top-level hooks")


def extract_command_names(manifest: str) -> list[str]:
    """Return every provides.commands[].name value declared in the manifest.

    Raises `MetadataValidationError` when the manifest has no
    provides.commands section, or the section declares no name entries.
    """
    # Extracting the commands section first keeps template names out of the match.
    commands_section_match = re.search(
        r"^  commands:\n((?:    .+\n)*?)(?=^  \w+:|^hooks:|^$)",
        manifest,
        re.MULTILINE,
    )
    if not commands_section_match:
        raise MetadataValidationError(
            "extension.yml must declare provides.commands section"
        )

    commands_section = commands_section_match.group(1)
    command_names = re.findall(
        r"- name:[ \t]*[\"']?([^\"'\n]+)[\"']?",
        commands_section,
    )
    if not command_names:
        raise MetadataValidationError(
            "extension.yml must declare provides.commands[].name entries"
        )
    return command_names


def check_commands_use_namespace(
    command_names: list[str], namespace_prefix: str, ext_id: str
) -> None:
    """Raise when a command name does not start with namespace_prefix.

    Raises `MetadataValidationError` naming the first command outside the
    namespace.
    """
    for name in command_names:
        if not name.startswith(namespace_prefix):
            raise MetadataValidationError(
                f"command '{name}' must use namespace '{namespace_prefix}*' "
                f"(matching extension.id='{ext_id}')"
            )


def check_hooks_use_namespace(manifest: str, namespace_prefix: str, ext_id: str) -> None:
    """Raise when a required hook, or any hook command, falls outside namespace_prefix.

    Raises `MetadataValidationError` naming the unmapped required hook or the
    first offending hook command.
    """
    for hook in REQUIRED_HOOKS:
        pattern = rf"^  {hook}:\n    command:[ \t]*[\"']?{re.escape(namespace_prefix)}"
        if not re.search(pattern, manifest, re.MULTILINE):
            raise MetadataValidationError(
                f"extension.yml hook '{hook}' must map to a "
                f"'{namespace_prefix}*' command"
            )

    hook_commands = re.findall(
        r"^[ \t]+command:[ \t]*[\"']?(speckit\.[^\"'\n]+)[\"']?",
        manifest,
        re.MULTILINE,
    )
    for cmd in hook_commands:
        if not cmd.startswith(namespace_prefix):
            raise MetadataValidationError(
                f"hook command '{cmd}' must use namespace '{namespace_prefix}*' "
                f"(matching extension.id='{ext_id}')"
            )


def find_stale_command_refs(docs: tuple[str, ...]) -> list[str]:
    """Return one "path:line: text" entry per stale /specflow.* reference in docs."""
    stale_refs: list[str] = []
    for path in docs:
        text = read_extension_file(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            if re.search(r"(^|[^A-Za-z0-9_-])/specflow\.", line):
                stale_refs.append(f"{path}:{line_no}: {line.strip()}")
    return stale_refs


def find_legacy_namespace_refs(docs: tuple[str, ...], legacy_namespace: str) -> list[str]:
    """Return one "path:line: text" entry per legacy_namespace reference in docs."""
    legacy_refs: list[str] = []
    for path in docs:
        text = read_extension_file(path)
        for line_no, line in enumerate(text.splitlines(), start=1):
            if legacy_namespace in line:
                legacy_refs.append(f"{path}:{line_no}: {line.strip()}")
    return legacy_refs


def check_readme_documents_dev_install(readme: str) -> None:
    """Raise when README.md is missing the local --dev install command.

    Raises `MetadataValidationError` when DEV_INSTALL_COMMAND is absent.
    """
    if DEV_INSTALL_COMMAND not in readme:
        raise MetadataValidationError(
            "README.md must document local --dev install command"
        )


def check_readme_catalog_slug_matches(readme: str, ext_id: str) -> None:
    """Raise when README.md's catalog install slug does not equal ext_id.

    Raises `MetadataValidationError` when no catalog install command is
    documented, or a documented slug does not match ext_id.
    """
    catalog_install_slugs = re.findall(
        r"specify extension add ([A-Za-z0-9_-]+)(?!\S)",
        readme,
    )
    # The local-path and --dev installs start with '.', which no catalog slug does.
    real_slugs = [slug for slug in catalog_install_slugs if not slug.startswith(".")]
    if not real_slugs:
        raise MetadataValidationError(
            "README.md must document a catalog install command "
            "'specify extension add <slug>'"
        )
    for slug in real_slugs:
        if slug != ext_id:
            raise MetadataValidationError(
                f"README.md install command 'specify extension add {slug}' "
                f"must match extension.id='{ext_id}'"
            )


def count_declared_hooks(manifest: str) -> int:
    """Return how many hook names the top-level hooks: block declares."""
    block = re.search(r"^hooks:\n(.*?)(?=^\S|\Z)", manifest, re.S | re.M)
    if not block:
        return 0
    return len(re.findall(r"^  ([a-z_]+):", block.group(1), re.M))


def check_catalog_counts_match(ext_id: str, commands: int, hooks: int) -> None:
    """Raise when catalog.json's provides counts differ from the manifest's.

    catalog.json sits at the repository root, outside the extension payload, so
    an absent file is not an error.

    Raises `MetadataValidationError` when either count differs.
    """
    catalog_path = ROOT.parent / "catalog.json"
    if not catalog_path.exists():
        return
    catalog = json.loads(catalog_path.read_text(encoding="utf-8"))
    provides = catalog.get("extensions", {}).get(ext_id, {}).get("provides", {})
    for key, declared in (("commands", commands), ("hooks", hooks)):
        listed = provides.get(key)
        if listed != declared:
            raise MetadataValidationError(
                f"catalog.json provides.{key} is {listed}; extension.yml "
                f"declares {declared}. Edit catalog.json to match."
            )


def main() -> None:
    """Validate extension.yml and public docs against the spec-kit namespace rule.

    Raises `MetadataValidationError` when a check in the pipeline fails.
    """
    manifest = read_extension_file("extension.yml")
    check_hooks_declared_at_top_level(manifest)

    ext_id = extract_extension_id(manifest)
    namespace_prefix = f"speckit.{ext_id}."

    command_names = extract_command_names(manifest)
    check_commands_use_namespace(command_names, namespace_prefix, ext_id)
    check_hooks_use_namespace(manifest, namespace_prefix, ext_id)
    check_catalog_counts_match(
        ext_id, len(command_names), count_declared_hooks(manifest)
    )

    stale_refs = find_stale_command_refs(PUBLIC_DOCS)
    if stale_refs:
        print("Stale /specflow.* references:")
        print("\n".join(stale_refs[:50]))
        raise MetadataValidationError(
            f"found {len(stale_refs)} stale command reference(s)"
        )

    if LEGACY_NAMESPACE != namespace_prefix:
        legacy_refs = find_legacy_namespace_refs(PUBLIC_DOCS, LEGACY_NAMESPACE)
        if legacy_refs:
            print(f"Legacy '{LEGACY_NAMESPACE}*' references found:")
            print("\n".join(legacy_refs[:50]))
            raise MetadataValidationError(
                f"found {len(legacy_refs)} legacy namespace reference(s); "
                f"expected '{namespace_prefix}*'"
            )

    readme = read_extension_file("README.md")
    check_readme_documents_dev_install(readme)
    check_readme_catalog_slug_matches(readme, ext_id)

    print(f"OK: extension metadata and docs are aligned (id='{ext_id}')")


if __name__ == "__main__":
    try:
        main()
    except MetadataValidationError as error:
        print(f"FAIL: {error}")
        sys.exit(1)
