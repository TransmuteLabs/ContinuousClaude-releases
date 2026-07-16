#!/usr/bin/env sh
# Continuous Claude — bootstrap installer (macOS / Linux).
#
# Downloads the self-contained `cc-setup` for the current platform from GitHub
# Release and runs `cc-setup install`. All installation logic lives inside cc-setup.
#
# Usage:
#   curl -fsSL https://raw.githubusercontent.com/<repo>/main/dist/install.sh | sh
#   # with cc-setup install arguments:
#   curl -fsSL .../install.sh | sh -s -- --autostart --add-path
#
# Environment variables:
#   CC_SETUP_REPO   — owner/repo (defaults to the public releases repo
#                     TransmuteLabs/ContinuousClaude-releases; the source repo is private).
#   CC_SETUP_VERSION — a specific tag (vX.Y.Z); defaults to latest.
set -eu

REPO="${CC_SETUP_REPO:-TransmuteLabs/ContinuousClaude-releases}"
VERSION="${CC_SETUP_VERSION:-latest}"

# ── Platform detection → target triple ──────────────────────────────
os="$(uname -s)"
arch="$(uname -m)"

case "$arch" in
  arm64|aarch64) arch="aarch64" ;;
  x86_64|amd64)  arch="x86_64" ;;
  *) echo "cc-setup: unsupported architecture: $arch" >&2; exit 1 ;;
esac

case "$os" in
  Darwin) triple="${arch}-apple-darwin" ;;
  Linux)  triple="${arch}-unknown-linux-gnu" ;;
  *) echo "cc-setup: unsupported OS: $os (use install.ps1 on Windows)" >&2; exit 1 ;;
esac

# ── cc-setup binary URL ──────────────────────────────────────────────
if [ "$VERSION" = "latest" ]; then
  base="https://github.com/${REPO}/releases/latest/download"
else
  base="https://github.com/${REPO}/releases/download/${VERSION}"
fi
url="${base}/cc-setup-${triple}"

# ── Download to a temp file ───────────────────────────────────────────
tmp="$(mktemp -d "${TMPDIR:-/tmp}/cc-setup.XXXXXX")"
bin="${tmp}/cc-setup"
trap 'rm -rf "$tmp"' EXIT

echo "cc-setup: downloading $url" >&2
if command -v curl >/dev/null 2>&1; then
  curl -fsSL "$url" -o "$bin"
elif command -v wget >/dev/null 2>&1; then
  wget -qO "$bin" "$url"
else
  echo "cc-setup: curl or wget is required" >&2; exit 1
fi
chmod +x "$bin"

# Pass the remaining arguments to `cc-setup install`.
# NOT exec: it would replace the shell process, and the EXIT trap would not fire —
# the temp directory with the binary would leak. We run it as a child and exit with
# its code (the trap cleans up $tmp). By this point cc-setup has already copied
# itself into bin_dir.
echo "cc-setup: running install ($triple)" >&2
"$bin" install "$@"
