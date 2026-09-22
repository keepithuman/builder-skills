#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
UPSTREAM_URL="https://github.com/itential/builder-skills.git"
UPSTREAM_BRANCH="main"
mode="rebase"

usage() {
  cat >&2 <<EOF
Usage: $(basename "$0") [--merge] [--branch <name>]

  --merge          use 'git merge' instead of 'git rebase' (default: rebase)
  --branch <name>  upstream branch to pull from (default: main)

Pulls the latest itential/builder-skills into your fork, keeping your
customizations under skills/*/custom/. Requires a clean working tree.
EOF
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --merge) mode="merge"; shift ;;
    --branch) UPSTREAM_BRANCH="$2"; shift 2 ;;
    -h|--help) usage ;;
    *) usage ;;
  esac
done

cd "${ROOT_DIR}"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "ERROR: working tree is not clean. Commit or stash your changes first." >&2
  git status --short >&2
  exit 1
fi

if ! git remote get-url upstream >/dev/null 2>&1; then
  echo "No 'upstream' remote found. Adding it: ${UPSTREAM_URL}"
  git remote add upstream "${UPSTREAM_URL}"
fi

echo "Fetching upstream/${UPSTREAM_BRANCH}..."
git fetch upstream "${UPSTREAM_BRANCH}"

echo "Applying via ${mode}..."
if [[ "${mode}" == "rebase" ]]; then
  if ! git rebase "upstream/${UPSTREAM_BRANCH}"; then
    cat >&2 <<EOF

Rebase stopped with a conflict. If your customizations only live under
skills/*/custom/, this should not happen -- itential/builder-skills
never commits to that path. A conflict means something outside
skills/*/custom/ was edited on both sides. Resolve it, then:
  git rebase --continue
and re-run this script's remaining steps manually:
  scripts/generate-vendor-wrappers.sh
  scripts/check-vendor-skills.sh
EOF
    exit 1
  fi
else
  git merge "upstream/${UPSTREAM_BRANCH}"
fi

echo "Regenerating .claude/skills, .agents/skills, .github/skills..."
"${ROOT_DIR}/scripts/generate-vendor-wrappers.sh"

echo "Validating..."
"${ROOT_DIR}/scripts/check-vendor-skills.sh"

if [[ -n "$(git status --porcelain)" ]]; then
  echo "Regeneration produced changes -- committing."
  git add .claude/skills .agents/skills .github/skills
  git commit -m "chore: regenerate vendor mirrors after upstream update"
fi

untracked_custom="$(git status --porcelain --ignored skills/*/custom 2>/dev/null | awk '{print $2}')"
if [[ -n "${untracked_custom}" ]]; then
  cat <<EOF

Note: you have custom/ files that aren't tracked by git (this is normal --
skills/*/custom/** is gitignored by default). If you want any of these
version-controlled and shared with your team, force-add them:
  git add -f <path>
See docs/customization.md (Path B) for the full workflow.
EOF
fi

echo "Done. Your fork is up to date with upstream/${UPSTREAM_BRANCH}, customizations preserved."
