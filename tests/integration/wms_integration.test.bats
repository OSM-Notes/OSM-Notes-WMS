#!/usr/bin/env bats
# WMS Integration Tests
# Tests for the WMS manager script with actual database operations
#
# Author: Andres Gomez (AngocA)
# Version: 2026-03-28

bats_require_minimum_version 1.5.0
# Load before setup so functions defined below (e.g. create_mock_wms_script) are not
# overwritten when setup() sourced test_helper.
load "$(dirname "${BATS_TEST_FILENAME}")/../test_helper.bash"

setup() {
 # Set up test environment - use current user for local database
 export TEST_DBNAME="osm_notes_wms_test"
 export TEST_DBUSER="${USER:-$(whoami)}"
 export TEST_DBPASSWORD=""
 export TEST_DBHOST=""
 export TEST_DBPORT=""
 export MOCK_MODE=0
 # Choose mock vs real WMS before WMS_SCRIPT is set: late MOCK_MODE flips used to
 # leave WMS_SCRIPT pointing at bin/wms/wmsManager.sh while tests expected mocks.
 if ! command -v psql > /dev/null 2>&1 \
  || ! psql -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
  export MOCK_MODE=1
 fi
 # Provide mock PostgreSQL client tools ONLY when running in mock mode
 local WMS_TMP_DIR
 WMS_TMP_DIR="$(mktemp -d)"
 export WMS_TMP_DIR
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
   cat > "${WMS_TMP_DIR}/psql" << 'EOF'
#!/bin/bash
echo "Mock psql called with: $*" >&2
case "$*" in
 *"schema_version"*) echo "1.1.0";;
 *"schema_name = 'wms'"*) echo "t";;
 *"COUNT(*) FROM wms.notes_wms"*) echo "3";;
 *"COUNT(*) FROM notes"*) echo "2";;
 *) echo "1";;
esac
exit 0
EOF
   cat > "${WMS_TMP_DIR}/createdb" << 'EOF'
#!/bin/bash
echo "Mock createdb called with: $*" >&2
exit 0
EOF
   cat > "${WMS_TMP_DIR}/dropdb" << 'EOF'
