# WMS (Web Map Service) Guide

## Documentation Index

This is the complete WMS documentation guide for system administrators and developers. For end users:

- **[WMS_User_Guide.md](./WMS_User_Guide.md)**: User guide for mappers and end users - How to use WMS in JOSM/Vespucci

## Overview

The WMS (Web Map Service) project provides a map service that displays the
location of open and closed OSM notes. This
service allows mappers to visualize note activity geographically, helping
identify areas that need attention or have been recently processed.

### What is WMS?

WMS (Web Map Service) is an OGC (Open Geospatial Consortium) standard that
provides map images over the internet. In our context, it serves OSM notes as
map layers that can be viewed in mapping applications like JOSM or Vespucci.

### Key Features

- **Geographic Visualization**: View notes on a map with their exact locations
- **Status Differentiation**: Distinguish between open and closed notes
- **Temporal Information**: Color coding based on note age
- **Real-time Updates**: Synchronized with the main OSM notes database
- **Standard Compliance**: OGC WMS 1.3.0 compliant service

### Architecture Overview

```text
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│   OSM Notes     │     │   PostgreSQL     │     │    GeoServer    │
│   Database      │───▶│   WMS Schema     │───▶│   WMS Service   │
│                 │     │   (wms.notes_wms)│     │                 │
└─────────────────┘     └──────────────────┘     └─────────────────┘
                                │                       │
                                ▼                       ▼
                       ┌─────────────────┐    ┌─────────────────┐
                       │   Triggers &    │    │   JOSM/Vespucci │
                       │   Functions     │    │   Applications  │
                       └─────────────────┘    └─────────────────┘
```

### Data Flow Diagram

```text
┌─────────────────────────────────────────────────────────────────┐
│                    OSM Notes Ingestion Process                    │
│  (OSM-Notes-Ingestion project populates public.notes table)     │
└────────────────────────────┬────────────────────────────────────┘
                             │
                             ▼
                    ┌─────────────────┐
                    │  public.notes   │  ← Source table with note_id,
                    │  public.countries│    longitude, latitude, etc.
                    └────────┬─────────┘
                             │
                             │ Trigger: wms.insert_new_notes()
                             ▼
                    ┌─────────────────┐
                    │  wms.notes_wms  │  ← Materialized table with
                    │                  │    PostGIS geometry column
                    └────────┬─────────┘
                             │
                             │ Materialized Views
                             ▼
        ┌────────────────────────────────────────────┐
        │  wms.notes_open_view                        │
        │  wms.notes_closed_view                      │  ← Views with calculated
        │  wms.disputed_areas_view                    │    fields (age, etc.)
        └────────┬────────────────────────────────────┘
                 │
                 │ GeoServer REST API
                 ▼
        ┌─────────────────┐
        │   GeoServer     │  ← Creates feature types and layers
        │   Datastore     │    from PostgreSQL views
        └────────┬─────────┘
                 │
                 │ WMS Protocol (HTTP)
                 ▼
        ┌─────────────────┐
        │  WMS Clients    │  ← JOSM, Vespucci, web maps
        │  (JOSM/Vespucci)│
        └─────────────────┘
```

### Installation Process Flow

```text
┌─────────────────────────────────────────────────────────────────┐
│                        Installation Flow                         │
└─────────────────────────────────────────────────────────────────┘

Step 1: Schema Verification
    │
    ├─▶ Run verifySchema.sql
    │   ├─▶ Check PostGIS extension ✅
    │   ├─▶ Verify notes table exists ✅
    │   ├─▶ Validate required columns ✅
    │   └─▶ Check countries table ✅
    │
    ▼
Step 2: Database Setup
    │
    ├─▶ Run wmsManager.sh install
    │   ├─▶ Create wms schema
    │   ├─▶ Create wms.notes_wms table
    │   ├─▶ Create materialized views
    │   ├─▶ Create triggers for sync
    │   └─▶ Populate initial data
    │
    ▼
Step 3: GeoServer Configuration
    │
    ├─▶ Run geoserverConfig.sh install
    │   ├─▶ Create workspace
    │   ├─▶ Create datastore
    │   ├─▶ Upload SLD styles
    │   ├─▶ Create feature types
    │   ├─▶ Create layers
    │   └─▶ Assign styles to layers
    │
    ▼
Step 4: Verification
    │
    ├─▶ Check WMS service
    │   ├─▶ GetCapabilities request
    │   ├─▶ GetMap request
    │   └─▶ Verify layers visible
    │
    └─▶ ✅ Installation Complete
```

### Component Interaction Diagram

```text
┌──────────────────────────────────────────────────────────────────┐
│                    Component Interaction                         │
└──────────────────────────────────────────────────────────────────┘

┌──────────────┐         ┌──────────────┐         ┌──────────────┐
│   wmsManager │────────▶│  PostgreSQL  │◀────────│  GeoServer   │
│     .sh      │  SQL    │   Database   │  Query  │   Config     │
└──────────────┘         └──────┬───────┘         └──────┬───────┘
                                │                        │
                                │                        │
                    ┌───────────▼───────────┐            │
                    │                       │            │
                    │  ┌─────────────────┐  │            │
                    │  │  wms schema     │  │            │
                    │  │  - notes_wms    │  │            │
                    │  │  - views        │  │            │
                    │  │  - triggers     │  │            │
                    │  └─────────────────┘  │            │
                    │                       │            │
                    │  ┌─────────────────┐  │            │
                    │  │  public schema   │  │            │
                    │  │  - notes        │  │            │
                    │  │  - countries    │  │            │
                    │  └─────────────────┘  │            │
                    │                       │            │
                    └───────────────────────┘            │
                                                          │
                                                          │
                    ┌─────────────────────────────────────▼──────┐
                    │                                           │
                    │  ┌─────────────────────────────────────┐  │
                    │  │  GeoServer Workspace: osm_notes     │  │
                    │  │  - Datastore: notes_wms             │  │
                    │  │  - Layers:                          │  │
                    │  │    • notesopen                      │  │
                    │  │    • notesclosed                    │  │
                    │  │    • countries                      │  │
                    │  │    • disputedareas                  │  │
                    │  │  - Styles: SLD files               │  │
                    │  └─────────────────────────────────────┘  │
                    │                                           │
                    └───────────────────────────────────────────┘
```

