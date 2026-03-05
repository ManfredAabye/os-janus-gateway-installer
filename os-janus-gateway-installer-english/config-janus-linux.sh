#!/usr/bin/env bash

set -euo pipefail

DEFAULT_PREFIX="/opt/janus"
DEFAULT_HTTP_PORT="8088"
DEFAULT_ADMIN_PORT="7088"
DEFAULT_RTP_RANGE="10000-10200"
DEFAULT_TOKEN_LENGTH="32"

prompt_default() {
  local text="$1"
  local def="$2"
  local value
  read -r -p "$text [$def]: " value
  if [[ -z "$value" ]]; then
    value="$def"
  fi
  printf '%s' "$value"
}

prompt_yes_no() {
  local text="$1"
  local def="$2"
  local value

  while true; do
    read -r -p "$text [$def]: " value
    if [[ -z "$value" ]]; then
      value="$def"
    fi
    case "${value,,}" in
      y|yes|j|ja|true|1) printf '%s' "true"; return ;;
      n|no|nein|false|0) printf '%s' "false"; return ;;
      *) echo "Please enter yes or no." ;;
    esac
  done
}

generate_alnum_token() {
  local length="${1:-$DEFAULT_TOKEN_LENGTH}"

  if command -v openssl >/dev/null 2>&1; then
    # Hex is 0-9a-f, so no special characters and OpenSim-compatible.
    openssl rand -hex "$((length / 2))" | cut -c1-"$length"
    return
  fi

  tr -dc 'A-Za-z0-9' </dev/urandom | head -c "$length"
}

upsert_key() {
  local file="$1"
  local key="$2"
  local value="$3"

  if grep -Eq "^[[:space:]]*;?[[:space:]]*${key}[[:space:]]*=" "$file"; then
    sudo sed -i -E "s|^[[:space:]]*;?[[:space:]]*(${key})[[:space:]]*=.*|\1 = $value|" "$file"
  else
    echo "$key = $value" | sudo tee -a "$file" >/dev/null
  fi
}

backup_file() {
  local file="$1"
  local ts
  ts="$(date +%Y%m%d-%H%M%S)"
  sudo cp "$file" "$file.bak-$ts"
}

echo "Janus configuration for OpenSim"
echo "--------------------------------"

INSTALL_PREFIX="$(prompt_default "Installation prefix" "$DEFAULT_PREFIX")"
CONF_DIR="$INSTALL_PREFIX/etc/janus"

if [[ ! -d "$CONF_DIR" ]]; then
  echo "Error: configuration directory not found: $CONF_DIR"
  exit 1
fi

JANUS_CORE_CFG="$CONF_DIR/janus.jcfg"
if [[ ! -f "$JANUS_CORE_CFG" ]]; then
  JANUS_CORE_CFG="$CONF_DIR/janus.cfg"
fi

HTTP_CFG="$CONF_DIR/janus.transport.http.jcfg"
if [[ ! -f "$HTTP_CFG" ]]; then
  HTTP_CFG="$CONF_DIR/janus.transport.http.cfg"
fi

if [[ ! -f "$JANUS_CORE_CFG" ]]; then
  echo "Error: neither janus.jcfg nor janus.cfg found in $CONF_DIR"
  exit 1
fi

if [[ ! -f "$HTTP_CFG" ]]; then
  echo "Error: HTTP transport config not found (janus.transport.http.jcfg/.cfg)"
  exit 1
fi

PUBLIC_HOST="$(prompt_default "Public hostname/IP for OpenSim (e.g. janus.example.org)" "127.0.0.1")"
HTTP_PORT="$(prompt_default "Janus HTTP port" "$DEFAULT_HTTP_PORT")"
RTP_RANGE="$(prompt_default "RTP port range (UDP)" "$DEFAULT_RTP_RANGE")"

ENABLE_ADMIN="$(prompt_yes_no "Enable Janus Admin API?" "no")"
ADMIN_PORT=""

GENERATED_API_SECRET="$(generate_alnum_token "$DEFAULT_TOKEN_LENGTH")"

API_SECRET="$(prompt_default "APIToken for OpenSim (Janus api_secret)" "$GENERATED_API_SECRET")"
while [[ -z "$API_SECRET" ]]; do
  API_SECRET="$(prompt_default "APIToken must not be empty" "$GENERATED_API_SECRET")"
