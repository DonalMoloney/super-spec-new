# mutation-gate-sample

This directory is a small Python project for `.claude/hooks/mutation-gate.sh` to run
on. The repository itself holds no application code, so the gate needs a consuming
project to mutate. `pricing.py` holds three pure functions with branches, and
`tests/test_pricing.py` holds a test per branch, so mutmut kills every mutant. The
`[tool.mutmut]` table in `pyproject.toml` names the file to mutate and the test
directory. `examples/` is export-ignored in `specflow/.gitattributes`, so nothing
here ships in the extension archive.

Run the gate from the repository root. It needs jq on `PATH`, plus mutmut 3 and
pytest, both listed in `requirements-dev.txt`:

```bash
python3 -m pip install -r requirements-dev.txt
bash .claude/hooks/mutation-gate.sh specflow/examples/mutation-gate-sample
```

The gate prints one line ending in `23 of 23 mutants killed.` and exits 0. To see it
block, set `MUTATION_THRESHOLD=100`, delete one assertion from the test file, and run
it again: the score drops to 95% and the exit code is 1. The hook tests in
`.claude/hooks/tests/run.sh` run both cases.

To watch mutmut itself, run it inside this directory:

```bash
cd specflow/examples/mutation-gate-sample
mutmut run
mutmut results
```

`mutmut run` writes its cache to `mutants/`, which the root `.gitignore` excludes.
`mutmut results` lists every mutant that survived; an empty list is the expected
result.
