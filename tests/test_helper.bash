#!/usr/bin/env bash
# Test Helper Functions for BATS Tests
# Common helper functions used across integration tests
#
# Author: Andres Gomez (AngocA)
# Version: 2026-03-28

# Ensures schema_version (core) exists for WMS / schema contract checks in tests.
# Parameters: none.
_ensure_schema_version_contract_for_tests() {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    return 0
  fi
  psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -c "
CREATE TABLE IF NOT EXISTS schema_version (
 component VARCHAR(64) PRIMARY KEY,
 version VARCHAR(16) NOT NULL,
 updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
INSERT INTO schema_version (component, version) VALUES ('core', '1.1.0')
ON CONFLICT (component) DO UPDATE SET
 version = EXCLUDED.version,
 updated_at = CURRENT_TIMESTAMP;
" 2> /dev/null || true
}

# Function to create WMS test database with PostGIS
# Uses processPlanetNotes.sh --base from OSM-Notes-Ingestion project to create base tables
create_wms_test_database() {
  echo "Creating WMS test database..."
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    echo "Mock mode enabled, skipping real database creation"
    return 0
  fi
  
  # Check if PostgreSQL is available
  if ! psql -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
    echo "PostgreSQL not available, using mock commands"
    export MOCK_MODE=1
    return 0
  fi
  
  # Check if database exists, if not create it
  # Don't create/delete the 'notes' database as it's a production database
  if [[ "${TEST_DBNAME}" != "notes" ]]; then
    if ! psql -d "${TEST_DBNAME}" -c "SELECT 1;" > /dev/null 2>&1; then
      createdb "${TEST_DBNAME}" 2> /dev/null || true
    fi
  else
    # If using 'notes', skip creation but ensure it exists
    if ! psql -d "${TEST_DBNAME}" -c "SELECT 1;" > /dev/null 2>&1; then
      echo "ERROR: Production database 'notes' not available"
      export MOCK_MODE=1
      return 1
    fi
  fi
  
  # Enable PostGIS extension if not already enabled (required for WMS)
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Try to use processPlanetNotes.sh --base from Ingestion project if available
  # This creates the base tables with the correct schema as defined by OSM-Notes-Ingestion
  # Try multiple possible locations for the Ingestion project
  local INGESTION_PROJECT=""
  local PROCESS_PLANET_SCRIPT=""
  
  # Try workspace-relative path first
  if [[ -f "../OSM-Notes-Ingestion/bin/process/processPlanetNotes.sh" ]]; then
    INGESTION_PROJECT="$(cd ../OSM-Notes-Ingestion && pwd)"
  # Try absolute path (user's home)
  elif [[ -f "/home/angoca/github/OSM-Notes/OSM-Notes-Ingestion/bin/process/processPlanetNotes.sh" ]]; then
    INGESTION_PROJECT="/home/angoca/github/OSM-Notes/OSM-Notes-Ingestion"
  # Try environment variable if set
  elif [[ -n "${OSM_NOTES_INGESTION_ROOT:-}" ]] && [[ -f "${OSM_NOTES_INGESTION_ROOT}/bin/process/processPlanetNotes.sh" ]]; then
    INGESTION_PROJECT="${OSM_NOTES_INGESTION_ROOT}"
  fi
  
  if [[ -n "${INGESTION_PROJECT}" ]]; then
    PROCESS_PLANET_SCRIPT="${INGESTION_PROJECT}/bin/process/processPlanetNotes.sh"
  fi
  
  if [[ -f "${PROCESS_PLANET_SCRIPT}" ]] && [[ -x "${PROCESS_PLANET_SCRIPT}" ]]; then
    echo "Using processPlanetNotes.sh --base from Ingestion project to create base tables..."
    # Set environment variables for the script
    export DBNAME="${TEST_DBNAME}"
    export DB_USER="${TEST_DBUSER:-}"
    export DB_PASSWORD="${TEST_DBPASSWORD:-}"
    export DB_HOST="${TEST_DBHOST:-}"
    export DB_PORT="${TEST_DBPORT:-}"
    
    # Run only the base setup (creates tables and populates with base data)
    # This is equivalent to the first step of processAPINotes.sh hybrid mode
    if "${PROCESS_PLANET_SCRIPT}" --base > /tmp/processPlanetNotes_test.log 2>&1; then
      echo "Base tables created successfully using processPlanetNotes.sh --base"
      # Ensure PostGIS is still enabled after processPlanetNotes.sh (it may have been dropped)
      psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
      
      # Ensure countries table has geom column (required for disputed areas view)
      # If countries table exists but doesn't have geom, add it with sample data
      if psql -d "${TEST_DBNAME}" -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'countries';" > /dev/null 2>&1; then
        if ! psql -d "${TEST_DBNAME}" -c "SELECT 1 FROM information_schema.columns WHERE table_name = 'countries' AND column_name = 'geom';" > /dev/null 2>&1; then
          echo "Adding geom column to countries table..."
          psql -d "${TEST_DBNAME}" -c "ALTER TABLE countries ADD COLUMN geom GEOMETRY(MultiPolygon, 4326);" 2> /dev/null || true
          # Populate with sample geometries if table has data but geom is NULL
          psql -d "${TEST_DBNAME}" -c "
            UPDATE countries 
            SET geom = ST_Multi(ST_MakeEnvelope(-180 + (country_id * 10), -90 + (country_id * 10), -170 + (country_id * 10), -80 + (country_id * 10), 4326))
            WHERE geom IS NULL;
          " 2> /dev/null || true
        fi
      fi
      _ensure_schema_version_contract_for_tests
    else
      echo "Warning: processPlanetNotes.sh --base failed, falling back to manual table creation"
      echo "Check /tmp/processPlanetNotes_test.log for details"
      # Fall back to manual creation
      _create_basic_tables_manually
    fi
  else
    echo "processPlanetNotes.sh not found at ${PROCESS_PLANET_SCRIPT}, using manual table creation"
    _create_basic_tables_manually
  fi
  
  # Ensure countries table has geom column even if created manually
  if psql -d "${TEST_DBNAME}" -c "SELECT 1 FROM information_schema.tables WHERE table_name = 'countries';" > /dev/null 2>&1; then
    if ! psql -d "${TEST_DBNAME}" -c "SELECT 1 FROM information_schema.columns WHERE table_name = 'countries' AND column_name = 'geom';" > /dev/null 2>&1; then
      echo "Adding geom column to countries table..."
      psql -d "${TEST_DBNAME}" -c "ALTER TABLE countries ADD COLUMN geom GEOMETRY(MultiPolygon, 4326);" 2> /dev/null || true
      # Populate with sample geometries
      psql -d "${TEST_DBNAME}" -c "
        UPDATE countries 
        SET geom = ST_Multi(ST_MakeEnvelope(-180 + (country_id * 10), -90 + (country_id * 10), -170 + (country_id * 10), -80 + (country_id * 10), 4326))
        WHERE geom IS NULL;
      " 2> /dev/null || true
    fi
  fi
  _ensure_schema_version_contract_for_tests
}

# Helper function to create basic tables manually (fallback)
_create_basic_tables_manually() {
  # Enable PostGIS extension if not already enabled
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create basic notes table structure if it doesn't exist
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Insert test data
  psql -d "${TEST_DBNAME}" -c "
    INSERT INTO notes (note_id, created_at, closed_at, longitude, latitude) VALUES
    (1, '2023-01-01 10:00:00', NULL, -74.006, 40.7128),
    (2, '2023-02-01 11:00:00', '2023-02-15 12:00:00', -118.2437, 34.0522),
    (3, '2023-03-01 09:00:00', NULL, 2.3522, 48.8566)
    ON CONFLICT (note_id) DO NOTHING;
  " 2> /dev/null || true
  _ensure_schema_version_contract_for_tests
}

# Function to drop WMS test database
drop_wms_test_database() {
  echo "Dropping WMS test database..."
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    echo "Mock dropdb called with: ${TEST_DBNAME}"
  else
    # Don't drop the 'notes' database as it's a production database
    # Only drop test databases (like osm_notes_wms_test)
    if [[ "${TEST_DBNAME}" == "notes" ]]; then
      echo "Skipping drop of production database 'notes'"
    else
      # For test databases, optionally drop them (commented out to preserve test data)
      # dropdb "${TEST_DBNAME}" 2> /dev/null || true
      echo "Preserving test database '${TEST_DBNAME}' (uncomment dropdb to remove)"
    fi
  fi
}

# Function to create test database (generic version)
create_test_database() {
  create_wms_test_database
}

# Function to drop test database (generic version)
drop_test_database() {
  drop_wms_test_database
}

# Helper function to run psql with proper authentication
run_psql() {
  local sql_command="$1"
  local description="${2:-SQL query}"
  
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    echo "Mock psql: ${description}"
    # Return mock values for common queries
    case "$sql_command" in
    *"schema_name = 'wms'"*)
      if [[ "$description" == *"removed"* ]]; then
        echo "f" # Schema removed
      else
        echo "t" # Schema exists
      fi
      ;;
    *"table_name = 'notes_wms'"*) echo "t" ;;
    *"trigger_name IN"*) echo "2" ;;
    *"COUNT(*) FROM wms.notes_wms"*) echo "3" ;;
    *"COUNT(*) FROM notes"*) echo "2" ;;
    *) echo "1" ;;
    esac
  else
    psql -d "${TEST_DBNAME}" -t -c "${sql_command}" | tr -d ' '
  fi
}