done

ADMIN_SECRET=""
if [[ "$ENABLE_ADMIN" == "true" ]]; then
  ADMIN_PORT="$(prompt_default "Janus Admin port" "$DEFAULT_ADMIN_PORT")"
  GENERATED_ADMIN_SECRET="$(generate_alnum_token "$DEFAULT_TOKEN_LENGTH")"
  ADMIN_SECRET="$(prompt_default "AdminAPIToken for OpenSim (Janus admin_secret)" "$GENERATED_ADMIN_SECRET")"
  while [[ -z "$ADMIN_SECRET" ]]; do
    ADMIN_SECRET="$(prompt_default "AdminAPIToken must not be empty" "$GENERATED_ADMIN_SECRET")"
  done
fi

echo "Backing up existing configurations ..."
backup_file "$JANUS_CORE_CFG"
backup_file "$HTTP_CFG"

echo "Setting Janus core configuration ..."
upsert_key "$JANUS_CORE_CFG" "rtp_port_range" "\"$RTP_RANGE\""

echo "Setting Janus HTTP/Admin/API configuration ..."
upsert_key "$HTTP_CFG" "http" "true"
upsert_key "$HTTP_CFG" "port" "$HTTP_PORT"
upsert_key "$HTTP_CFG" "api_secret" "\"$API_SECRET\""
if [[ "$ENABLE_ADMIN" == "true" ]]; then
  upsert_key "$HTTP_CFG" "admin_http" "true"
  upsert_key "$HTTP_CFG" "admin_port" "$ADMIN_PORT"
  upsert_key "$HTTP_CFG" "admin_secret" "\"$ADMIN_SECRET\""
else
  upsert_key "$HTTP_CFG" "admin_http" "false"
fi

OPENSIM_SNIPPET_FILE="./opensim-janus-config.generated.ini"
cat > "$OPENSIM_SNIPPET_FILE" <<EOF
; ==========================================================
; OpenSim WebRTC/Janus Config
; ==========================================================

; ----------------------------
; OpenSim.ini
; ----------------------------
[WebRtcVoice]
  Enabled = true
  SpatialVoiceService = WebRtcVoice.dll:WebRtcVoiceServiceConnector
  NonSpatialVoiceService = WebRtcVoice.dll:WebRtcVoiceServiceConnector
  WebRtcVoiceServerURI = http://$PUBLIC_HOST:8003

; ----------------------------
; Robust.ini
; ----------------------------
[ServiceList]
  VoiceServiceConnector = "8000/OpenSim.Server.Handlers.dll:OpenSim.Server.Handlers.WebRtcVoiceServerConnector"

[WebRtcVoice]
  Enabled = true
  NonSpatialVoiceService = WebRtcJanusService.dll:WebRtcJanusService

[JanusWebRtcVoice]
  JanusGatewayURI = http://$PUBLIC_HOST:$HTTP_PORT/janus
  APIToken = $API_SECRET
EOF

if [[ "$ENABLE_ADMIN" == "true" ]]; then
cat >> "$OPENSIM_SNIPPET_FILE" <<EOF
  JanusGatewayAdminURI = http://$PUBLIC_HOST:$ADMIN_PORT/admin
  AdminAPIToken = $ADMIN_SECRET
EOF
fi

cat >> "$OPENSIM_SNIPPET_FILE" <<EOF
  MessageDetails = false
EOF

echo
echo "Configuration completed."
echo "Janus Core: $JANUS_CORE_CFG"
echo "Janus HTTP: $HTTP_CFG"
echo "OpenSim/Robust Snippet: $OPENSIM_SNIPPET_FILE"
echo
echo "Notes:"
if [[ "$ENABLE_ADMIN" == "true" ]]; then
  echo "- Open firewall: TCP $HTTP_PORT, TCP $ADMIN_PORT, UDP ${RTP_RANGE%-*}-${RTP_RANGE#*-}"
else
  echo "- Open firewall: TCP $HTTP_PORT, UDP ${RTP_RANGE%-*}-${RTP_RANGE#*-}"
  echo "- Admin API is disabled (admin_http = false)."
fi
echo "- Restart Janus, e.g.: sudo systemctl restart janus"
echo "- Apply the generated INI block in OpenSim."
