#!/usr/bin/env bash
set -euo pipefail

log() {
  printf '\n==> %s\n' "$1"
}

warn() {
  printf '\n[WARN] %s\n' "$1"
}

need_cmd() {
  command -v "$1" >/dev/null 2>&1 || {
    echo "Missing required command: $1" >&2
    exit 1
  }
}

log "Checking OS"
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "Detected: ${PRETTY_NAME:-unknown}"
else
  warn "/etc/os-release not found; continuing anyway"
fi

need_cmd sudo
need_cmd curl
need_cmd bash

log "Installing GitHub CLI (gh) if needed"
if ! command -v gh >/dev/null 2>&1; then
  (type -p wget >/dev/null || (sudo apt update && sudo apt install wget -y)) \
    && sudo mkdir -p -m 755 /etc/apt/keyrings \
    && out=$(mktemp) && wget -nv -O "$out" https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    && cat "$out" | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg > /dev/null \
    && sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg \
    && sudo mkdir -p -m 755 /etc/apt/sources.list.d \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null \
    && sudo apt update \
    && sudo apt install gh -y
else
  echo "gh already installed: $(gh --version | head -n 1)"
fi

log "Checking GitHub authentication"
if gh auth status >/dev/null 2>&1; then
  echo "gh auth already configured"
else
  warn "gh auth is not configured. Starting interactive login..."
  gh auth login
fi

log "Checking gh copilot availability"
if gh copilot --help >/dev/null 2>&1; then
  echo "gh copilot is available"
else
  warn "gh copilot help failed. Please check your GitHub login or Copilot availability manually."
fi

log "Installing Hermes if needed"
if ! command -v hermes >/dev/null 2>&1; then
  curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
  warn "Hermes installed. You may need to reopen your shell or run: source ~/.bashrc"
else
  echo "Hermes already installed: $(hermes --version | head -n 1)"
fi

mkdir -p "${HOME}/.hermes"

log "Writing Hermes config for GitHub Copilot provider"
python3 - <<'PY'
from pathlib import Path
cfg = Path.home() / '.hermes' / 'config.yaml'
text = cfg.read_text(encoding='utf-8') if cfg.exists() else ''
block = '''model:
  default: gpt-5.4
  api_mode: codex_responses
  provider: "copilot"

  # API configuration — GitHub Copilot
  api_key: ""
  base_url: "https://api.githubcopilot.com"
'''
if text.startswith('model:\n'):
    lines = text.splitlines(True)
    end = len(lines)
    for i in range(1, len(lines)):
        if lines[i] and not lines[i].startswith((' ', '\t')):
            end = i
            break
    new_text = block + ''.join(lines[end:])
else:
    new_text = block + ('\n' + text if text and not text.startswith('\n') else text)
cfg.write_text(new_text, encoding='utf-8')
print(f'Wrote {cfg}')
PY

log "Testing Hermes with Copilot provider"
if command -v hermes >/dev/null 2>&1; then
  env -u COPILOT_GITHUB_TOKEN -u GH_TOKEN -u GITHUB_TOKEN \
    python -m hermes_cli.main chat -q "Reply with exactly: COPILOT_OK" \
    --provider copilot --model gpt-5.4 || true
else
  warn "Hermes command not in PATH yet. Open a new shell and re-run the verification manually."
fi

log "Done"
echo "Suggested next steps:"
echo "  1) Run: hermes --version"
echo "  2) Run: hermes dashboard --no-open"
echo "  3) Open: http://127.0.0.1:9119/"
echo "  4) If you previously set GitHub token env vars by hand, ensure they do not conflict with gh auth login"
