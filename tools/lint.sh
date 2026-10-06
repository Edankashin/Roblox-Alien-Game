#!/usr/bin/env bash
# Extra source contracts. Each hard lint must pass; documentation audits are advisory.
set -euo pipefail
REPO="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO"
python3 -I tools/lint_strings.py
python3 -I tools/lint_remotes.py
