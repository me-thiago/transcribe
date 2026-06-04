#!/usr/bin/env bash
#
# Instala o transcribe: symlink em ~/.local/bin, checagem de dependências
# e template de config. Idempotente — pode rodar quantas vezes quiser.

set -e

REPO_DIR=$(cd "$(dirname "$0")" && pwd)
BIN_DIR="$HOME/.local/bin"

mkdir -p "$BIN_DIR"
ln -sf "$REPO_DIR/transcribe" "$BIN_DIR/transcribe"
echo "✓ symlink: $BIN_DIR/transcribe -> $REPO_DIR/transcribe"

case ":$PATH:" in
  *":$BIN_DIR:"*) ;;
  *) echo "⚠ adicione ao seu ~/.zshrc:  export PATH=\"\$HOME/.local/bin:\$PATH\"" ;;
esac

for dep in jq ffmpeg; do
  if command -v "$dep" >/dev/null 2>&1; then
    echo "✓ $dep"
  else
    echo "⚠ $dep ausente — instale com: brew install $dep"
  fi
done

CFG="$HOME/.config/transcribe/env"
if [ -f "$CFG" ]; then
  echo "✓ config já existe: $CFG"
else
  mkdir -p "$(dirname "$CFG")"
  ( umask 177; printf 'ELEVENLABS_API_KEY=\n' >"$CFG" )
  echo "✓ template criado: $CFG — preencha sua ELEVENLABS_API_KEY"
fi

echo ""
echo "Pronto. Rode:  rehash && transcribe --help"
