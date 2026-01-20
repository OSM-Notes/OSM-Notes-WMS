# OSM-Notes-WMS

**Web Map Service (WMS) for OpenStreetMap Notes**

This repository provides WMS (Web Map Service) layer publication for OSM notes,
allowing mappers to visualize note activity geographically in mapping
applications like JOSM or Vespucci.

> **Note:** This project was extracted from [OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion)
> to provide focused documentation and maintainability. The WMS service requires
> access to a database populated by the OSM-Notes-Ingestion project.

## Overview

This project provides a complete WMS service that displays the location of open
and closed OSM notes on a map. The service allows mappers to:

- **Visualize note activity geographically**: View all notes in an area at once
- **Identify patterns**: Notice where many notes are clustered
- **Prioritize work**: Focus on areas that need attention
- **Track progress**: See which areas have been recently worked on

### Key Features

- **Geographic Visualization**: View notes on a map with their exact locations
- **Status Differentiation**: Distinguish between open and closed notes
- **Temporal Information**: Color coding based on note age
- **Real-time Updates**: Synchronized with the main OSM notes database via triggers
- **Country-based Styling**: Different colors and shapes per country for easy identification
- **Standard Compliance**: OGC WMS 1.3.0 compliant service via GeoServer

## Architecture

```text
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   OSM Notes     │     │   PostgreSQL     │     │    GeoServer    │
│   Database      │───▶│   WMS Schema     │───▶│   WMS Service   │
│  (from Ingestion)│     │   (wms.notes_wms)│     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Triggers &    │    │   JOSM/Vespucci │
                       │   Functions     │    │   Applications  │
                       └─────────────────┘    └─────────────────┘
```

## Prerequisites

Before installing WMS, ensure you have:

1. **PostgreSQL with PostGIS**
   - Database must be populated by [OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion)
   - Access to tables: `notes`, `countries` (schema `public`)
   - PostGIS extension installed

2. **GeoServer**
   - Version 2.18+ recommended
   - REST API access enabled
   - Java Runtime Environment installed

3. **Database Access**
   - Read/write access for WMS schema installation (user with CREATE/ALTER privileges)
   - Read-only access for GeoServer (user `geoserver` recommended)

### Verifying Database Schema Compatibility

Before installing WMS, verify that your database schema matches the expected schema from OSM-Notes-Ingestion:

```bash
# Check if required columns exist in notes table
psql -d notes -c "
SELECT 
  column_name, 
  data_type 
FROM information_schema.columns 
WHERE table_name = 'notes' 
  AND column_name IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude', 'id_country')
ORDER BY column_name;
"

# Expected output should include:
# - note_id (integer or bigint)
# - created_at (timestamp or timestamp with time zone)
# - closed_at (timestamp or timestamp with time zone, nullable)
# - longitude (double precision or numeric)
# - latitude (double precision or numeric)
# - id_country (integer, nullable - optional but recommended)

# Check if countries table exists
psql -d notes -c "
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND table_name = 'countries'
);
"

# Verify PostGIS extension is installed
psql -d notes -c "SELECT PostGIS_Version();"
```

**Important:** The WMS installation script (`prepareDatabase.sql`) will automatically validate the schema and report any missing columns. If validation fails, ensure you have the correct version of OSM-Notes-Ingestion installed and that the database has been properly populated.

## Quick Start

### 1. Install WMS Database Components

```bash
# Navigate to project directory
cd OSM-Notes-WMS

# Copy and configure properties
cp etc/wms.properties.sh.example etc/wms.properties.sh
# Edit etc/wms.properties.sh with your database and GeoServer settings

# Install WMS database components (requires elevated privileges)
./bin/wms/wmsManager.sh install

# Verify installation
./bin/wms/wmsManager.sh status
```

### 2. Grant GeoServer Permissions

```bash
# Grant read-only permissions to geoserver user
psql -d notes -f sql/wms/grantGeoserverPermissions.sql
```

### 3. Configure GeoServer

```bash
# Configure GeoServer for WMS layers
./bin/wms/geoserverConfig.sh install

# Verify configuration
./bin/wms/geoserverConfig.sh status
```

### 4. Access WMS Service

- **WMS URL**: `http://localhost:8080/geoserver/wms` (or your GeoServer URL)
- **Layer Name**: `osm_notes:notes_wms_layer`
- **GetCapabilities**: `http://localhost:8080/geoserver/wms?service=WMS&version=1.1.0&request=GetCapabilities`

## Practical Examples

### Example 1: Complete Fresh Installation

```bash
# 1. Verify database schema compatibility
psql -d notes -f sql/wms/verifySchema.sql

# 2. Install WMS database components
./bin/wms/wmsManager.sh install

# 3. Grant GeoServer permissions
psql -d notes -f sql/wms/grantGeoserverPermissions.sql

# 4. Configure GeoServer
./bin/wms/geoserverConfig.sh install

# 5. Verify everything works
./bin/wms/wmsManager.sh status
./bin/wms/geoserverConfig.sh status

# 6. Test WMS service
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" | grep -i "notes"
```

