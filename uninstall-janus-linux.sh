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
  echo "Das Skript entfernt Janus-Dateien unter: $INSTALL_PREFIX"
  [[ -n "$SOURCE_DIR" ]] && echo "Source-Ordner fuer make uninstall: $SOURCE_DIR"
  echo "Secrets-Datei: $SECRETS_FILE"
  read -r -p "Fortfahren? (yes/no): " answer
  if [[ "$answer" != "yes" ]]; then
    echo "Abgebrochen."
    exit 0
  fi
fi

echo "Stoppe Janus-Dienst (falls vorhanden) ..."
if command -v systemctl >/dev/null 2>&1; then
  sudo systemctl stop janus 2>/dev/null || true
fi

echo "Stoppe VOICESERVER screen session (falls vorhanden) ..."
if command -v screen >/dev/null 2>&1; then
  if screen -list | grep -q "VOICESERVER"; then
    screen -S VOICESERVER -X quit || true
  fi
fi

if [[ -n "$SOURCE_DIR" && -d "$SOURCE_DIR" ]]; then
  if [[ -f "$SOURCE_DIR/Makefile" ]]; then
    echo "Fuehre make uninstall im Source-Ordner aus ..."
    (cd "$SOURCE_DIR" && sudo make uninstall) || true
  fi
fi

echo "Entferne Installationsprefix: $INSTALL_PREFIX"
sudo rm -rf "$INSTALL_PREFIX"

if [[ -f "$SECRETS_FILE" ]]; then
  echo "Entferne Secrets-Datei: $SECRETS_FILE"
  rm -f "$SECRETS_FILE"
fi

echo "Janus Deinstallation abgeschlossen."
