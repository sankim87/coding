#!/bin/bash
# Download the LightCraft macOS app from GitHub releases, verify it, and install it.
#
# Usage:
#   bash install-mac.sh            # latest release
#   bash install-mac.sh 0.7.1      # a specific version
#
# The app goes to /Applications, or to ~/Applications when /Applications is not writable.
# Set LIGHTCRAFT_DEST to choose another folder. Your photo library is not touched.

set -euo pipefail

REPO="storytold/lightcraft"

if [ "$(uname -s)" != "Darwin" ]; then
  echo "This script runs on macOS only." >&2
  exit 1
fi

if [ -n "${1:-}" ]; then
  tag="v${1#v}"
else
  tag=$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" |
    sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' | head -n 1)
  if [ -z "$tag" ]; then
    echo "Could not find the latest release of $REPO." >&2
    exit 1
  fi
fi
ver="${tag#v}"
base="https://github.com/$REPO/releases/download/$tag"
dmg="lightcraft-$ver-macos-universal.dmg"

if [ -n "${LIGHTCRAFT_DEST:-}" ]; then
  dest="$LIGHTCRAFT_DEST"
elif [ -w /Applications ]; then
  dest="/Applications"
else
  dest="$HOME/Applications"
fi

work=$(mktemp -d)
mnt=""
cleanup() {
  if [ -n "$mnt" ]; then
    hdiutil detach -quiet "$mnt" 2>/dev/null || true
  fi
  rm -rf "$work"
}
trap cleanup EXIT

echo "Downloading LightCraft $ver ..."
curl -fL --progress-bar -o "$work/$dmg" "$base/$dmg"
curl -fsSL -o "$work/SHA256SUMS.txt" "$base/SHA256SUMS.txt"

echo "Checking SHA-256 ..."
expected=$(awk -v f="$dmg" '$2 == f { print $1 }' "$work/SHA256SUMS.txt")
actual=$(shasum -a 256 "$work/$dmg" | awk '{ print $1 }')
if [ -z "$expected" ] || [ "$expected" != "$actual" ]; then
  echo "Checksum mismatch for $dmg (expected '$expected', got '$actual'). Nothing was installed." >&2
  exit 1
fi

mnt="$work/mnt"
mkdir "$mnt"
hdiutil attach -quiet -nobrowse -readonly -mountpoint "$mnt" "$work/$dmg"
app=$(find "$mnt" -maxdepth 1 -name '*.app' | head -n 1)
if [ -z "$app" ]; then
  echo "No .app found in $dmg. Nothing was installed." >&2
  exit 1
fi
name=$(basename "$app")

echo "Checking signature and notarization ..."
codesign --verify --deep --strict "$app"
if ! spctl --assess --type execute "$app"; then
  echo "Gatekeeper rejected $name. Nothing was installed." >&2
  exit 1
fi

if pgrep -xq "${name%.app}"; then
  echo "${name%.app} is running. Quit it and run this script again." >&2
  exit 1
fi

mkdir -p "$dest"
if [ -d "$dest/$name" ]; then
  echo "Replacing the existing $dest/$name ..."
  rm -rf "$dest/$name"
fi
ditto "$app" "$dest/$name"

echo "Installed LightCraft $ver to $dest/$name"
echo "Open it with: open \"$dest/$name\""
