#!/usr/bin/env bash

set -euo pipefail

INSTALL_PREFIX="${1:-/opt/janus}"
SOURCE_DIR="${2:-}"
SECRETS_FILE="${3:-$HOME/janus_opensim_secrets.env}"
AUTO_YES="${AUTO_YES:-false}"

if [[ "${1:-}" == "--yes" ]]; then
  INSTALL_PREFIX="/opt/janus"
  SOURCE_DIR="${2:-}"
  SECRETS_FILE="${3:-$HOME/janus_opensim_secrets.env}"
  AUTO_YES="true"
fi

if [[ "$AUTO_YES" != "true" ]]; then
  echo "This script removes Janus files under: $INSTALL_PREFIX"
  [[ -n "$SOURCE_DIR" ]] && echo "Source directory for make uninstall: $SOURCE_DIR"
  echo "Secrets file: $SECRETS_FILE"
  read -r -p "Continue? (yes/no): " answer
  if [[ "$answer" != "yes" ]]; then
    echo "Aborted."
    exit 0
  fi
fi

echo "Stopping Janus service (if present) ..."
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl stop janus 2>/dev/null || true
fi

echo "Stopping VOICESERVER screen session (if present) ..."
if command -v screen >/dev/null 2>&1; then
  if screen -list | grep -q "VOICESERVER"; then
    screen -S VOICESERVER -X quit || true
  fi
fi

if [[ -n "$SOURCE_DIR" && -d "$SOURCE_DIR" ]]; then
  if [[ -f "$SOURCE_DIR/Makefile" ]]; then
    echo "Running make uninstall in source directory ..."
    (cd "$SOURCE_DIR" && sudo make uninstall) || true
  fi
fi

echo "Removing installation prefix: $INSTALL_PREFIX"
sudo rm -rf "$INSTALL_PREFIX"

if [[ -f "$SECRETS_FILE" ]]; then
  echo "Removing secrets file: $SECRETS_FILE"
  rm -f "$SECRETS_FILE"
fi

echo "Janus uninstallation completed."
