#!/usr/bin/env bash
#
# Creates a PUBLIC GitHub repo from this directory and pushes it.
# Requires the GitHub CLI:  brew install gh  &&  gh auth login
#
# Usage:
#   ./setup.sh                       # repo name defaults to gha-feature-tour
#   ./setup.sh my-repo-name
#
set -euo pipefail

REPO_NAME="${1:-gha-feature-tour}"
cd "$(dirname "$0")"

command -v gh >/dev/null || { echo "gh not found. brew install gh"; exit 1; }
gh auth status >/dev/null 2>&1 || { echo "Not logged in. Run: gh auth login"; exit 1; }

OWNER=$(gh api user --jq .login)
echo "==> Creating public repo ${OWNER}/${REPO_NAME}"

if [ ! -d .git ]; then
  git init -q -b main
fi

git add -A
git diff --cached --quiet || git commit -q -m "GitHub Actions feature tour"

# create if absent, otherwise just point at it
if gh repo view "${OWNER}/${REPO_NAME}" >/dev/null 2>&1; then
  echo "==> Repo already exists, reusing it"
  git remote remove origin 2>/dev/null || true
  git remote add origin "https://github.com/${OWNER}/${REPO_NAME}.git"
  git push -u origin main --force
else
  gh repo create "${REPO_NAME}" --public --source=. --remote=origin --push
fi

echo
echo "==> Triggering the feature tour"
sleep 3   # give GitHub a moment to register the workflows
gh workflow run "00 · Feature Tour" \
  -f target_env=production \
  -f release_name='hello world' \
  -f run_slow_tests=true \
  --repo "${OWNER}/${REPO_NAME}" || {
    echo "Manual trigger not registered yet — open the Actions tab and run it there."
  }

echo
echo "Repo:    https://github.com/${OWNER}/${REPO_NAME}"
echo "Actions: https://github.com/${OWNER}/${REPO_NAME}/actions"
echo
echo "Watch it:   gh run watch --repo ${OWNER}/${REPO_NAME}"
echo "Read logs:  gh run view --log --repo ${OWNER}/${REPO_NAME}"
