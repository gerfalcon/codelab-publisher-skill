#!/usr/bin/env bash
# check_prereqs.sh — Verify claat, gh, git, and gh auth state.
# Read-only. Safe to run any time.

set -uo pipefail

ok()    { printf "  \033[32m✓\033[0m %s\n" "$1"; }
miss()  { printf "  \033[31m✗\033[0m %s\n" "$1"; }
warn()  { printf "  \033[33m!\033[0m %s\n" "$1"; }

echo "Codelab Publisher — prereq check"
echo

# --- claat ---
if command -v claat >/dev/null 2>&1; then
  VERSION="$(claat version 2>&1 | head -1)"
  ok "claat installed ($VERSION)"
else
  miss "claat NOT installed — run: bash scripts/install_claat.sh"
fi

# --- gh ---
if command -v gh >/dev/null 2>&1; then
  GH_VERSION="$(gh --version 2>&1 | head -1)"
  ok "gh installed ($GH_VERSION)"
else
  miss "gh NOT installed — install: brew install gh"
fi

# --- git ---
if command -v git >/dev/null 2>&1; then
  ok "git installed ($(git --version))"
else
  miss "git NOT installed — install: brew install git (or xcode-select --install)"
fi

# --- go (optional, only used for installing claat) ---
if command -v go >/dev/null 2>&1; then
  ok "go installed ($(go version | awk '{print $3}')) — usable for installing claat"
else
  warn "go NOT installed — fine if claat is already installed; otherwise install_claat.sh will fall back to a prebuilt binary"
fi

echo
echo "Auth state:"

# --- gh auth ---
if command -v gh >/dev/null 2>&1; then
  if gh auth status >/dev/null 2>&1; then
    # Use the API to determine the currently-active user (more reliable than parsing auth status text)
    ACTIVE="$(gh api user --jq .login 2>/dev/null || echo "")"
    if [ -n "$ACTIVE" ]; then
      ok "gh authenticated (active account: $ACTIVE)"
    else
      ok "gh authenticated"
    fi
    # Warn if multiple accounts
    ACCOUNT_COUNT="$(gh auth status 2>&1 | grep -c 'Logged in to github.com' || true)"
    if [ "${ACCOUNT_COUNT:-0}" -gt 1 ]; then
      warn "Multiple gh accounts logged in — the codelab will publish under '$ACTIVE'. Switch with: gh auth switch"
    fi
  else
    miss "gh NOT authenticated — ask the user to run: ! gh auth login"
  fi
fi

# --- repo state ---
echo
echo "Repo state:"
if git rev-parse --git-dir >/dev/null 2>&1; then
  REPO_ROOT="$(git rev-parse --show-toplevel)"
  ok "Inside git repo: $REPO_ROOT"
  if git remote get-url origin >/dev/null 2>&1; then
    ok "Remote 'origin' configured: $(git remote get-url origin)"
  else
    warn "No 'origin' remote — deploy.sh will offer to create a new GitHub repo via gh"
  fi
else
  warn "Not inside a git repo — deploy.sh will run 'git init' and create a new repo"
fi

echo
echo "Done."
