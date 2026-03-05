# Janus Gateway Installer

Linux installer to fully:

- clone
- build
- install

`https://github.com/meetecho/janus-gateway.git`

## Linux

```bash
bash install-janus-linux.sh
```

Optional with target directory and prefix:
Optional with target directory and prefix:

```bash
bash install-janus-linux.sh janus-gateway-src /opt/janus
```

## Uninstall (Ubuntu/Linux)

Default (with confirmation, prefix `/opt/janus`):

```bash
bash uninstall-janus-linux.sh
```

With source directory for `make uninstall`:

```bash
bash uninstall-janus-linux.sh /opt/janus /pfad/zu/janus-gateway
```

Without confirmation:

```bash
bash uninstall-janus-linux.sh --yes /pfad/zu/janus-gateway
```

## Configuration for OpenSim (Ubuntu/Linux)

Interactive Janus configuration for OpenSim, including generation of an INI snippet:

```bash
bash config-janus-linux.sh
```

The script:

- asks for host, ports, RTP range, and secrets
- sets `api_secret` and `admin_secret` in Janus
- enables HTTP/Admin transport and sets ports
- sets `rtp_port_range`
- creates `opensim-janus-config.generated.ini` for OpenSim