## Installation & Setup

### Prerequisites

Before installing WMS, ensure you have:

1. **PostgreSQL with PostGIS**

   ```bash
   # Ubuntu/Debian
   sudo apt-get install postgresql postgis
   
   # CentOS/RHEL
   sudo yum install postgresql postgis
   ```

2. **GeoServer**

   ```bash
   # Download from https://geoserver.org/download/
   # Or use Docker
   docker run -p 8080:8080 kartoza/geoserver
   ```

3. **Java Runtime Environment**

   ```bash
   # Required for GeoServer
   java -version
   ```

4. **OSM-Notes-Ingestion Database**
   - Main database must be populated with notes data
   - API or Planet processing should be completed
   - Database schema must match the expected schema (see [Schema Compatibility](#schema-compatibility) below)

### Installation Steps

#### Step 1: Install WMS Database Components

```bash
# Navigate to project directory
cd OSM-Notes-WMS

# Install WMS database components
./bin/wms/wmsManager.sh install

# Verify installation
./bin/wms/wmsManager.sh status
```

#### Step 2: Configure GeoServer

```bash
# Configure GeoServer for WMS
./bin/wms/geoserverConfig.sh install

# Verify configuration
./bin/wms/geoserverConfig.sh status
```

#### Step 3: Verify Setup

```bash
# Test WMS service
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities"

# Check layer availability
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:notes_wms_layer&STYLES=&CRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=256&HEIGHT=256&FORMAT=image/png"
```

### Quick Setup (Automated)

For a complete automated setup:

```bash
# Run complete WMS setup
./bin/wms/wmsManager.sh install && \
./bin/wms/geoserverConfig.sh install

# Verify everything is working
./bin/wms/wmsManager.sh status && \
./bin/wms/geoserverConfig.sh status
```

## Schema Compatibility

### Verifying Database Schema Compatibility

Before installing WMS, it's important to verify that your database schema matches the expected schema from OSM-Notes-Ingestion. The WMS project requires specific columns and tables to function correctly.

#### Required Schema Elements

The `notes` table must have the following columns:

| Column Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `note_id` | INTEGER or BIGINT | Yes | Unique identifier for the note |
| `created_at` | TIMESTAMP or TIMESTAMPTZ | Yes | When the note was created |
| `closed_at` | TIMESTAMP or TIMESTAMPTZ | No | When the note was closed (NULL if open) |
| `longitude` | DOUBLE PRECISION or NUMERIC | Yes | Longitude coordinate |
| `latitude` | DOUBLE PRECISION or NUMERIC | Yes | Latitude coordinate |
| `id_country` | INTEGER | No | Country ID (optional, but recommended for country-based styling) |

The `countries` table must exist in the `public` schema:

| Column Name | Data Type | Required | Description |
|------------|-----------|----------|-------------|
| `country_id` | INTEGER | Yes | Unique identifier for the country |
| `country_name` | VARCHAR or TEXT | Yes | Country name |
| `country_name_en` | VARCHAR or TEXT | No | English country name |
| `geom` | GEOMETRY | Yes | Country boundary geometry (PostGIS) |

#### Automated Schema Verification Script

For convenience, a verification script is provided:

```bash
# Run the schema verification script
psql -d notes -f sql/wms/verifySchema.sql
```

This script will:
- ✅ Check PostGIS extension installation
- ✅ Verify `notes` table exists
- ✅ Validate all required columns are present
- ✅ Check `countries` table exists
- ✅ Verify data is available
- ✅ Provide a summary report

The script will exit with an error code if any required elements are missing, making it suitable for use in automated checks and CI/CD pipelines.

#### Manual Verification

You can also verify the schema manually:

```bash
# Check required columns in notes table
psql -d notes -c "
SELECT column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'notes' 
  AND column_name IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude', 'id_country')
ORDER BY column_name;
"

# Verify countries table exists
psql -d notes -c "
SELECT EXISTS (
  SELECT 1 FROM information_schema.tables 
  WHERE table_schema = 'public' 
    AND table_name = 'countries'
);
"

# Check PostGIS version
psql -d notes -c "SELECT PostGIS_Version();"

# Verify data exists
psql -d notes -c "SELECT COUNT(*) FROM notes;"
psql -d notes -c "SELECT COUNT(*) FROM countries;"
```

#### Automatic Validation During Installation

The WMS installation script (`prepareDatabase.sql`) automatically validates the schema during installation:

- ✅ Checks for PostGIS extension
- ✅ Validates required columns in `notes` table
- ✅ Warns if `id_country` column is missing (optional but recommended)
- ✅ Checks for `countries` table existence

If validation fails, the installation will stop with a clear error message indicating what's missing.

#### Troubleshooting Schema Issues

**Problem:** Missing columns error during installation

**Solution:**
1. Verify you have the correct version of OSM-Notes-Ingestion installed
2. Ensure the database has been populated by running the ingestion process
3. Check the OSM-Notes-Ingestion documentation for the current schema version
4. If using an older version, consider upgrading OSM-Notes-Ingestion

**Problem:** Column names don't match (e.g., `lon`/`lat` instead of `longitude`/`latitude`)

**Solution:**
- The WMS project requires the exact schema as defined by OSM-Notes-Ingestion
- Ensure you're using the standard schema with `longitude`/`latitude` column names
- If your database uses different column names, you may need to migrate or update OSM-Notes-Ingestion

**Problem:** Countries table missing

**Solution:**
- Run the country assignment process in OSM-Notes-Ingestion
- The `countries` table is required for disputed areas view and country-based styling

#### Version Compatibility

The WMS project is designed to work with the current schema version of OSM-Notes-Ingestion. If you encounter schema compatibility issues:

1. **Check OSM-Notes-Ingestion version**: Ensure you're using a compatible version
2. **Review changelog**: Check if there have been recent schema changes in OSM-Notes-Ingestion
3. **Update if needed**: Upgrade OSM-Notes-Ingestion to the latest version if your version is outdated

For the latest schema requirements, refer to the [OSM-Notes-Ingestion documentation](https://github.com/OSM-Notes/OSM-Notes-Ingestion).

## Practical Examples

### Example 1: Complete Installation Workflow

```bash
#!/bin/bash
# Complete WMS installation script

set -e  # Exit on error

# Step 1: Verify schema compatibility
echo "Step 1: Verifying database schema..."
psql -d notes -f sql/wms/verifySchema.sql || {
    echo "ERROR: Schema verification failed. Please check your database."
    exit 1
}

# Step 2: Install WMS database components
echo "Step 2: Installing WMS database components..."
./bin/wms/wmsManager.sh install || {
    echo "ERROR: WMS installation failed."
    exit 1
}

# Step 3: Grant GeoServer permissions
echo "Step 3: Granting GeoServer permissions..."
psql -d notes -f sql/wms/grantGeoserverPermissions.sql || {
    echo "ERROR: Failed to grant permissions."
    exit 1
}

# Step 4: Configure GeoServer
echo "Step 4: Configuring GeoServer..."
./bin/wms/geoserverConfig.sh install || {
    echo "ERROR: GeoServer configuration failed."
    exit 1
}

# Step 5: Verify installation
echo "Step 5: Verifying installation..."
./bin/wms/wmsManager.sh status
./bin/wms/geoserverConfig.sh status

echo "✅ Installation completed successfully!"
```

### Example 2: Monitoring and Health Checks

```bash
#!/bin/bash
# WMS health check script

GEOSERVER_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASSWORD="${GEOSERVER_PASSWORD:-geoserver}"

echo "=== WMS Health Check ==="
echo ""

# Check GeoServer accessibility
echo "1. Checking GeoServer accessibility..."
if curl -s -f -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   "${GEOSERVER_URL}/rest/about/status" > /dev/null; then
    echo "   ✅ GeoServer is accessible"
else
    echo "   ❌ GeoServer is not accessible"
    exit 1
fi

# Check database connection
echo "2. Checking database connection..."
if psql -d notes -c "SELECT 1;" > /dev/null 2>&1; then
    echo "   ✅ Database connection OK"
else
    echo "   ❌ Database connection failed"
    exit 1
fi

# Check WMS schema
echo "3. Checking WMS schema..."
if psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;" > /dev/null 2>&1; then
    NOTE_COUNT=$(psql -d notes -t -c "SELECT COUNT(*) FROM wms.notes_wms;")
    echo "   ✅ WMS schema exists (${NOTE_COUNT} notes)"
else
    echo "   ❌ WMS schema not found"
    exit 1
fi

# Check WMS layers
echo "4. Checking WMS layers..."
LAYERS=("notesopen" "notesclosed" "countries" "disputedareas")
for layer in "${LAYERS[@]}"; do
    if curl -s -f -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
       "${GEOSERVER_URL}/rest/layers/osm_notes:${layer}" > /dev/null; then
        echo "   ✅ Layer '${layer}' exists"
    else
        echo "   ❌ Layer '${layer}' not found"
    fi
done

echo ""
echo "=== Health Check Complete ==="
```

### Example 3: Troubleshooting Common Issues

#### Issue: GeoServer cannot connect to database

```bash
# Check database connectivity from GeoServer host
psql -h localhost -U geoserver -d notes -c "SELECT 1;"

# Verify GeoServer datastore configuration
curl -u admin:geoserver \
  "http://localhost:8080/geoserver/rest/workspaces/osm_notes/datastores/notes_wms.json" | jq

# Test connection manually
psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"
```

#### Issue: Layers not appearing in GetCapabilities

```bash
# Check if layers exist in GeoServer
curl -u admin:geoserver \
  "http://localhost:8080/geoserver/rest/layers.json" | jq '.layers.layer[] | select(.name | startswith("osm_notes"))'

# Verify layer is enabled
curl -u admin:geoserver \
  "http://localhost:8080/geoserver/rest/layers/osm_notes:notesopen.json" | jq '.layer.enabled'

# Recreate layer if needed
./bin/wms/geoserverConfig.sh remove
./bin/wms/geoserverConfig.sh install
```

#### Issue: Styles not applying correctly

```bash
# Check if styles are uploaded
curl -u admin:geoserver \
  "http://localhost:8080/geoserver/rest/styles.json" | jq '.styles.style[] | .name'

# Verify style is assigned to layer
curl -u admin:geoserver \
  "http://localhost:8080/geoserver/rest/layers/osm_notes:notesopen.json" | jq '.layer.defaultStyle.name'

# Re-upload styles
./bin/wms/geoserverConfig.sh remove
./bin/wms/geoserverConfig.sh install
```

### Example 4: Automated Refresh After Data Updates

```bash
#!/bin/bash
# Refresh WMS views after notes update

# Refresh disputed areas view (most common update)
psql -d notes -c "REFRESH MATERIALIZED VIEW CONCURRENTLY wms.disputed_and_unclaimed_areas;"

# If notes table was updated, refresh notes_wms
# Note: This is usually handled automatically by triggers, but can be done manually:
psql -d notes -c "
  REFRESH MATERIALIZED VIEW CONCURRENTLY wms.notes_open_view;
  REFRESH MATERIALIZED VIEW CONCURRENTLY wms.notes_closed_view;
"

# Verify refresh
psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"
```

### Example 5: Querying Notes via WMS

```bash
# Get all open notes in a bounding box (New York area)
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:notesopen&STYLES=&CRS=EPSG:4326&BBOX=-74.1,40.6,-73.9,40.8&WIDTH=1024&HEIGHT=1024&FORMAT=image/png" -o notes_map.png

# Get feature info for a specific point
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=osm_notes:notesopen&QUERY_LAYERS=osm_notes:notesopen&CRS=EPSG:4326&BBOX=-74.01,40.71,-74.00,40.72&WIDTH=256&HEIGHT=256&I=128&J=128&INFO_FORMAT=application/json" | jq

# Get capabilities (list all available layers)
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" | grep -i "name>" | grep "osm_notes"
```

## Configuration

### WMS Properties File

The WMS system uses a centralized configuration file: `etc/wms.properties.sh`

**Important**: This file is not tracked in Git for security reasons. You must
create it from the example file:

```bash
# Copy the example file
cp etc/wms.properties.sh.example etc/wms.properties.sh

# Edit with your credentials and settings
vi etc/wms.properties.sh
```

The example file contains default values and detailed comments. Replace the
example values with your actual configuration.

#### Key Configuration Sections

1. **Database Configuration**

   ```bash
   WMS_DBNAME="notes"
   WMS_DBUSER="postgres"    # WMS-specific database user
   WMS_DBHOST="localhost"
   WMS_DBPORT="5432"
   ```

2. **GeoServer Configuration**

   ```bash
   GEOSERVER_URL="http://localhost:8080/geoserver"
   GEOSERVER_USER="admin"
   GEOSERVER_PASSWORD="geoserver"
   ```

3. **Service Configuration**

   ```bash
   WMS_SERVICE_TITLE="OSM Notes WMS Service"
   WMS_LAYER_SRS="EPSG:4326"
   WMS_BBOX_MINX="-180"
   WMS_BBOX_MAXX="180"
   ```

#### Customization Examples

**Regional Configuration (Europe)**

```bash
export WMS_BBOX_MINX="-10"
export WMS_BBOX_MAXX="40"
export WMS_BBOX_MINY="35"
export WMS_BBOX_MAXY="70"
export WMS_SERVICE_TITLE="European OSM Notes WMS Service"
```

**Custom Database**

```bash
export WMS_DBNAME="my_osm_notes"
export WMS_DBUSER="myuser"    # WMS-specific database user
export WMS_DBPASSWORD="mypassword"
export WMS_DBHOST="my-db-server.com"
```

**Custom GeoServer**

```bash
export GEOSERVER_URL="https://my-geoserver.com/geoserver"
export GEOSERVER_USER="admin"
export GEOSERVER_PASSWORD="secure_password"
```

### Style Configuration

The WMS service includes three main styles:

1. **OpenNotes.sld**: For open notes (darker = older)
2. **ClosedNotes.sld**: For closed notes (lighter = older)
3. **CountriesAndMaritimes.sld**: For geographic boundaries

#### Custom Styles

To use custom styles:

```bash
# Set custom style file
export WMS_STYLE_OPEN_FILE="/path/to/my/custom_open.sld"
export WMS_STYLE_CLOSED_FILE="/path/to/my/custom_closed.sld"

# Reconfigure GeoServer
./bin/wms/geoserverConfig.sh install --force
```

## Usage

### Accessing the WMS Service

#### Service URLs

- **GetCapabilities**: `http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities`
- **GetMap**: `http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:notes_wms_layer&STYLES=&CRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=256&HEIGHT=256&FORMAT=image/png`
- **GetFeatureInfo**: `http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetFeatureInfo&LAYERS=osm_notes:notes_wms_layer&QUERY_LAYERS=osm_notes:notes_wms_layer&INFO_FORMAT=application/json&I=128&J=128&WIDTH=256&HEIGHT=256&CRS=EPSG:4326&BBOX=-180,-90,180,90`

#### GetFeatureInfo Request

GetFeatureInfo returns feature information for a specific pixel location on the map.

**Parameters:**

| Parameter | Required | Type | Description |
|-----------|----------|------|-------------|
| `SERVICE` | Yes | String | Service type (WMS) |
| `VERSION` | Yes | String | WMS version (1.3.0) |
| `REQUEST` | Yes | String | Request type (GetFeatureInfo) |
| `LAYERS` | Yes | String | Layer name |
| `QUERY_LAYERS` | Yes | String | Query layer name |
| `INFO_FORMAT` | Yes | String | Response format (text/html, application/json, text/plain) |
| `I` | Yes | Integer | Pixel X coordinate |
| `J` | Yes | Integer | Pixel Y coordinate |
| `WIDTH` | Yes | Integer | Image width |
| `HEIGHT` | Yes | Integer | Image height |
| `CRS` | Yes | String | Coordinate reference system |
| `BBOX` | Yes | String | Bounding box |

**Example JSON Response:**

```json
{
  "type": "FeatureCollection",
  "features": [
    {
      "type": "Feature",
      "id": "notes_wms.12345",
      "geometry": {
        "type": "Point",
        "coordinates": [-73.9857, 40.7484]
      },
      "properties": {
        "note_id": 12345,
        "year_created_at": 2024,
        "year_closed_at": null
      }
    }
  ]
}
```

#### Layer Names

- **Open Notes**: `osm_notes:notes_wms_layer` (filtered for open notes)
- **Closed Notes**: `osm_notes:notes_wms_layer` (filtered for closed notes)

### Integration with Mapping Applications

#### JOSM Integration

1. **Add WMS Layer**
   - Open JOSM
   - Go to `Imagery` → `Add WMS Layer`
   - Enter WMS URL: `http://localhost:8080/geoserver/wms`
   - Select layer: `osm_notes:notes_wms_layer`

2. **Configure Layer**
   - Set transparency as needed
   - Choose appropriate style
   - Adjust zoom levels

#### Vespucci Integration

1. **Add WMS Layer**
   - Open Vespucci
   - Go to `Layer` → `Add WMS Layer`
   - Enter WMS URL: `http://localhost:8080/geoserver/wms`
   - Select layer: `osm_notes:notes_wms_layer`

### Interpreting the Map

#### Color Coding

**Open Notes:**

- **Dark Red**: Recently opened notes (high priority)
- **Medium Red**: Notes open for a few days
- **Light Red**: Notes open for weeks/months

**Closed Notes:**

- **Dark Green**: Recently closed notes
- **Medium Green**: Notes closed some time ago
- **Light Green**: Notes closed long ago

#### Spatial Patterns

- **Clusters**: Areas with many notes may indicate mapping issues
- **Sparse Areas**: Few notes might indicate well-mapped areas
- **Linear Patterns**: Notes along roads or features being mapped

### Best Practices

1. **Layer Management**
   - Use appropriate zoom levels
   - Combine with other data sources
   - Adjust transparency for better visibility

2. **Performance**
   - Cache frequently accessed areas
   - Use appropriate bounding boxes
   - Monitor service performance

3. **Data Interpretation**
   - Consider temporal patterns
   - Look for geographic clusters
   - Cross-reference with other OSM data

## Troubleshooting

### Common Issues

#### 1. WMS Service Not Accessible

**Symptoms:**

- 404 errors when accessing WMS URLs
- GeoServer not responding

**Solutions:**

```bash
# Check GeoServer status
./bin/wms/geoserverConfig.sh status

# Restart GeoServer
sudo systemctl restart geoserver

# Check logs
tail -f /opt/geoserver/logs/geoserver.log
```

#### 2. Database Connection Issues

**Symptoms:**

- WMS layers not loading
- Database connection errors

**Solutions:**

```bash
# Check WMS schema
psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"

# Reinstall WMS components if needed
./bin/wms/wmsManager.sh install --force
```

#### 3. Empty or Missing Data

**Symptoms:**

- WMS layers show no data
- Empty map tiles

**Solutions:**

```bash
# Check if notes data exists
psql -d notes -c "SELECT COUNT(*) FROM notes;"

# Verify WMS data population
psql -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"

# Check triggers
psql -d notes -c "SELECT * FROM information_schema.triggers
  WHERE trigger_name LIKE '%wms%';"
```

#### 4. Performance Issues

**Symptoms:**

- Slow WMS responses
- Timeout errors
- High memory usage

**Solutions:**

```bash
# Check GeoServer memory
ps aux | grep geoserver

# Optimize database
psql -d notes -c "VACUUM ANALYZE wms.notes_wms;"

# Check indexes
psql -d notes -c "SELECT schemaname, tablename, indexname FROM pg_indexes
  WHERE schemaname = 'wms';"
```

### Diagnostic Commands

#### System Health Check

```bash
# Comprehensive health check
./bin/wms/wmsManager.sh status
./bin/wms/geoserverConfig.sh status
```

#### Performance Monitoring

```bash
# Check database performance
psql -d notes -c \
  "SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del 
  FROM pg_stat_user_tables WHERE schemaname = 'wms';"

# Check GeoServer performance
curl -s "http://localhost:8080/geoserver/rest/about/status" | jq .
```

#### Log Analysis

```bash
# Check WMS logs
tail -f logs/wms.log

# Check GeoServer logs
tail -f /opt/geoserver/logs/geoserver.log

# Check system logs
journalctl -u geoserver -f
```

### Recovery Procedures

#### Complete WMS Reset

```bash
# Remove WMS configuration
./bin/wms/geoserverConfig.sh remove
./bin/wms/wmsManager.sh deinstall

# Reinstall from scratch
./bin/wms/wmsManager.sh install
./bin/wms/geoserverConfig.sh install
```

#### Database Recovery

```bash
# Recreate WMS schema
psql -d notes -f sql/wms/prepareDatabase.sql

# Repopulate WMS data
psql -d notes -c "INSERT INTO wms.notes_wms 
  SELECT note_id, extract(year from created_at), extract(year from closed_at),
    ST_SetSRID(ST_MakePoint(lon, lat), 4326) FROM notes 
    WHERE lon IS NOT NULL AND lat IS NOT NULL;"
```

## Database Schema and Technical Details

### WMS Schema Overview

The WMS system uses a dedicated schema (`wms`) to optimize performance and maintain separation of concerns.

```sql
-- WMS Schema
CREATE SCHEMA IF NOT EXISTS wms;
COMMENT ON SCHEMA wms IS 'Objects to publish the WMS layer';
```

### Core Table: `wms.notes_wms`

The main WMS table containing optimized note data for map visualization.

```sql
CREATE TABLE wms.notes_wms (
    note_id INTEGER PRIMARY KEY,
    year_created_at INTEGER,
    year_closed_at INTEGER,
    geometry GEOMETRY(POINT, 4326)
);

COMMENT ON TABLE wms.notes_wms IS
  'Locations of the notes and its opening and closing year';
COMMENT ON COLUMN wms.notes_wms.note_id IS 'OSM note id';
COMMENT ON COLUMN wms.notes_wms.year_created_at IS 'Year when the note was created';
COMMENT ON COLUMN wms.notes_wms.year_closed_at IS 'Year when the note was closed';
COMMENT ON COLUMN wms.notes_wms.geometry IS 'Location of the note';
```

### Indexes

```sql
-- Index for open notes (most important queries)
CREATE INDEX notes_open ON wms.notes_wms (year_created_at);
COMMENT ON INDEX notes_open IS 'Queries based on creation year';

-- Index for closed notes
CREATE INDEX notes_closed ON wms.notes_wms (year_closed_at);
COMMENT ON INDEX notes_closed IS 'Queries based on closed year';

-- Spatial index for geometry queries
CREATE INDEX notes_wms_geometry_idx ON wms.notes_wms USING GIST (geometry);
COMMENT ON INDEX notes_wms_geometry_idx IS 'Spatial index for geometry queries';

-- Composite index for temporal-spatial queries
CREATE INDEX notes_wms_temporal_spatial ON wms.notes_wms (year_created_at, year_closed_at)
WHERE geometry IS NOT NULL;
```

### Triggers and Functions

#### Insert Trigger

Automatically populates WMS table when new notes are inserted:

```sql
CREATE OR REPLACE FUNCTION wms.insert_new_notes()
RETURNS TRIGGER AS $$
BEGIN
    -- Only insert if coordinates are valid
    IF NEW.lon IS NOT NULL AND NEW.lat IS NOT NULL THEN
        INSERT INTO wms.notes_wms
        VALUES (
            NEW.note_id,
            EXTRACT(YEAR FROM NEW.created_at),
            EXTRACT(YEAR FROM NEW.closed_at),
            ST_SetSRID(ST_MakePoint(NEW.lon, NEW.lat), 4326)
        );
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER insert_new_notes
    AFTER INSERT ON notes
    FOR EACH ROW
    EXECUTE FUNCTION wms.insert_new_notes();
```

#### Update Trigger

Automatically updates WMS table when notes are closed:

```sql
CREATE OR REPLACE FUNCTION wms.update_notes()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE wms.notes_wms
    SET year_closed_at = extract(year from NEW.closed_at)
    WHERE note_id = NEW.note_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_notes
    AFTER UPDATE ON notes
    FOR EACH ROW
    WHEN (OLD.closed_at IS DISTINCT FROM NEW.closed_at)
    EXECUTE FUNCTION wms.update_notes();
```

### Initial Data Population

```sql
-- Populate WMS table from main notes table
INSERT INTO wms.notes_wms
SELECT 
    note_id,
    extract(year from created_at) AS year_created_at,
    extract(year from closed_at) AS year_closed_at,
    ST_SetSRID(ST_MakePoint(lon, lat), 4326) AS geometry
FROM notes
WHERE lon IS NOT NULL AND lat IS NOT NULL;
```

## Advanced Configuration

### Custom Layer Filters

Create custom SQL views for specific note types:

```sql
-- Custom view for high-priority notes
CREATE VIEW wms.high_priority_notes AS
SELECT note_id, year_created_at, year_closed_at, geometry
FROM wms.notes_wms
WHERE year_closed_at IS NULL
  AND year_created_at >= extract(year from current_date) - 1;
```

### Performance Optimization

#### Database Optimization

```sql
-- Add spatial index
CREATE INDEX IF NOT EXISTS notes_wms_geometry_gist ON wms.notes_wms USING GIST (geometry);

-- Add temporal index
CREATE INDEX IF NOT EXISTS notes_wms_temporal ON wms.notes_wms (year_created_at,
  year_closed_at);

-- Analyze table
ANALYZE wms.notes_wms;
```

#### GeoServer Optimization

```bash
# Configure GeoServer memory
export GEOSERVER_OPTS="-Xms2g -Xmx4g"

# Enable tile caching
# Configure in GeoServer admin interface
```

### Security Considerations

#### Authentication

```bash
# Enable WMS authentication
export WMS_AUTH_ENABLED="true"
export WMS_AUTH_USER="wms_user"
export WMS_AUTH_PASSWORD="secure_password"
```

#### CORS Configuration

```bash
# Configure CORS for web applications
export WMS_CORS_ENABLED="true"
export WMS_CORS_ALLOW_ORIGIN="https://myapp.com"
```

## Administration and Maintenance

### System Monitoring

#### Health Check Script

Create a monitoring script: `/usr/local/bin/wms-health-check.sh`

```bash
#!/bin/bash
# WMS Health Check Script

# Use logs directory in home or project directory (no special permissions required)
# Create directory first: mkdir -p ~/logs
LOG_FILE="${HOME}/logs/wms-health-check.log"
# Alternative: Use project logs directory
# LOG_FILE="/path/to/OSM-Notes-WMS/logs/wms-health-check.log"
ALERT_EMAIL="admin@yourdomain.com"

# Check database connection
check_database() {
    psql -h localhost -U postgres -d notes -c \
      "SELECT COUNT(*) FROM wms.notes_wms;" >/dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "$(date): Database connection OK" >> $LOG_FILE
        return 0
    else
        echo "$(date): Database connection FAILED" >> $LOG_FILE
        return 1
    fi
}

# Check GeoServer status
check_geoserver() {
    curl -s "http://localhost:8080/geoserver/rest/about/status" >/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date): GeoServer status OK" >> $LOG_FILE
        return 0
    else
        echo "$(date): GeoServer status FAILED" >> $LOG_FILE
        return 1
    fi
}

# Check WMS service
check_wms_service() {
    curl -s "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities" \
      >/dev/null
    if [ $? -eq 0 ]; then
        echo "$(date): WMS service OK" >> $LOG_FILE
        return 0
    else
        echo "$(date): WMS service FAILED" >> $LOG_FILE
        return 1
    fi
}

# Main health check
main() {
    local failed=0
    
    check_database || failed=1
    check_geoserver || failed=1
    check_wms_service || failed=1
    
    if [ $failed -eq 1 ]; then
        echo "$(date): WMS health check FAILED" >> $LOG_FILE
        echo "WMS health check failed. Check logs at $LOG_FILE" | mail -s \
          "WMS Alert" $ALERT_EMAIL
        return 1
    else
        echo "$(date): WMS health check PASSED" >> $LOG_FILE
        return 0
    fi
}

main
```

#### Cron Job Setup

```bash
# Add to crontab for regular monitoring
# Check every 5 minutes
*/5 * * * * /usr/local/bin/wms-health-check.sh

# Daily maintenance at 2 AM
# Adjust the path to match your installation directory
0 2 * * * /path/to/OSM-Notes-WMS/bin/wms/wmsManager.sh status
```

### Performance Monitoring

#### Database Performance

```sql
-- Monitor query performance
SELECT query, calls, total_time, mean_time
FROM pg_stat_statements
WHERE query LIKE '%wms%'
ORDER BY mean_time DESC
LIMIT 10;

-- Monitor table statistics
SELECT schemaname, tablename, n_tup_ins, n_tup_upd, n_tup_del
FROM pg_stat_user_tables
WHERE schemaname = 'wms';

-- Monitor index usage
SELECT schemaname, tablename, indexname, idx_scan, idx_tup_read
FROM pg_stat_user_indexes
WHERE schemaname = 'wms';
```

#### GeoServer Performance

```bash
# Monitor GeoServer memory usage
ps aux | grep geoserver

# Check GeoServer logs
tail -f /opt/geoserver/logs/geoserver.log

# Monitor WMS response times
curl -w "@curl-format.txt" -o /dev/null -s \
  "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:notes_wms_layer&STYLES=&CRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=256&HEIGHT=256&FORMAT=image/png"
```

### Maintenance Procedures

#### Daily Tasks

```bash
# Check system health
/usr/local/bin/wms-health-check.sh

# Monitor disk space
df -h | grep -E "(/$|/opt)"

# Check service status
systemctl status geoserver
systemctl status postgresql
```

#### Weekly Tasks

```bash
# Update database statistics
psql -d notes -c "ANALYZE wms.notes_wms;"

# Clean old logs
find /opt/geoserver/logs -name "*.log.*" -mtime +7 -delete

# Check for updates
apt list --upgradable | grep -E "(postgresql|geoserver)"
```

#### Monthly Tasks

```bash
# Full system backup
pg_dump notes > /backup/osm_notes_$(date +%Y%m).sql

# GeoServer backup
cp -r /opt/geoserver/data_dir /backup/geoserver_$(date +%Y%m)
```

### Backup and Recovery

#### Database Backup Script

```bash
#!/bin/bash
# Database backup script

BACKUP_DIR="/backup/database"
DATE=$(date +%Y%m%d_%H%M%S)
DB_NAME="notes"

# Create backup directory
mkdir -p $BACKUP_DIR

# Full database backup
pg_dump -h localhost -U postgres $DB_NAME > $BACKUP_DIR/${DB_NAME}_${DATE}.sql

# WMS schema only backup
pg_dump -h localhost -U postgres -n wms $DB_NAME > $BACKUP_DIR/wms_schema_${DATE}.sql

# Compress backups
gzip $BACKUP_DIR/${DB_NAME}_${DATE}.sql
gzip $BACKUP_DIR/wms_schema_${DATE}.sql

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.sql.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/${DB_NAME}_${DATE}.sql.gz"
```

#### GeoServer Backup Script

```bash
#!/bin/bash
# GeoServer backup script

BACKUP_DIR="/backup/geoserver"
DATE=$(date +%Y%m%d_%H%M%S)
GEOSERVER_DIR="/opt/geoserver/data_dir"

# Create backup directory
mkdir -p $BACKUP_DIR

# Stop GeoServer
systemctl stop geoserver

# Backup data directory
tar -czf $BACKUP_DIR/geoserver_${DATE}.tar.gz -C /opt geoserver/data_dir

# Start GeoServer
systemctl start geoserver

# Clean old backups (keep 30 days)
find $BACKUP_DIR -name "*.tar.gz" -mtime +30 -delete

echo "Backup completed: $BACKUP_DIR/geoserver_${DATE}.tar.gz"
```

### Log Management

#### Log Rotation

Create logrotate configuration: `/etc/logrotate.d/wms`

**Note:** If using logs in home directory (`~/logs/`), use absolute path in logrotate config.

```text
# Example for logs in home directory
/home/username/logs/wms*.log {
    daily
    missingok
    rotate 30
    compress
    delaycompress
    notifempty
    create 644 username username
    postrotate
        systemctl reload geoserver
    endscript
}

# Alternative: If using /var/log/ (requires root permissions)
# /var/log/wms*.log {
#     daily
#     missingok
#     rotate 30
#     compress
#     delaycompress
#     notifempty
#     create 644 root root
#     postrotate
#         systemctl reload geoserver
#     endscript
# }
```

#### Log Analysis

```bash
# Analyze WMS access logs
grep "WMS" /opt/geoserver/logs/geoserver.log | \
  awk '{print $1, $2}' | \
  sort | uniq -c | sort -nr

# Monitor error patterns
grep "ERROR" /opt/geoserver/logs/geoserver.log | \
  tail -100 | \
  awk '{print $5}' | \
  sort | uniq -c | sort -nr
```

## Deployment

### Docker Deployment

```yaml
# docker-compose.prod.yml
version: '3.8'
services:
  postgres-prod:
    image: postgis/postgis:13-3.1
    environment:
      POSTGRES_DB: ${WMS_DBNAME}
      POSTGRES_USER: ${WMS_DBUSER}
      POSTGRES_PASSWORD: ${WMS_DBPASSWORD}
    volumes:
      - postgres_prod_data:/var/lib/postgresql/data
      - ./sql:/docker-entrypoint-initdb.d
    networks:
      - wms_network
    restart: unless-stopped

  geoserver-prod:
    image: kartoza/geoserver:2.24.0
    environment:
      GEOSERVER_ADMIN_PASSWORD: ${GEOSERVER_PASSWORD}
      GEOSERVER_ADMIN_USER: ${GEOSERVER_USER}
      GEOSERVER_DATA_DIR: /opt/geoserver/data_dir
      GEOSERVER_OPTS: "-Xms2g -Xmx4g -XX:+UseG1GC"
    volumes:
      - geoserver_prod_data:/opt/geoserver/data_dir
      - ./sld:/opt/geoserver/data_dir/styles
    networks:
      - wms_network
    ports:
      - "8080:8080"
    depends_on:
      - postgres-prod
    restart: unless-stopped

volumes:
  postgres_prod_data:
  geoserver_prod_data:

networks:
  wms_network:
    driver: bridge
```

### Environment-Specific Configurations

#### Development Environment

```bash
export WMS_DEV_MODE="true"
export WMS_DEBUG_ENABLED="true"
export WMS_LOG_LEVEL="DEBUG"
export WMS_DBNAME="osm_notes_dev"
```

#### Production Environment

```bash
export WMS_DEV_MODE="false"
export WMS_DEBUG_ENABLED="false"
export WMS_LOG_LEVEL="INFO"
export WMS_CACHE_ENABLED="true"
export WMS_CACHE_TTL="3600"
export GEOSERVER_OPTS="-Xms4g -Xmx8g -XX:+UseG1GC"
```

## Support and Resources

### Getting Help

1. **Check Documentation**
   - This guide
   - [WMS_User_Guide.md](./WMS_User_Guide.md) for end users

2. **Community Support**
   - OSM community forums
   - GeoServer mailing lists
   - GitHub issues

3. **Logs and Debugging**
   - Enable debug logging
   - Check system logs
   - Monitor performance metrics

### Related Documentation

#### WMS Documentation

- **[WMS_User_Guide.md](./WMS_User_Guide.md)**: Step-by-step user guide for mappers using WMS in JOSM/Vespucci

#### System Documentation

> **Note:** The following documentation files are part of the [OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion) project, which provides the data source for this WMS service:
>
> - **Documentation.md**: Complete system architecture and technical overview (in OSM-Notes-Ingestion)
> - **Component_Dependencies.md**: Component dependencies and data flow (in OSM-Notes-Ingestion)
> - **Troubleshooting_Guide.md**: Centralized troubleshooting guide (in OSM-Notes-Ingestion)

#### Processing Documentation

> **Note:** The following documentation files describe the data ingestion process in the [OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion) project:
>
> - **Process_API.md**: API processing details (WMS data source) (in OSM-Notes-Ingestion)
> - **Process_Planet.md**: Planet processing details (WMS data source) (in OSM-Notes-Ingestion)

#### Script Reference

- **[bin/wms/README.md](../bin/wms/README.md)**: WMS script usage examples and documentation
- **Script Entry Points**: `wmsManager.sh` and `geoserverConfig.sh` (see [bin/wms/README.md](../bin/wms/README.md))
- **Environment Variables**: See `etc/wms.properties.sh.example` for all available configuration variables