### Example 2: Updating After Database Changes

```bash
# After updating notes in the ingestion database, refresh WMS views
psql -d notes -c "REFRESH MATERIALIZED VIEW CONCURRENTLY wms.disputed_and_unclaimed_areas;"

# Or use the provided script
psql -d notes -f sql/wms/refreshDisputedAreasView.sql
```

### Example 3: Troubleshooting Connection Issues

```bash
# Check if GeoServer is accessible
curl -u admin:geoserver http://localhost:8080/geoserver/rest/about/status

# Check database connection
psql -d notes -c "SELECT COUNT(*) FROM notes;"

# Verify WMS schema exists
psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"

# Check GeoServer configuration
./bin/wms/geoserverConfig.sh status
```

### Example 4: Using WMS in JOSM

1. Open JOSM
2. Go to **Imagery** → **Imagery preferences**
3. Click **Add new** → **WMS/WMTS**
4. Enter WMS URL: `http://your-server:8080/geoserver/wms`
5. Select layer: `osm_notes:notesopen` (for open notes) or `osm_notes:notesclosed` (for closed notes)
6. Click **OK** and the layer will appear in your map

### Example 5: Querying Notes via WMS GetFeatureInfo

```bash
# Get information about notes at a specific location
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=osm_notes:notesopen&QUERY_LAYERS=osm_notes:notesopen&CRS=EPSG:4326&BBOX=-74.01,40.71,-74.00,40.72&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=application/json"
```

### Example 6: Monitoring WMS Service Health

```bash
# Check if all layers are available
for layer in notesopen notesclosed countries disputedareas; do
  echo "Checking layer: $layer"
  curl -s "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:$layer&CRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=256&HEIGHT=256&FORMAT=image/png" > /dev/null && echo "✅ $layer OK" || echo "❌ $layer FAILED"
done
```

## Documentation

- **[WMS_Guide.md](./docs/WMS_Guide.md)**: Complete technical guide for administrators and developers
  - Includes [Schema Compatibility](./docs/WMS_Guide.md#schema-compatibility) section for verifying database schema
- **[WMS_User_Guide.md](./docs/WMS_User_Guide.md)**: User guide for mappers and end users - How to use WMS in JOSM/Vespucci
- **[bin/wms/README.md](./bin/wms/README.md)**: Scripts documentation
- **[sql/wms/README.md](./sql/wms/README.md)**: SQL scripts documentation
  - Includes schema verification instructions and `verifySchema.sql` script
- **[sld/README.md](./sld/README.md)**: Style files documentation

## Dependencies

### External Dependencies

- **OSM-Notes-Ingestion Database**: This project requires access to a PostgreSQL database populated by the [OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion) project
  - Schema `public`: tables `notes`, `countries`
  - This WMS project creates and manages schema `wms`

- **GeoServer**: Web map server for serving WMS layers
- **PostgreSQL with PostGIS**: Database with spatial extensions

### Project Structure

```
OSM-Notes-WMS/
├── bin/wms/              # WMS management scripts
├── sql/wms/              # SQL scripts for database setup
├── sld/                  # Style files (SLD) for map layers
├── docs/                 # Documentation
├── etc/                  # Configuration files
├── tests/                # Test suites
└── lib/osm-common/       # Common library functions (Git submodule)
```

## Configuration

Configuration is done via `etc/wms.properties.sh` (created from `etc/wms.properties.sh.example`):

- Database connection settings
- GeoServer access configuration
- WMS service metadata
- Style and layer settings

See `etc/wms.properties.sh.example` for all available options.

## Maintenance

### Refreshing Disputed Areas View

After updating countries in the ingestion database, refresh the disputed areas materialized view:

```bash
psql -d notes -f sql/wms/refreshDisputedAreasView.sql
```

Or use the SQL directly:

```sql
REFRESH MATERIALIZED VIEW CONCURRENTLY wms.disputed_and_unclaimed_areas;
```

## Uninstallation

To remove WMS components:

```bash
# Remove GeoServer configuration
./bin/wms/geoserverConfig.sh remove

# Remove WMS database components
./bin/wms/wmsManager.sh remove
```

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.

## Data License

**Important:** This repository contains only code and configuration files. All data processed by this system comes from **OpenStreetMap (OSM)** and is licensed under the **Open Database License (ODbL)**.

- **OSM Data License:** [Open Database License (ODbL)](http://opendatacommons.org/licenses/odbl/)
- **OSM Copyright:** [OpenStreetMap contributors](http://www.openstreetmap.org/copyright)

For more information about OSM licensing, see: [https://www.openstreetmap.org/copyright](https://www.openstreetmap.org/copyright)

## Contributing

Contributions are welcome! Please see the [CONTRIBUTING.md](CONTRIBUTING.md) file for guidelines.

## Author

Andres Gomez (AngocA)


