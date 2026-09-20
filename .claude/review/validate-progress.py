#!/usr/bin/env python3
"""Run the shipped progress validator under specflow/gates/python/ (ADR-0025)."""

import os
import sys
from pathlib import Path

GATE = Path(__file__).resolve().parents[2] / "specflow" / "gates" / "python" / "validate-progress.py"

os.execv(sys.executable, [sys.executable, str(GATE), *sys.argv[1:]])