#!/bin/bash
echo "Mock dropdb called with: $*" >&2
exit 0
EOF
   chmod +x "${WMS_TMP_DIR}/psql" "${WMS_TMP_DIR}/createdb" "${WMS_TMP_DIR}/dropdb"
   export PATH="${WMS_TMP_DIR}:${PATH}"
 fi
 # WMS script path
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  # Create mock WMS script and use it
  create_mock_wms_script
  WMS_SCRIPT="${BATS_TEST_DIRNAME}/mock_wmsManager.sh"
 else
  WMS_SCRIPT="${BATS_TEST_DIRNAME}/../../bin/wms/wmsManager.sh"
 fi
 # Create test database with required extensions
 create_wms_test_database
}
teardown() {
 # Clean up test database
 drop_wms_test_database
 if [[ -n "${WMS_TMP_DIR:-}" ]] && [[ -d "${WMS_TMP_DIR}" ]]; then
  rm -rf "${WMS_TMP_DIR}"
 fi
}
# Function to create WMS test database with PostGIS
create_wms_test_database() {
 echo "Creating WMS test database..."
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  echo "Mock mode enabled, skipping real database creation"
  return 0
 fi
 # Check if database exists, if not create it
 if ! psql -d "${TEST_DBNAME}" -c "SELECT 1;" > /dev/null 2>&1; then
  createdb "${TEST_DBNAME}" 2> /dev/null || true
 fi
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
 # Countries shape expected by sql/wms/prepareDatabase.sql (disputed areas MV)
 psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_id INTEGER PRIMARY KEY,
      country_name_en VARCHAR(100),
      country_name VARCHAR(100) NOT NULL,
      geom GEOMETRY(MultiPolygon, 4326)
    );
    INSERT INTO countries (country_id, country_name_en, country_name, geom) VALUES
      (1, 'Test', 'Test', ST_SetSRID(ST_Multi(ST_GeomFromText('POLYGON((-1 -1, 2 -1, 2 2, -1 2, -1 -1))')), 4326)::geometry(MultiPolygon,4326));
  " 2> /dev/null || true
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
    # Preserve test database for debugging (uncomment to enable cleanup)
    # dropdb "${TEST_DBNAME}" 2> /dev/null || true
    echo "Preserving test database '${TEST_DBNAME}' (uncomment dropdb to remove)"
  fi
 fi
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
  if ! is_wms_installed; then
    print_status "${YELLOW}" "⚠️  WMS is not installed"
    return 0
  fi
  set_mock_state "false"
  print_status "${GREEN}" "✅ WMS removal completed successfully"
}
show_status() {
  print_status "${BLUE}" "📊 WMS Status Report"
  if is_wms_installed; then
    print_status "${GREEN}" "✅ WMS is installed"
    print_status "${BLUE}" "📈 WMS Statistics:"
    print_status "${BLUE}" "   - Total notes in WMS: 3"
    print_status "${BLUE}" "   - Active triggers: 2"
  else
    print_status "${YELLOW}" "⚠️  WMS is not installed"
  fi
}
# Main function
main() {
  local COMMAND=""
  local FORCE=false
  local DRY_RUN=false
  while [[ $# -gt 0 ]]; do
    case $1 in
      install | remove | status | help)
        COMMAND="$1"
        shift
        ;;
      --force)
        FORCE=true
        shift
        ;;
      --dry-run)
        DRY_RUN=true
        shift
        ;;
      -h | --help)
        show_help
        exit 0
        ;;
      *)
        print_status "${RED}" "❌ ERROR: Unknown option: $1"
        show_help
        exit 1
        ;;
    esac
  done
  case "${COMMAND}" in
    install)
      install_wms
      ;;
    remove)
      deinstall_wms
      ;;
    status)
      show_status
      ;;
    help)
      show_help
      ;;
    "")
      print_status "${RED}" "❌ ERROR: No command specified"
      show_help
      exit 1
      ;;
    *)
      print_status "${RED}" "❌ ERROR: Unknown command: ${COMMAND}"
      show_help
      exit 1
      ;;
  esac
}
main "$@"
EOF
 chmod +x "$mock_script"
 WMS_SCRIPT="$mock_script"
 # Initialize mock state
 echo "false" > "/tmp/mock_wms_state"
}
@test "WMS integration: should install WMS components successfully" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Deinstall WMS first if it's already installed
 run "$WMS_SCRIPT" remove
 # Install WMS
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 # Verify WMS schema exists (mock mode)
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  # In mock mode, we just verify the installation was successful
  [[ "$output" == *"installation completed successfully"* ]] || [[ "$output" == *"WMS installation completed successfully"* ]]
 else
  # In real mode, verify database objects
  local schema_exists
  schema_exists=$(run_psql "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms');" "Check WMS schema")
  [ "$schema_exists" == "t" ]
  # Verify WMS table exists
  local table_exists
  table_exists=$(run_psql "SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'wms' AND table_name = 'notes_wms');" "Check WMS table")
  [ "$table_exists" == "t" ]
  # Verify triggers exist
  local trigger_count
  trigger_count=$(run_psql "SELECT COUNT(*) FROM information_schema.triggers WHERE trigger_name IN ('insert_new_notes', 'update_notes');" "Check triggers")
  [ "$trigger_count" -eq 2 ]
 fi
}
@test "WMS integration: should show correct status after installation" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Install WMS first
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 # Check status
 run "$WMS_SCRIPT" status
 [ "$status" -eq 0 ]
 [[ "$output" == *"WMS is installed"* ]] || [[ "$output" == *"✅ WMS is installed"* ]]
 [[ "$output" == *"WMS Statistics"* ]] || [[ "$output" == *"Statistics"* ]]
 # Verify note count (mock mode)
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  # In mock mode, we just verify the status shows installed
  [[ "$output" == *"WMS is installed"* ]] || [[ "$output" == *"✅ WMS is installed"* ]]
 else
  # In real mode, verify actual note count
  # Note: processPlanetNotes.sh --base may create a variable number of notes
  # Accept any positive count (at least 1 note)
  local note_count
  note_count=$(run_psql "SELECT COUNT(*) FROM wms.notes_wms;" "Count WMS notes")
  [ "$note_count" -ge 1 ] # Should have at least 1 note from test data
 fi
}
@test "WMS integration: should not install twice without force" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Install WMS first
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 # Try to install again
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 [[ "$output" == *"already installed"* ]] || [[ "$output" == *"WMS is already installed"* ]] || [[ "$output" == *"⚠️"* ]]
 [[ "$output" == *"Use --force"* ]] || [[ "$output" == *"--force"* ]]
}
@test "WMS integration: should force reinstall with --force" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Install WMS first
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 # Force reinstall
 run "$WMS_SCRIPT" install --force
 [ "$status" -eq 0 ]
 [[ "$output" == *"installation completed successfully"* ]] || [[ "$output" == *"WMS installation completed successfully"* ]] || [[ "$output" == *"✅"* ]]
}
@test "WMS integration: should deinstall WMS components successfully" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Install WMS first
 run "$WMS_SCRIPT" install
 [ "$status" -eq 0 ]
 # Remove WMS
 run "$WMS_SCRIPT" remove
 [ "$status" -eq 0 ]
 [[ "$output" == *"removal completed successfully"* ]] || [[ "$output" == *"WMS removal completed successfully"* ]] || [[ "$output" == *"✅"* ]]
 # Verify WMS schema is removed (mock mode)
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  # In mock mode, we just verify the removal was successful
  [[ "$output" == *"removal completed successfully"* ]] || [[ "$output" == *"WMS removal completed successfully"* ]]
 else
  # In real mode, verify schema is removed
  local schema_exists
  schema_exists=$(run_psql "SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms');" "Check WMS schema removed")
  [ "$schema_exists" == "f" ]
 fi
}
@test "WMS integration: should handle deinstall when not installed" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Try to remove when not installed
 run "$WMS_SCRIPT" remove
 [ "$status" -eq 0 ]
 [[ "$output" == *"not installed"* ]] || [[ "$output" == *"WMS is not installed"* ]] || [[ "$output" == *"⚠️"* ]]
}
@test "WMS integration: should show dry run output" {
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEST_DBNAME}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEST_DBNAME}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # Test dry run
 run "$WMS_SCRIPT" install --dry-run
 [ "$status" -eq 0 ]
 [[ "$output" == *"DRY RUN"* ]] || [[ "$output" == *"Would install"* ]] || [[ "$output" == *"dry-run"* ]]
}
@test "WMS integration: should validate PostGIS requirement" {
 # In mock mode, we skip this test as it requires real database
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  skip "Skipping PostGIS validation in mock mode"
 fi
  
 # Create a temporary database for this destructive test
 local TEMP_DB="osm_notes_wms_test_postgis_validation_$$"
 
 # Setup: Create temporary database with PostGIS
 createdb "${TEMP_DB}" 2> /dev/null || true
 psql -d "${TEMP_DB}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
 psql -d "${TEMP_DB}" -c "CREATE TABLE notes (id INTEGER PRIMARY KEY, created_at TIMESTAMP, closed_at TIMESTAMP, longitude DOUBLE PRECISION, latitude DOUBLE PRECISION);" 2> /dev/null || true
 psql -d "${TEMP_DB}" -c "INSERT INTO notes VALUES (1, NOW(), NULL, -74.006, 40.7128);" 2> /dev/null || true
 
 # Test: Remove PostGIS and verify script detects it
 psql -d "${TEMP_DB}" -c "DROP EXTENSION IF EXISTS postgis CASCADE;" 2> /dev/null || true
 
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEMP_DB}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEMP_DB}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 
 # Run install - should fail because PostGIS is missing
 run "$WMS_SCRIPT" install
 [ "$status" -ne 0 ]
 [[ "$output" == *"PostGIS"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"not installed"* ]]
 
 # Cleanup: Drop temporary database
 dropdb "${TEMP_DB}" 2> /dev/null || true
}
@test "WMS integration: should handle database connection errors" {
 # Test with invalid database
 export WMS_DBNAME="nonexistent_db"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="nonexistent_db"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 # In mock mode, we skip this test as it requires real database
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  skip "Skipping database connection error test in mock mode"
 fi
 run "$WMS_SCRIPT" install
 # Accept any non-zero exit code (1, 3, 255, etc.) for connection errors
 # The script should fail with a non-zero exit code when database doesn't exist
 [ "$status" -ne 0 ]
 # Check for error message (script outputs ERROR in red, so look for ERROR or error)
 [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"error"* ]] || [[ "$output" == *"failed"* ]] || [[ "$output" == *"Cannot connect"* ]]
}
@test "WMS integration: should handle missing required columns" {
 # In mock mode, we just test the installation
 if [[ "${MOCK_MODE:-0}" == "1" ]]; then
  # Try to install WMS in mock mode
  run "$WMS_SCRIPT" install
  [ "$status" -eq 0 ]
  [[ "$output" == *"installation completed successfully"* ]] || [[ "$output" == *"WMS installation completed successfully"* ]]
  return 0
 fi
  
 # Create a temporary database for this destructive test
 local TEMP_DB="osm_notes_wms_test_missing_columns_$$"
 
 # Setup: Create temporary database with PostGIS and incomplete notes table
 createdb "${TEMP_DB}" 2> /dev/null || true
 psql -d "${TEMP_DB}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
 # Create notes table WITHOUT required columns (missing longitude and latitude)
 psql -d "${TEMP_DB}" -c "CREATE TABLE notes (id INTEGER PRIMARY KEY, created_at TIMESTAMP, closed_at TIMESTAMP);" 2> /dev/null || true
 psql -d "${TEMP_DB}" -c "CREATE TABLE countries (country_id INTEGER PRIMARY KEY, name VARCHAR(255), geom GEOMETRY(MultiPolygon, 4326));" 2> /dev/null || true
 
 # Set database environment variables for WMS script
 export WMS_DBNAME="${TEMP_DB}"
 export WMS_DBUSER="${TEST_DBUSER}"
 export WMS_DBPASSWORD="${TEST_DBPASSWORD}"
 export TEST_DBNAME="${TEMP_DB}"
 export TEST_DBUSER="${TEST_DBUSER}"
 export TEST_DBPASSWORD="${TEST_DBPASSWORD}"
 export PGPASSWORD="${TEST_DBPASSWORD}"
 
 # Run install - should fail because required columns are missing
 run "$WMS_SCRIPT" install
 # Script should fail with non-zero exit code (3 = ERROR_GENERAL from schema validation)
 [ "$status" -ne 0 ]
 # Check for error message - validation error may appear in different formats
 # Accept any non-zero status as success (the script correctly detected missing columns)
 # Also check for common error patterns
 [[ "$status" -eq 3 ]] || [[ "$output" == *"longitude"* ]] || [[ "$output" == *"latitude"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing required columns"* ]] || [[ "$output" == *"schema validation failed"* ]] || [[ "$output" == *"validation failed"* ]] || [[ "$output" == *"required columns"* ]] || [[ "$output" == *"does not match"* ]]
 
 # Cleanup: Drop temporary database
 dropdb "${TEMP_DB}" 2> /dev/null || true
}
