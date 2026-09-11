#!/usr/bin/env python3
"""Validate a reviewer findings document against .claude/review/schema.json.

Reads the subset of JSON Schema that schema.json actually uses - type, required,
properties, items, enum, const - so the reviewer agents need no third-party
dependency to be checked in a hook or in CI.
"""

import json
import sys
from pathlib import Path

SCHEMA_PATH = Path(__file__).resolve().parent / "schema.json"

JSON_TYPES = {
    "object": dict,
    "array": list,
    "string": str,
    "number": (int, float),
    "boolean": bool,
}


class FindingsError(Exception):
    """A findings document does not match the schema. The message names the failing key."""


def validate(value, schema, path):
    """Check value against schema, raising FindingsError naming the first failing key."""
    expected_type = schema.get("type")
    if expected_type and not isinstance(value, JSON_TYPES[expected_type]):
        raise FindingsError(f"{path}: expected {expected_type}, found {type(value).__name__}")

    if "const" in schema and value != schema["const"]:
        raise FindingsError(f"{path}: expected {schema['const']!r}, found {value!r}")

    if "enum" in schema and value not in schema["enum"]:
        allowed = ", ".join(repr(option) for option in schema["enum"])
        raise FindingsError(f"{path}: {value!r} is not one of {allowed}")

    if isinstance(value, dict):
        for key in schema.get("required", []):
            if key not in value:
                raise FindingsError(f"{join(path, key)}: required key is missing")
        for key, subschema in schema.get("properties", {}).items():
            if key in value:
                validate(value[key], subschema, join(path, key))

    if isinstance(value, list) and "items" in schema:
        for index, item in enumerate(value):
            validate(item, schema["items"], f"{path}[{index}]")


def join(path, key):
    """Build the dotted key path reported in an error message."""
    return f"{path}.{key}" if path else key


def main(argv):
    if len(argv) != 2:
        print(f"usage: {Path(argv[0]).name} <findings.json>", file=sys.stderr)
        return 2
    document = json.loads(Path(argv[1]).read_text())
    schema = json.loads(SCHEMA_PATH.read_text())
    try:
        validate(document, schema, "")
    except FindingsError as error:
        print(f"{argv[1]}: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))
