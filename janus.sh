#!/bin/bash

JANUS_BIN="${JANUS_BIN:-/opt/janus/bin/janus}"
JANUS_CFG_DIR="${JANUS_CFG_DIR:-/opt/janus/etc/janus}"

start_janus() {
    if [ ! -x "$JANUS_BIN" ]; then
        echo "Janus Binary nicht gefunden: $JANUS_BIN"
        exit 1
    fi
    if [ ! -d "$JANUS_CFG_DIR" ]; then
        echo "Janus Config-Verzeichnis nicht gefunden: $JANUS_CFG_DIR"
        exit 1
    fi
    screen -fa -S VOICESERVER -d -U -m "$JANUS_BIN" -C "$JANUS_CFG_DIR"
}

stop_janus() {
    if screen -list | grep -q "VOICESERVER"; then
        screen -S VOICESERVER -X quit
    else
        echo "VOICESERVER läuft nicht."
    fi
}

status_janus() {
    if screen -list | grep -q "VOICESERVER"; then
        echo "VOICESERVER läuft."
    else
        echo "VOICESERVER läuft nicht."
    fi
}

restart_janus() {
    stop_janus
    sleep 2
    start_janus
}

case "$1" in
    start)
        start_janus
        ;;
    stop)
        stop_janus
        ;;
    restart)
        restart_janus
        ;;
    status)
        status_janus
        ;;

    *)
        echo "Benutzung: $0 {start|stop|restart|status}"
        exit 1
        ;;
esac