#!/usr/bin/env bash
set -euo pipefail

REPO="itential/builder-skills"
AGENTS=(github-copilot claude-code cursor codex)

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh (GitHub CLI) is required. Install: https://cli.github.com/" >&2
  exit 1
fi

if ! gh skill --help >/dev/null 2>&1; then
  echo "ERROR: your gh version does not support 'gh skill'. Update gh: https://cli.github.com/" >&2
  echo "Current version: $(gh --version | head -1)" >&2
  exit 1
fi

agent="${1:-}"
if [[ -z "${agent}" ]]; then
  echo "Select an agent:"
  select agent in "${AGENTS[@]}"; do
    [[ -n "${agent:-}" ]] && break
  done
fi

scope="${2:-project}"

echo "Installing all itential/builder-skills skills for --agent ${agent} --scope ${scope}..."
start=$(date +%s.%N)
gh skill install "${REPO}" --agent "${agent}" --scope "${scope}" --all
end=$(date +%s.%N)

elapsed=$(python3 -c "print(f'{${end} - ${start}:.2f}')")
echo "Done. Installed for ${agent} (scope: ${scope}) in ${elapsed}s."
