#!/bin/sh
# Pastyx — clipboard manager for macOS. One-line installer.
#
#   curl -fsSL https://raw.githubusercontent.com/leeguooooo/pastyx/main/install.sh | sh
#
# Installs the latest notarized release to /Applications and launches it.
# Free for 7 days, then a one-time license (Settings → License).
set -eu

REPO="leeguooooo/pastyx"
APP="/Applications/Pastyx.app"
LEGACY_APP="/Applications/paste.app"   # the same app before the rename
ASSET="Pastyx-macos-arm64.tar.gz"      # universal binary (Apple silicon + Intel)

[ "$(uname -s)" = "Darwin" ] || { echo "Pastyx is macOS-only."; exit 1; }
major="$(sw_vers -productVersion | cut -d. -f1)"
[ "$major" -ge 26 ] || { echo "Pastyx needs macOS 26 or newer (this Mac has $(sw_vers -productVersion))."; exit 1; }

echo "→ Finding the latest release…"
LATEST_URL="$(curl -fsSL -o /dev/null -w '%{url_effective}' "https://github.com/${REPO}/releases/latest")"
TAG="${LATEST_URL##*/}"
[ -n "$TAG" ] && [ "$TAG" != "releases" ] || { echo "✗ could not resolve latest release"; exit 1; }
BASE="https://github.com/${REPO}/releases/download/${TAG}"

TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

echo "→ Downloading Pastyx ${TAG}…"
curl -fsSL "${BASE}/${ASSET}" -o "${TMP}/${ASSET}"
curl -fsSL "${BASE}/${ASSET}.sha256" -o "${TMP}/${ASSET}.sha256"
echo "→ Verifying checksum…"
( cd "$TMP" && shasum -a 256 -c "${ASSET}.sha256" >/dev/null ) || { echo "✗ checksum mismatch"; exit 1; }

echo "→ Closing any running instance…"
osascript -e 'tell application "Pastyx" to quit' >/dev/null 2>&1 || true
osascript -e 'tell application "paste" to quit' >/dev/null 2>&1 || true
pkill -x Pastyx >/dev/null 2>&1 || true
pkill -x paste >/dev/null 2>&1 || true
sleep 1

echo "→ Installing to ${APP}…"
SUDO=""
[ -w /Applications ] || { echo "  (/Applications needs admin — you may be asked for your password)"; SUDO="sudo"; }
$SUDO rm -rf "$APP" "$LEGACY_APP"
$SUDO tar -xzf "${TMP}/${ASSET}" -C /Applications

open "$APP"

echo ""
echo "✓ Installed Pastyx ${TAG} and launched it."
echo "  • It walks you through the one permission it needs (Accessibility)."
echo "  • Press ⌘⇧V to open it. Your existing history carries over."
