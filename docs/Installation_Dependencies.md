---
title: "Installation and Dependencies Guide"
description: "Complete guide to install dependencies and set up OSM-Notes-WMS for development"
version: "1.0.0"
last_updated: "2026-01-26"
author: "AngocA"
tags:
  - "installation"
  - "dependencies"
  - "setup"
audience:
  - "developers"
  - "system-admins"
project: "OSM-Notes-WMS"
status: "active"
---

# Installation and Dependencies Guide

Complete guide to install all dependencies and set up OSM-Notes-WMS for development and production.

## Table of Contents

1. [System Requirements](#system-requirements)
2. [System Dependencies](#system-dependencies)
3. [Internal Dependencies](#internal-dependencies)
4. [Database Setup](#database-setup)
5. [GeoServer Installation](#geoserver-installation)
6. [Project Installation](#project-installation)
7. [Configuration](#configuration)
8. [Verification](#verification)
9. [Troubleshooting](#troubleshooting)

---

## System Requirements

### Operating System

- **Linux** (Ubuntu 20.04+ / Debian 11+ recommended)
- **Bash** 4.0 or higher
- **Git** for cloning repositories

### Hardware Requirements

- **CPU**: 2+ cores recommended
- **RAM**: 4GB minimum, 8GB+ recommended (for GeoServer)
- **Disk**: 10GB+ free space
- **Network**: Stable connection for GeoServer access

---

## System Dependencies

### Required Software

Install all required dependencies on Ubuntu/Debian:

```bash
# Update package list
sudo apt-get update

# PostgreSQL with PostGIS extension (if not already installed)
sudo apt-get install -y postgresql postgresql-contrib postgis postgresql-14-postgis-3

# Standard UNIX utilities
sudo apt-get install -y grep awk sed curl

# Git (if not already installed)
sudo apt-get install -y git

# Java Runtime Environment (required for GeoServer)
sudo apt-get install -y default-jre

# Verify Java installation
java -version  # Should be Java 8 or higher
```

### Verify Installation

```bash
# Check PostgreSQL version
psql --version  # Should be 12+

# Check PostGIS
psql -d postgres -c "SELECT PostGIS_version();"

# Check Bash version
bash --version  # Should be 4.0+

# Check Java
java -version
```

---

## Internal Dependencies

### ⚠️ Required: OSM-Notes-Ingestion

**OSM-Notes-WMS REQUIRES OSM-Notes-Ingestion to be installed and configured first.**

The WMS project uses the same PostgreSQL database as Ingestion:
- **Database**: `notes` (same database as Ingestion)
- **Schema**: `public` (managed by Ingestion) - contains `notes`, `countries` tables
- **Schema**: `wms` (managed by WMS) - contains WMS-specific views and tables

### Installation Order

1. **First**: Install and configure OSM-Notes-Ingestion
2. **Second**: Ensure Ingestion database is populated with data
3. **Third**: Install GeoServer
4. **Fourth**: Install OSM-Notes-WMS (this project)
5. **Verify**: Ensure Ingestion database has data before configuring WMS layers

### Database Schema Requirements

WMS requires these tables in the Ingestion database (`public` schema):
- `notes` - Notes table with geometry column
- `countries` - Countries table
- `note_comments` - Note comments (optional, for advanced features)

---

## Database Setup

### 1. Verify Ingestion Database

```bash
# Test connection to Ingestion database
psql -h localhost -U notes -d notes -c "SELECT COUNT(*) FROM public.notes;"

# Verify required tables exist
psql -h localhost -U notes -d notes -c "\dt public.*"

# Verify PostGIS is enabled
psql -h localhost -U notes -d notes -c "SELECT PostGIS_version();"
```

### 2. Create WMS Schema

```bash
# Create WMS schema in the same database
psql -h localhost -U notes -d notes << EOF
CREATE SCHEMA IF NOT EXISTS wms;
GRANT USAGE ON SCHEMA wms TO notes;
GRANT CREATE ON SCHEMA wms TO notes;
\q
EOF
```

### 3. Run WMS SQL Scripts

```bash
# Run database preparation script
psql -h localhost -U notes -d notes -f sql/wms/prepareDatabase.sql

# Verify schema was created
psql -h localhost -U notes -d notes -c "\dn wms"
```

---

## GeoServer Installation

### 1. Download GeoServer

```bash
# Create directory for GeoServer
sudo mkdir -p /opt/geoserver
cd /opt/geoserver

# Download GeoServer (replace version with latest)
wget https://sourceforge.net/projects/geoserver/files/GeoServer/2.24.0/geoserver-2.24.0-bin.zip

# Extract
sudo unzip geoserver-2.24.0-bin.zip
sudo mv geoserver-2.24.0/* .
sudo rm -rf geoserver-2.24.0 geoserver-2.24.0-bin.zip
```

### 2. Configure GeoServer

```bash
# Set GeoServer data directory (optional, defaults to installation directory)
export GEOSERVER_DATA_DIR=/var/lib/geoserver

# Create data directory
sudo mkdir -p /var/lib/geoserver
sudo chown -R $USER:$USER /var/lib/geoserver
```

### 3. Start GeoServer

```bash
# Start GeoServer (development)
cd /opt/geoserver/bin
./startup.sh

# Or install as systemd service (production)
sudo nano /etc/systemd/system/geoserver.service
```

**Systemd service file** (`/etc/systemd/system/geoserver.service`):

```ini
[Unit]
Description=GeoServer
After=network.target

[Service]
Type=forking
User=geoserver
ExecStart=/opt/geoserver/bin/startup.sh
ExecStop=/opt/geoserver/bin/shutdown.sh
Restart=on-failure

[Install]
WantedBy=multi-user.target
```

```bash
# Enable and start service
sudo systemctl daemon-reload
sudo systemctl enable geoserver
sudo systemctl start geoserver
```

### 4. Access GeoServer Web Interface

- **URL**: `http://localhost:8080/geoserver`
- **Default username**: `admin`
- **Default password**: `geoserver`

**Important**: Change the default password immediately!

---

## Project Installation

### 1. Clone Repository with Submodules

```bash
# Clone with submodules (recommended)
git clone --recurse-submodules https://github.com/OSM-Notes/OSM-Notes-WMS.git
cd OSM-Notes-WMS

# Or if already cloned, initialize submodules
git submodule update --init --recursive
```

### 2. Verify Submodule Installation

```bash
# Check submodule status
git submodule status

# Verify common functions exist
ls -la lib/osm-common/commonFunctions.sh
ls -la lib/osm-common/validationFunctions.sh
ls -la lib/osm-common/errorHandlingFunctions.sh
ls -la lib/osm-common/bash_logger.sh
```

### 3. Verify Database Access

```bash
# Test connection to Ingestion database
psql -h localhost -U notes -d notes -c "SELECT COUNT(*) FROM public.notes;"

# Verify WMS schema exists
psql -h localhost -U notes -d notes -c "\dn wms"
```

---

## Configuration

### 1. Environment Variables

Set required environment variables:

```bash
# Database configuration (same as Ingestion)
export DB_HOST="localhost"
export DB_PORT="5432"
export DB_NAME="notes"
export DB_USER="notes"
export DB_PASSWORD="your_secure_password_here"

# GeoServer configuration
export GEOSERVER_URL="http://localhost:8080/geoserver"
export GEOSERVER_USER="admin"
export GEOSERVER_PASSWORD="your_geoserver_password"

# Logging
export LOG_LEVEL="INFO"  # TRACE, DEBUG, INFO, WARN, ERROR, FATAL
```

### 2. Configuration File

Create or edit `etc/wms.properties.sh`:

```bash
# Copy example if exists
cp etc/wms.properties.sh.example etc/wms.properties.sh

# Edit configuration
nano etc/wms.properties.sh
```

### 3. Source Configuration

```bash
# Source the configuration
source etc/wms.properties.sh

# Or export variables in your shell
export DB_NAME="notes"
export DB_USER="notes"
# ... etc
```

---

## Verification

### 1. Verify Prerequisites

```bash
# Check all tools are installed
which psql java curl

# Check PostgreSQL connection
psql -h localhost -U notes -d notes -c "SELECT version();"

# Check GeoServer is running
curl -I http://localhost:8080/geoserver
```

### 2. Verify Database Setup

```bash
# Check WMS schema exists
psql -h localhost -U notes -d notes -c "\dn wms"

# Check WMS views exist
psql -h localhost -U notes -d notes -c "\dv wms.*"
```

### 3. Run Database Setup Scripts

```bash
# Run database preparation
psql -h localhost -U notes -d notes -f sql/wms/prepareDatabase.sql

# Verify schema
psql -h localhost -U notes -d notes -f sql/wms/verifySchema.sql
```

### 4. Configure GeoServer Layers

```bash
# Run WMS setup script (if available)
./bin/wms/setupGeoServer.sh

# Or manually configure layers via GeoServer web interface
# See docs/WMS_Guide.md for detailed instructions
```

### 5. Test WMS Service

```bash
# Test GetCapabilities
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetCapabilities"

# Test GetMap (should return an image)
curl "http://localhost:8080/geoserver/wms?SERVICE=WMS&VERSION=1.3.0&REQUEST=GetMap&LAYERS=osm_notes:notesopen&CRS=EPSG:4326&BBOX=-180,-90,180,90&WIDTH=256&HEIGHT=256&FORMAT=image/png" -o test_map.png
```

---

## Troubleshooting

### Ingestion Database Not Found

**Error**: `relation "public.notes" does not exist`

**Solution**:
1. Ensure OSM-Notes-Ingestion is installed and configured
2. Verify Ingestion database is populated with data
3. Check database connection settings
4. Verify user has SELECT permissions on Ingestion tables

### GeoServer Connection Issues

```bash
# Check GeoServer is running
sudo systemctl status geoserver
# or
ps aux | grep geoserver

# Check GeoServer logs
tail -f /opt/geoserver/logs/geoserver.log

# Test GeoServer web interface
curl -I http://localhost:8080/geoserver
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
sudo systemctl status postgresql

# Test connection
psql -h localhost -U notes -d notes

# Check user permissions
psql -U postgres -c "\du notes"
```

### Submodule Issues

```bash
# Initialize submodules
git submodule update --init --recursive

# Verify submodule exists
ls -la lib/osm-common/commonFunctions.sh
```

### WMS Layer Not Found

**Error**: `Layer 'osm_notes:notesopen' not found`

**Solution**:
1. Verify database views exist: `psql -d notes -c "\dv wms.*"`
2. Check GeoServer data store is configured correctly
3. Verify GeoServer can connect to database
4. Check GeoServer logs for errors

---

## Next Steps

After installation:

1. **Read WMS Guide**: `docs/WMS_Guide.md` - Complete technical guide
2. **Review User Guide**: `docs/WMS_User_Guide.md` - How to use WMS in JOSM/Vespucci
3. **Check Scripts**: `bin/wms/README.md` - Scripts documentation
4. **Explore SQL**: `sql/wms/README.md` - SQL scripts documentation

---

## Related Documentation

- [WMS Guide](WMS_Guide.md) - Complete technical guide for administrators
- [WMS User Guide](WMS_User_Guide.md) - User guide for mappers
- [Scripts Documentation](bin/wms/README.md) - WMS management scripts
- [SQL Documentation](sql/wms/README.md) - SQL scripts documentation
- [SLD Documentation](sld/README.md) - Style files documentation
