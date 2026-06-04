#!/usr/bin/env bash
#
# Installs transcribe + dictate: symlinks into ~/.local/bin, checks dependencies
# and scaffolds a config template. Idempotent — safe to run any number of times.

set -e

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
for cmd in transcribe dictate; do
  ln -sf "$REPO_DIR/$cmd" "$BIN_DIR/$cmd"
  echo "✓ symlink: $BIN_DIR/$cmd -> $REPO_DIR/$cmd"
done

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "⚠ add to your ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

for dep in jq ffmpeg; do
  if command -v "$dep" >/dev/null 2>&1; then
    echo "✓ $dep"
  else
    echo "⚠ $dep missing — install with: brew install $dep"
  fi
done

CFG="$HOME/.config/transcribe/env"
if [ -f "$CFG" ]; then
  echo "✓ config already exists: $CFG"
else
  mkdir -p "$(dirname "$CFG")"
  ( umask 177; printf 'ELEVENLABS_API_KEY=\n' >"$CFG" )
  echo "✓ template created: $CFG — fill in your ELEVENLABS_API_KEY"
fi

echo ""
echo "Done. Run:  rehash && transcribe --help"
