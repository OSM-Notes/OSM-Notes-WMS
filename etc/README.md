# Configuration Directory

This directory contains configuration files for the OSM-Notes-WMS project.

## Files

### `wms.properties.sh.example`

Template configuration file for WMS system. This file contains all configuration
options with default values and detailed comments.

**Important**: This file is tracked in Git. Create a copy for your actual
configuration:

```bash
cp etc/wms.properties.sh.example etc/wms.properties.sh
```

Then edit `wms.properties.sh` with your actual settings. The file
`wms.properties.sh` should not be committed to Git (it's in .gitignore) as it
may contain sensitive information like passwords.

### Configuration Sections

The properties file includes the following configuration sections:

- **Database Configuration**: Connection settings for PostgreSQL
- **GeoServer Configuration**: GeoServer access and workspace settings
- **WMS Service Configuration**: Service metadata and layer settings
- **Style Configuration**: SLD style file paths and names
- **Performance Configuration**: Connection pools and caching
- **Security Configuration**: Authentication and CORS settings
- **Logging Configuration**: Log levels and file management
- **Development Configuration**: Debug and development mode settings

## Environment Variables

All configuration values can be overridden using environment variables. See the
example file for variable names and usage.


