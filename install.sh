#!/usr/bin/env bash

# Instala el comando "stock" en ~/.local/bin mediante un symlink hacia
# el wrapper del proyecto, evitando depender de sudo.

set -u

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
TARGET_PATH="${INSTALL_DIR}/stock"
SOURCE_PATH="${PROJECT_ROOT}/stock"

mkdir -p "$INSTALL_DIR"
ln -sfn "$SOURCE_PATH" "$TARGET_PATH"

printf "Instalado: %s -> %s\n" "$TARGET_PATH" "$SOURCE_PATH"

case ":$PATH:" in
  *":$INSTALL_DIR:"*)
    printf "El directorio %s ya esta en tu PATH.\n" "$INSTALL_DIR"
    printf "Ya puedes usar: stock help\n"
    ;;
  *)
    printf "Aviso: %s no está en tu PATH.\n" "$INSTALL_DIR"
    printf "Añade esta línea a tu ~/.zshrc o ~/.bashrc:\n"
    printf "export PATH=\"%s:\$PATH\"\n" "$INSTALL_DIR"
    printf "Después abre una nueva terminal y usa: stock help\n"
    ;;
esac
