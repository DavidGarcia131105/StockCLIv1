#!/usr/bin/env bash

# Elimina el symlink instalado para el comando "stock".

set -u

INSTALL_DIR="${INSTALL_DIR:-${HOME}/.local/bin}"
TARGET_PATH="${INSTALL_DIR}/stock"

if [[ -L "$TARGET_PATH" || -f "$TARGET_PATH" ]]; then
  rm -f "$TARGET_PATH"
  printf "Eliminado: %s\n" "$TARGET_PATH"
else
  printf "No existe instalación en: %s\n" "$TARGET_PATH"
fi
