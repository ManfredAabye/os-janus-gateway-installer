#!/usr/bin/env bash

set -euo pipefail

REPO_URL="https://github.com/meetecho/janus-gateway.git"
TARGET_DIR="${1:-janus-gateway}"
INSTALL_PREFIX="${2:-/opt/janus}"

if ! command -v git >/dev/null 2>&1; then
  echo "Fehler: git ist nicht installiert oder nicht im PATH."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "Fehler: sudo ist nicht installiert."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Fehler: Dieses Skript unterstützt aktuell nur Debian/Ubuntu (apt-get)."
  exit 1
fi

if [ -e "$TARGET_DIR" ]; then
  echo "Fehler: Zielpfad '$TARGET_DIR' existiert bereits."
  echo "Bitte anderen Zielordner angeben, z. B.:"
  echo "  bash install-janus-linux.sh janus-gateway-src"
  exit 1
fi

echo "Installiere Build-Abhängigkeiten ..."
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake git pkg-config automake libtool gengetopt \
  libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
  libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev \
  libwebsockets-dev libsrtp2-dev libnice-dev libsqlite3-dev

echo "Klonen von Janus Gateway nach '$TARGET_DIR' ..."
git clone "$REPO_URL" "$TARGET_DIR"

echo "Baue Janus Gateway ..."
cd "$TARGET_DIR"
sh autogen.sh
./configure --prefix="$INSTALL_PREFIX"
make -j"$(nproc)"

echo "Installiere Janus Gateway nach '$INSTALL_PREFIX' ..."
sudo make install
sudo make configs

echo "Fertig gebaut und installiert."
echo "Quellcode: $(pwd)"
echo "Prefix: $INSTALL_PREFIX"
