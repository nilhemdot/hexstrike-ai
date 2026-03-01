#!/bin/bash
set -euo pipefail

# Only run in remote (Claude Code on the web) environments
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

cd "${CLAUDE_PROJECT_DIR:-$(pwd)}"

VENV_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}/hexstrike-env"

echo "Setting up HexStrike AI virtual environment..."

# Create venv if it doesn't exist
if [ ! -f "${VENV_DIR}/bin/activate" ]; then
  python3 -m venv "${VENV_DIR}"
fi

# Activate venv
source "${VENV_DIR}/bin/activate"

echo "Installing HexStrike AI Python dependencies..."

# Upgrade pip inside the venv to avoid system pip limitations
pip install --upgrade pip --quiet

# Install project dependencies
pip install -r requirements.txt --quiet

echo "HexStrike AI dependencies installed successfully."

# Persist venv activation for the session
if [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export PATH=\"${VENV_DIR}/bin:\$PATH\"" >> "$CLAUDE_ENV_FILE"
  echo "export VIRTUAL_ENV=\"${VENV_DIR}\"" >> "$CLAUDE_ENV_FILE"
fi
