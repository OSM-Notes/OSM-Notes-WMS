#!/usr/bin/env bash
# Test Helper Functions for BATS Tests
# Common helper functions used across integration tests
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08

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
  if ! psql -d "${TEST_DBNAME}" -c "SELECT 1;" > /dev/null 2>&1; then
    createdb "${TEST_DBNAME}" 2> /dev/null || true
  fi
  
  # Enable PostGIS extension if not already enabled (required for WMS)
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Try to use processPlanetNotes.sh --base from Ingestion project if available
  # This creates the base tables with the correct schema as defined by OSM-Notes-Ingestion
  local INGESTION_PROJECT="/home/angoca/github/OSM-Notes-Ingestion"
  local PROCESS_PLANET_SCRIPT="${INGESTION_PROJECT}/bin/process/processPlanetNotes.sh"
  
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
}

# Function to drop WMS test database
drop_wms_test_database() {
  echo "Dropping WMS test database..."
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    echo "Mock dropdb called with: ${TEST_DBNAME}"
  else
    dropdb "${TEST_DBNAME}" 2> /dev/null || true
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

# Function to create mock WMS script
create_mock_wms_script() {
  local mock_script="${BATS_TEST_DIRNAME}/mock_wmsManager.sh"
  if [[ -f "${mock_script}" ]]; then
    # Script already exists, reuse it
    return 0
  fi
  
  cat > "$mock_script" << 'EOF'
#!/bin/bash
# Mock WMS Manager Script for testing
set -euo pipefail
# Mock colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'
print_status() {
  local COLOR=$1
  local MESSAGE=$2
  echo -e "${COLOR}${MESSAGE}${NC}"
}
show_help() {
  cat << 'HELP_EOF'
WMS Manager Script (MOCK)
Usage: $0 [COMMAND] [OPTIONS]
COMMANDS:
  install     Install WMS components in the database
  deinstall   Remove WMS components from the database
  status      Check the status of WMS installation
  help        Show this help message
OPTIONS:
  --force     Force installation even if already installed
  --dry-run   Show what would be done without executing
  --verbose   Show detailed output
HELP_EOF
}
# Mock functions - use a file to persist state
get_mock_state() {
  local state_file="/tmp/mock_wms_state"
  if [[ -f "$state_file" ]]; then
    cat "$state_file"
  else
    echo "false"
  fi
}
set_mock_state() {
  local state="$1"
  local state_file="/tmp/mock_wms_state"
  echo "$state" > "$state_file"
}
is_wms_installed() {
  [[ "$(get_mock_state)" == "true" ]]
}
install_wms() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    print_status "${YELLOW}" "DRY RUN: Would install WMS components"
    return 0
  fi
  if is_wms_installed && [[ "${FORCE:-false}" != "true" ]]; then
    print_status "${YELLOW}" "⚠️  WMS is already installed. Use --force to reinstall."
    return 0
  fi
  set_mock_state "true"
  print_status "${GREEN}" "✅ WMS installation completed successfully"
  print_status "${BLUE}" "📋 Installation Summary:"
  print_status "${BLUE}" "   - Schema 'wms' created"
  print_status "${BLUE}" "   - Table 'wms.notes_wms' created"
  print_status "${BLUE}" "   - Indexes created for performance"
  print_status "${BLUE}" "   - Triggers configured for synchronization"
  print_status "${BLUE}" "   - Functions created for data management"
}
deinstall_wms() {
  if [[ "${DRY_RUN:-false}" == "true" ]]; then
    print_status "${YELLOW}" "DRY RUN: Would remove WMS components"
    return 0
  fi
  set_mock_state "false"
  print_status "${GREEN}" "✅ WMS removal completed successfully"
}
show_status() {
  if is_wms_installed; then
    print_status "${GREEN}" "✅ WMS is installed"
    print_status "${BLUE}" "   Schema 'wms' exists"
    print_status "${BLUE}" "   Table 'wms.notes_wms' exists"
  else
    print_status "${YELLOW}" "⚠️  WMS is not installed"
  fi
}
# Main command handler
case "${1:-}" in
  install)
    install_wms
    ;;
  deinstall|remove)
    deinstall_wms
    ;;
  status)
    show_status
    ;;
  help|--help|-h)
    show_help
    ;;
  *)
    print_status "${RED}" "ERROR: Unknown command '${1:-}'"
    show_help
    exit 1
    ;;
esac
EOF
  chmod +x "$mock_script"
}


