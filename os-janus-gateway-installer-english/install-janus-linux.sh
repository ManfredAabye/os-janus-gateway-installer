#!/usr/bin/env bash

set -euo pipefail

#REPO_URL="https://github.com/meetecho/janus-gateway.git"
REPO_URL="https://github.com/ManfredAabye/janus-gateway.git"
TARGET_DIR="${1:-janus-gateway}"
INSTALL_PREFIX="${2:-/opt/janus}"

if ! command -v git >/dev/null 2>&1; then
  echo "Error: git is not installed or not in PATH."
  exit 1
fi

if ! command -v sudo >/dev/null 2>&1; then
  echo "Error: sudo is not installed."
  exit 1
fi

if ! command -v apt-get >/dev/null 2>&1; then
  echo "Error: this script currently supports Debian/Ubuntu only (apt-get)."
  exit 1
fi

if [ -e "$TARGET_DIR" ]; then
  echo "Note: target path '$TARGET_DIR' already exists."
  while true; do
    read -r -p "Delete existing directory and clone again? (yes/no): " answer
    case "${answer,,}" in
      yes|y|ja|j)
        echo "Removing existing directory: $TARGET_DIR"
        rm -rf "$TARGET_DIR"
        break
        ;;
      no|n|nein)
        echo "Aborted."
        exit 1
        ;;
      *)
        echo "Please enter 'yes' or 'no'."
        ;;
    esac
  done
fi

echo "Installing build dependencies ..."
sudo apt-get update
sudo apt-get install -y \
  build-essential cmake git pkg-config automake libtool gengetopt \
  libmicrohttpd-dev libjansson-dev libssl-dev libsofia-sip-ua-dev libglib2.0-dev \
  libopus-dev libogg-dev libcurl4-openssl-dev liblua5.3-dev libconfig-dev \
  libwebsockets-dev libsrtp2-dev libnice-dev libsqlite3-dev

echo "Cloning Janus Gateway into '$TARGET_DIR' ..."
git clone "$REPO_URL" "$TARGET_DIR"

echo "Building Janus Gateway ..."
cd "$TARGET_DIR"
sh autogen.sh
./configure --prefix="$INSTALL_PREFIX"
make -j"$(nproc)"

echo "Installing Janus Gateway into '$INSTALL_PREFIX' ..."
sudo make install
sudo make configs

echo "Build and installation completed."
echo "Source code: $(pwd)"
echo "Prefix: $INSTALL_PREFIX"
