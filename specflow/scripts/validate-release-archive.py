#!/usr/bin/env python3
"""Validate the ZIP that spec-kit's catalog downloads.

`specify extension add specflow` downloads the catalog entry's `download_url`,
extracts the whole archive, then reads `extension.yml` from the archive root or
from its single top-level directory (spec-kit
`src/specify_cli/extensions/__init__.py`, `install_from_archive`). The extension
lives under `specflow/` here, so the archive users receive is the release asset
`specflow-vX.Y.Z.zip` that `.github/workflows/release.yml` builds with
`git archive --prefix=specflow/` from this directory. GitHub's generated tag
archive holds the whole repository and carries no `extension.yml` one level
down, so it fails install with "No extension.yml found in archive".

`git archive` applies the `export-ignore` rules in .gitattributes. The checks
below rebuild the release asset locally and measure it against the limits
spec-kit enforces in `src/specify_cli/_download_security.py` before extracting
an untrusted archive, so a regression fails CI instead of failing users at
install time (issue #6).

Usage:
    python3 scripts/validate-release-archive.py [git-ref]

Default ref is HEAD.
"""

from __future__ import annotations

import re
import subprocess
import sys
import tempfile
import zipfile
from pathlib import Path

MIB = 1024 * 1024

# The four limits mirror specify_cli._download_security in spec-kit.
MAX_DOWNLOAD_BYTES = 50 * MIB
MAX_ZIP_ENTRIES = 512
MAX_ZIP_MEMBER_BYTES = 10 * MIB
MAX_ZIP_TOTAL_BYTES = 50 * MIB

# A check fails above half of a limit, before the archive reaches the limit itself.
FAIL_RATIO = 0.5

# EXTENSION_ROOT is the archive root, not the repository root.
EXTENSION_ROOT = Path(__file__).resolve().parent.parent

# The installed extension reads each of these at runtime.
# A command or template file declared in extension.yml is checked from the manifest instead.
REQUIRED_MEMBERS = (
    "extension.yml",
    "README.md",
    "LICENSE",
    "CHANGELOG.md",
    "SKILL.md",
    # commands/*.md link to these at runtime ("See references/...").
    "references/superpowers-mapping.md",
    "references/workflow-guide.md",
    # gates/python/validate-findings.py reads this schema at runtime.
    # No provides entry declares it, so the manifest check below skips it.
    "references/findings-schema.json",
    # The gate scripts ship so a catalog install can run them (ADR-0025).
    # provides.scripts declares the same ten paths.
    # A row here also fails when extension.yml drops the matching manifest entry.
    "gates/bash/risk-classifier.sh",
    "gates/bash/merge-gate.sh",
    "gates/bash/write-marker.sh",
    "gates/bash/block-main-commit.sh",
    "gates/bash/test-gate.sh",
    "gates/bash/artifact-lint.sh",
    "gates/bash/session-start.sh",
    "gates/bash/agent-event.sh",
    "gates/python/validate-findings.py",
    "gates/python/validate-progress.py",
)

# The export-ignore rules in .gitattributes strip these prefixes and members.
EXCLUDED_PREFIXES = (
    "assets/",
    "examples/",
    "scripts/",
    ".github/",
)
EXCLUDED_MEMBERS = (
    ".gitattributes",
    ".gitignore",
)

failures: list[str] = []


def report_failure(message: str) -> None:
    """Print `message` as a failed check and append it to `failures`."""
    failures.append(message)
    print(f"  FAIL  {message}")


def report_pass(message: str) -> None:
    """Print `message` as a passed check."""
    print(f"  ok    {message}")


def format_mib(size: int) -> str:
    """Return a byte count as MiB with two decimals."""
    return f"{size / MIB:.2f} MiB"


def declared_payload_files(manifest: str) -> list[str]:
    """Return every `file:` path declared under provides in extension.yml."""
    provides = manifest.partition("\nprovides:\n")[2]
    provides = re.split(r"^\S", provides, maxsplit=1, flags=re.MULTILINE)[0]
    return re.findall(r"^\s*-?\s*file:\s*[\"']?([^\"'\n]+)[\"']?\s*$", provides, re.MULTILINE)


def check_limit(message: str, actual: int, limit: int, advice: str) -> None:
    """Report `message` as failed, near the limit, or passed, against `limit`.

    `advice` extends the near-limit failure message, after the percentage.
    """
    if actual > limit:
        report_failure(message)
    elif actual > limit * FAIL_RATIO:
        report_failure(f"{message} (over {FAIL_RATIO:.0%} of the limit{advice})")
    else:
        report_pass(message)


def build_archive(ref: str, destination: Path) -> None:
    """Write the git archive ZIP for `ref` to `destination`.

    Raises `subprocess.CalledProcessError` when git cannot archive the ref.
    """
    subprocess.run(
        ["git", "archive", "--format=zip", "--prefix=specflow/", "-o", str(destination), ref],
        cwd=EXTENSION_ROOT,
        check=True,
    )


