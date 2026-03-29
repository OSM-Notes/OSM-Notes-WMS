# Configuration Directory

Configuration for the OSM-Notes-WMS project.

## Files

### `wms.properties.sh.example` (minimal)

Variables **used by** `bin/wms/wmsManager.sh` and `bin/wms/geoserverConfig.sh`: database,
GeoServer REST, layer metadata, bbox, SLD paths. Start here for a normal install.

```bash
cp etc/wms.properties.sh.example etc/wms.properties.sh
chmod 600 etc/wms.properties.sh
vi etc/wms.properties.sh
```

### `wms.properties.extras.sh.example` (optional)

Extra variables **not** consumed by `bin/wms/*.sh` (documentation SQL strings, service metadata,
cache/log placeholders, etc.). Only if you need them exported for other tooling:

```bash
cp etc/wms.properties.extras.sh.example etc/wms.properties.extras.sh
chmod 600 etc/wms.properties.extras.sh
```

In `wms.properties.sh`, uncomment the block that sources `etc/wms.properties.extras.sh` so
`__export_wms_properties_extras` runs after the minimal exports.

### Optional `etc/properties.sh` (manual)

You may create `etc/properties.sh` yourself with `DBNAME`, `DB_USER`, `DB_PASSWORD`, `DB_HOST`,
`DB_PORT` if you share the same pattern as other OSM-Notes components. There is **no** tracked
template in this repository. `wmsManager.sh` and `geoserverConfig.sh` source it when the file exists.
`WMS_*` in `wms.properties.sh` override those defaults.

### `wms.properties.sh_local` (optional)

Additional overrides loaded **last** by `geoserverConfig.sh` only. Useful for secrets on a server.

## Security

- Do not commit `wms.properties.sh`, `wms.properties.extras.sh`, or `properties.sh` (see `.gitignore`).
- Use `chmod 600` on local config files.

## Environment

All values can still be overridden with environment variables before running scripts.
