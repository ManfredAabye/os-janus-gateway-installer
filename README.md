# Janus Gateway Installer

Installer für Linux, um Janus Gateway vollständig zu:

- klonen
- bauen
- installieren

`https://github.com/meetecho/janus-gateway.git`

## Linux

```bash
bash install-janus-linux.sh
```

Optional mit Zielordner und Prefix:

```bash
bash install-janus-linux.sh janus-gateway-src /opt/janus
```

## Deinstallation (Ubuntu/Linux)

Standard (mit Rueckfrage, Prefix `/opt/janus`):

```bash
bash uninstall-janus-linux.sh
```

Mit Source-Ordner fuer `make uninstall`:

```bash
bash uninstall-janus-linux.sh /opt/janus /pfad/zu/janus-gateway
```

Ohne Rueckfrage:

```bash
bash uninstall-janus-linux.sh --yes /pfad/zu/janus-gateway
```

## Konfiguration fuer OpenSim (Ubuntu/Linux)

Interaktive Konfiguration von Janus fuer OpenSim inkl. Generierung eines INI-Snippets:

```bash
bash config-janus-linux.sh
```

Das Skript:

- fragt Host, Ports, RTP-Range und Secrets ab
- setzt `api_secret` und `admin_secret` in Janus
- aktiviert HTTP/Admin-Transport und setzt Ports
- setzt `rtp_port_range`
- erstellt `opensim-janus-config.generated.ini` fuer OpenSim