def read_archive_manifest(archive: zipfile.ZipFile, members: dict[str, zipfile.ZipInfo]) -> str:
    """Return extension.yml's text from `archive`, or an empty string when absent.

    `git archive` applies core.autocrlf, so a Windows checkout yields CRLF
    members. GitHub's generated archive uses LF instead. The read normalizes
    line endings so a caller can compare manifest text directly.
    """
    manifest_info = members.get("extension.yml")
    if not manifest_info:
        return ""
    return archive.read(manifest_info.filename).decode("utf-8").replace("\r\n", "\n")


def check_size_limits(download_size: int, total_size: int, entry_count: int) -> None:
    """Report the download size, the uncompressed size, and the entry count against their limits."""
    check_limit(
        f"download size: {format_mib(download_size)} / {format_mib(MAX_DOWNLOAD_BYTES)}",
        download_size,
        MAX_DOWNLOAD_BYTES,
        "; slim the archive",
    )
    check_limit(
        f"uncompressed total: {format_mib(total_size)} / {format_mib(MAX_ZIP_TOTAL_BYTES)}",
        total_size,
        MAX_ZIP_TOTAL_BYTES,
        "; slim the archive",
    )
    check_limit(f"entries: {entry_count} / {MAX_ZIP_ENTRIES}", entry_count, MAX_ZIP_ENTRIES, "")


def check_member_sizes(files: dict[str, zipfile.ZipInfo]) -> None:
    """Report each member over MAX_ZIP_MEMBER_BYTES by name, or the largest member within it."""
    oversized = [
        (name, info.file_size)
        for name, info in files.items()
        if info.file_size > MAX_ZIP_MEMBER_BYTES
    ]
    if oversized:
        for name, size in oversized:
            report_failure(f"member {name} is {format_mib(size)} (limit {format_mib(MAX_ZIP_MEMBER_BYTES)})")
        return
    largest = max(files.items(), key=lambda item: item[1].file_size)
    report_pass(
        f"largest member: {largest[0]} at {format_mib(largest[1].file_size)} "
        f"/ {format_mib(MAX_ZIP_MEMBER_BYTES)}"
    )


def check_required_members(files: dict[str, zipfile.ZipInfo]) -> None:
    """Report each REQUIRED_MEMBERS entry present in `files`, or missing by name."""
    for name in REQUIRED_MEMBERS:
        if name in files:
            report_pass(name)
        else:
            report_failure(f"missing required member: {name}")


def check_declared_members(manifest: str, files: dict[str, zipfile.ZipInfo]) -> None:
    """Report extension.yml's declared payload files present in `files`, or missing by name.

    Reports a failure when `manifest` is empty. Reports another when it
    declares no payload files.
    """
    if not manifest:
        report_failure("extension.yml could not be read from the archive")
        return
    declared = declared_payload_files(manifest)
    if not declared:
        report_failure("no command/template files parsed from extension.yml provides")
    for name in declared:
        if name in files:
            report_pass(f"declared in extension.yml: {name}")
        else:
            report_failure(f"extension.yml declares '{name}' but it is not in the archive")


def check_excluded_paths(
    members: dict[str, zipfile.ZipInfo], files: dict[str, zipfile.ZipInfo]
) -> None:
    """Report each EXCLUDED_PREFIXES and EXCLUDED_MEMBERS entry absent, or shipped."""
    for prefix in EXCLUDED_PREFIXES:
        present = sorted(name for name in members if name.startswith(prefix))
        if present:
            report_failure(f"{prefix} should be export-ignored but ships {len(present)} member(s)")
        else:
            report_pass(f"{prefix} excluded")
    for name in EXCLUDED_MEMBERS:
        if name in files:
            report_failure(f"{name} should be export-ignored but is in the archive")
        else:
            report_pass(f"{name} excluded")


def main() -> int:
    """Check the archive for the ref in argv and return the exit code."""
    ref = sys.argv[1] if len(sys.argv) > 1 else "HEAD"
    print(f"Validating release archive for ref '{ref}'\n")

    with tempfile.TemporaryDirectory() as tmpdir:
        archive_path = Path(tmpdir) / "specflow.zip"
        build_archive(ref, archive_path)

        download_size = archive_path.stat().st_size
        with zipfile.ZipFile(archive_path) as archive:
            infos = archive.infolist()
            members = {
                info.filename.split("/", 1)[1]: info
                for info in infos
                if "/" in info.filename
            }
            manifest = read_archive_manifest(archive, members)

        files = {name: info for name, info in members.items() if not name.endswith("/")}
        total_size = sum(info.file_size for info in files.values())

        print("Archive limits (spec-kit _download_security):")
        check_size_limits(download_size, total_size, len(infos))
        check_member_sizes(files)

        print("\nRuntime payload present:")
        check_required_members(files)
        check_declared_members(manifest, files)

        print("\nNon-runtime paths excluded:")
        check_excluded_paths(members, files)

    print()
    if failures:
        print(f"{len(failures)} check(s) failed:")
        for failure in failures:
            print(f"  - {failure}")
        return 1
    print("Release archive is within every spec-kit install limit.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
