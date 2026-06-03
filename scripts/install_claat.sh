#!/usr/bin/env bash
# install_claat.sh — Install the claat CLI.
# Tries `go install` first, falls back to a prebuilt binary from the releases page.

set -euo pipefail

if command -v claat >/dev/null 2>&1; then
  echo "claat is already installed:"
  claat version 2>&1 | head -1
  exit 0
fi

echo "claat not found. Attempting to install..."
echo

# --- Path 1: go install ---
if command -v go >/dev/null 2>&1; then
  echo "Found Go toolchain. Running: go install github.com/googlecodelabs/tools/claat@latest"
  go install github.com/googlecodelabs/tools/claat@latest

  GOBIN="$(go env GOBIN 2>/dev/null || true)"
  [ -z "$GOBIN" ] && GOBIN="$(go env GOPATH 2>/dev/null)/bin"

  echo
  echo "Installed to: $GOBIN/claat"

  if [[ ":$PATH:" != *":$GOBIN:"* ]]; then
    echo
    echo "⚠  $GOBIN is not on your PATH. Add this to your shell profile:"
    echo "    export PATH=\"\$PATH:$GOBIN\""
    echo
    echo "Or, for this session only:"
    echo "    export PATH=\"\$PATH:$GOBIN\""
  fi

  if [ -x "$GOBIN/claat" ]; then
    echo
    "$GOBIN/claat" version 2>&1 | head -1
  fi
  exit 0
fi

# --- Path 2: prebuilt binary ---
echo "Go not installed. Falling back to prebuilt binary download."

OS="$(uname -s | tr '[:upper:]' '[:lower:]')"
ARCH_RAW="$(uname -m)"
case "$ARCH_RAW" in
  arm64|aarch64) ARCH="arm64" ;;
  x86_64|amd64)  ARCH="amd64" ;;
  *) echo "Unsupported architecture: $ARCH_RAW"; exit 1 ;;
esac

echo "Detected platform: $OS-$ARCH"

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: gh CLI required to fetch release metadata. Install gh first (brew install gh) or install Go (brew install go) and re-run."
  exit 1
fi

echo "Looking up latest claat release..."
ASSET_URL="$(gh api repos/googlecodelabs/tools/releases/latest \
  --jq ".assets[] | select(.name | test(\"$OS.*$ARCH\")) | .browser_download_url" 2>/dev/null | head -1 || true)"

# Apple Silicon fallback: claat only ships darwin-amd64, which works under Rosetta 2.
if [ -z "$ASSET_URL" ] && [ "$OS" = "darwin" ] && [ "$ARCH" = "arm64" ]; then
  echo "No darwin-arm64 binary published. Falling back to darwin-amd64 (requires Rosetta 2)."
  ASSET_URL="$(gh api repos/googlecodelabs/tools/releases/latest \
    --jq '.assets[] | select(.name == "claat-darwin-amd64") | .browser_download_url' 2>/dev/null | head -1 || true)"
  if [ -n "$ASSET_URL" ] && ! arch -x86_64 true >/dev/null 2>&1; then
    echo
    echo "WARNING: Rosetta 2 is not installed. The amd64 binary will not run."
    echo "Install Rosetta with:  softwareupdate --install-rosetta --agree-to-license"
    echo "Or (better) install Go and re-run:  brew install go && bash scripts/install_claat.sh"
    exit 1
  fi
fi

if [ -z "$ASSET_URL" ]; then
  echo
  echo "ERROR: Could not find a prebuilt binary for $OS-$ARCH at"
  echo "  https://github.com/googlecodelabs/tools/releases/latest"
  echo
  echo "Options:"
  echo "  1. Install Go and re-run this script: brew install go && bash scripts/install_claat.sh"
  echo "  2. Manually download from https://github.com/googlecodelabs/tools/releases/latest"
  exit 1
fi

echo "Downloading: $ASSET_URL"
TMP="$(mktemp)"
curl -fSL "$ASSET_URL" -o "$TMP"
chmod +x "$TMP"

# Try to install to /usr/local/bin first, fall back to ~/bin
INSTALL_DIR="/usr/local/bin"
if [ ! -w "$INSTALL_DIR" ]; then
  echo
  echo "$INSTALL_DIR is not writable. Trying ~/bin instead."
  INSTALL_DIR="$HOME/bin"
  mkdir -p "$INSTALL_DIR"
fi

mv "$TMP" "$INSTALL_DIR/claat"
echo
echo "Installed to: $INSTALL_DIR/claat"

if [[ ":$PATH:" != *":$INSTALL_DIR:"* ]]; then
  echo
  echo "⚠  $INSTALL_DIR is not on your PATH. Add this to your shell profile:"
  echo "    export PATH=\"\$PATH:$INSTALL_DIR\""
fi

echo
"$INSTALL_DIR/claat" version 2>&1 | head -1
