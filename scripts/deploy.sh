#!/usr/bin/env bash
# deploy.sh — Commit codelab + push to GitHub + enable Pages on /docs of the current branch.
#
# Env vars (optional):
#   REPO_NAME    — name for the new GitHub repo if no 'origin' remote exists.
#                  Defaults to "codelab-<id>".
#   VISIBILITY   — public | private. Defaults to "public".
#   DOCS_DIR     — output directory containing <id>/index.html. Defaults to "docs".
#   BRANCH       — branch to push and configure Pages on. Defaults to current branch
#                  (or "main" if not yet on a branch).
#
# Exit codes:
#   0  success — codelab live
#   1  prereq missing (claat output not found, missing tools, etc.)
#   2  Pages config conflict — existing config differs; manual intervention needed.

set -euo pipefail

DOCS_DIR="${DOCS_DIR:-docs}"

# ---------- Prereq: built codelab exists ----------
ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo "$PWD")"
cd "$ROOT"

if ! ls "$DOCS_DIR"/*/index.html >/dev/null 2>&1; then
  echo "ERROR: No built codelab found at $DOCS_DIR/<id>/index.html"
  echo "Run first: claat export -o $DOCS_DIR codelab.md"
  exit 1
fi

CODELAB_ID="$(ls -d "$DOCS_DIR"/*/ 2>/dev/null | head -1 | xargs -n1 basename)"
echo "Codelab id: $CODELAB_ID"

# ---------- Ensure git repo ----------
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "Not inside a git repo. Initializing..."
  git init -b main
fi

BRANCH="${BRANCH:-$(git branch --show-current 2>/dev/null || echo main)}"
[ -z "$BRANCH" ] && BRANCH="main"

# ---------- Stage and commit ----------
# IMPORTANT: Only stage the codelab source and built output. Never `git add -A`
# here — this script may run from a working tree that also contains the
# codelab-publisher skill files (SKILL.md, references/, scripts/, assets/) or
# other unrelated content, and those must NOT be committed to the codelab repo.
STAGE_PATHS=()
[ -f codelab.md ] && STAGE_PATHS+=("codelab.md")
[ -d "$DOCS_DIR" ] && STAGE_PATHS+=("$DOCS_DIR")

if [ "${#STAGE_PATHS[@]}" -eq 0 ]; then
  echo "ERROR: Nothing to stage — expected codelab.md and/or $DOCS_DIR/ in $ROOT"
  exit 1
fi

git add -- "${STAGE_PATHS[@]}"
if ! git diff --cached --quiet; then
  git commit -m "Build codelab: $CODELAB_ID"
else
  echo "Nothing new to commit."
fi

# Need at least one commit before we can create/push a remote.
if ! git rev-parse HEAD >/dev/null 2>&1; then
  echo "ERROR: Repo has no commits yet. Make an initial commit and re-run."
  exit 1
fi

# ---------- Ensure 'origin' ----------
if ! git remote get-url origin >/dev/null 2>&1; then
  REPO_NAME="${REPO_NAME:-codelab-$CODELAB_ID}"
  VISIBILITY="${VISIBILITY:-public}"
  case "$VISIBILITY" in
    public|private) ;;
    *) echo "ERROR: VISIBILITY must be 'public' or 'private', got: $VISIBILITY"; exit 1 ;;
  esac

  echo "No 'origin' remote. Creating GitHub repo: $REPO_NAME ($VISIBILITY)..."
  gh repo create "$REPO_NAME" "--$VISIBILITY" --source=. --remote=origin
fi

OWNER_REPO="$(gh repo view --json nameWithOwner --jq .nameWithOwner)"
echo "Repository: $OWNER_REPO"
echo "Branch: $BRANCH"

# ---------- Push ----------
echo "Pushing to origin/$BRANCH..."
git push -u origin "$BRANCH"

# ---------- Configure Pages ----------
echo
echo "Configuring GitHub Pages..."

if gh api "repos/$OWNER_REPO/pages" >/dev/null 2>&1; then
  EXISTING_BRANCH="$(gh api "repos/$OWNER_REPO/pages" --jq '.source.branch // ""' 2>/dev/null || echo "")"
  EXISTING_PATH="$(gh api "repos/$OWNER_REPO/pages" --jq '.source.path // ""' 2>/dev/null || echo "")"
  echo "Pages already enabled: branch='$EXISTING_BRANCH' path='$EXISTING_PATH'"

  if [ "$EXISTING_BRANCH" != "$BRANCH" ] || [ "$EXISTING_PATH" != "/$DOCS_DIR" ]; then
    echo
    echo "WARNING: Pages source differs from this script's default ($BRANCH /$DOCS_DIR)."
    echo "Not changing it automatically — the existing config might be intentional."
    echo
    echo "To switch sources manually:"
    echo "  gh api -X PUT repos/$OWNER_REPO/pages -f 'source[branch]=$BRANCH' -f 'source[path]=/$DOCS_DIR'"
    echo
    echo "Proceeding with status check against the existing config."
  fi
else
  echo "Pages not yet enabled. Enabling on /$DOCS_DIR of $BRANCH..."
  gh api -X POST "repos/$OWNER_REPO/pages" \
    -f build_type=legacy \
    -f "source[branch]=$BRANCH" \
    -f "source[path]=/$DOCS_DIR" >/dev/null
  echo "Pages enabled."
fi

# ---------- Poll until built ----------
PAGES_URL="$(gh api "repos/$OWNER_REPO/pages" --jq .html_url 2>/dev/null || true)"
echo
echo "Waiting for Pages build (up to 90s)..."

BUILT=false
for i in $(seq 1 30); do
  STATUS="$(gh api "repos/$OWNER_REPO/pages" --jq .status 2>/dev/null || echo "")"
  printf "  [%2d/30] status=%s\n" "$i" "${STATUS:-?}"
  if [ "$STATUS" = "built" ]; then
    BUILT=true
    break
  fi
  sleep 3
done

echo
echo "=================================================="
if [ "$BUILT" = true ]; then
  echo "✓ Codelab live at:"
else
  echo "Codelab will be live shortly at (still building):"
fi
echo "  ${PAGES_URL}${CODELAB_ID}/"
echo "=================================================="

if [ "$BUILT" = false ]; then
  echo
  echo "If the URL 404s, wait another minute and refresh. First builds can be slow."
fi
