#!/usr/bin/env bats
# Schema Verification Edge Cases Tests
# Tests for edge cases in schema verification
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08

setup() {
  # Load test helper functions
  load "${BATS_TEST_DIRNAME}/../test_helper.bash"
  
  # Set up test environment
  export TEST_DBNAME="osm_notes_schema_test"
  export TEST_DBUSER="${USER:-$(whoami)}"
  export TEST_DBPASSWORD=""
  export TEST_DBHOST=""
  export TEST_DBPORT=""
  export MOCK_MODE=0
  
  # SQL script path
  VERIFY_SCHEMA_SQL="${BATS_TEST_DIRNAME}/../../sql/wms/verifySchema.sql"
  
  # Create test database
  create_test_database
}

teardown() {
  # Clean up test database
  drop_test_database
}

# Function to create test database
create_test_database() {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    return 0
  fi
  
  # Check if PostgreSQL is available
  if ! psql -d postgres -c "SELECT 1;" > /dev/null 2>&1; then
    skip "PostgreSQL not available"
  fi
  
  # Create database if it doesn't exist
  if ! psql -d "${TEST_DBNAME}" -c "SELECT 1;" > /dev/null 2>&1; then
    createdb "${TEST_DBNAME}" 2> /dev/null || true
  fi
  
  # Enable PostGIS extension
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
}

# Function to drop test database
drop_test_database() {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    return 0
  fi
  
  dropdb "${TEST_DBNAME}" 2> /dev/null || true
}

# ============================================================================
# PostGIS Extension Edge Cases
# ============================================================================

@test "Schema verification edge case: should detect missing PostGIS extension" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Drop PostGIS extension if it exists
  psql -d "${TEST_DBNAME}" -c "DROP EXTENSION IF EXISTS postgis CASCADE;" 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"PostGIS"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"required"* ]] || [[ "$output" == *"❌"* ]]
}

# ============================================================================
# Table Existence Edge Cases
# ============================================================================

@test "Schema verification edge case: should detect missing notes table" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Ensure notes table doesn't exist
  psql -d "${TEST_DBNAME}" -c "DROP TABLE IF EXISTS notes CASCADE;" 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"notes"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"not found"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing countries table" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table but not countries table
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  psql -d "${TEST_DBNAME}" -c "DROP TABLE IF EXISTS countries CASCADE;" 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"countries"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"not found"* ]] || [[ "$output" == *"❌"* ]]
}

# ============================================================================
# Column Existence Edge Cases
# ============================================================================

@test "Schema verification edge case: should detect missing note_id column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table without note_id column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"note_id"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing longitude column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table without longitude column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"longitude"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing latitude column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table without latitude column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"latitude"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing created_at column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table without created_at column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"created_at"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing closed_at column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table without closed_at column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"closed_at"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

# ============================================================================
# Countries Table Column Edge Cases
# ============================================================================

@test "Schema verification edge case: should detect missing country_id column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create countries table without country_id column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_name_en TEXT,
      geom GEOMETRY(POLYGON, 4326)
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"country_id"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing country_name_en column" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create countries table without country_name_en column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_id INTEGER PRIMARY KEY,
      geom GEOMETRY(POLYGON, 4326)
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"country_name_en"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

@test "Schema verification edge case: should detect missing geom column in countries" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create countries table without geom column
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_id INTEGER PRIMARY KEY,
      country_name_en TEXT
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  [ "$status" -ne 0 ]
  [[ "$output" == *"geom"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]] || [[ "$output" == *"❌"* ]]
}

# ============================================================================
# Data Edge Cases
# ============================================================================

@test "Schema verification edge case: should warn about empty notes table" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create empty notes table
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Create empty countries table
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_id INTEGER PRIMARY KEY,
      country_name_en TEXT,
      geom GEOMETRY(POLYGON, 4326)
    );
  " 2> /dev/null || true
  
  # Run verification script
  run psql -d "${TEST_DBNAME}" -f "${VERIFY_SCHEMA_SQL}" 2>&1
  # Should succeed but warn about empty tables
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  [[ "$output" == *"empty"* ]] || [[ "$output" == *"WARNING"* ]] || [[ "$output" == *"⚠️"* ]] || [[ "$output" == *"0 records"* ]]
}

@test "Schema verification edge case: should succeed with valid schema and data" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table with data
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      longitude DOUBLE PRECISION,
      latitude DOUBLE PRECISION
    );
    INSERT INTO notes (note_id, created_at, longitude, latitude) VALUES
    (1, NOW(), -74.006, 40.7128),
    (2, NOW(), -118.2437, 34.0522);
  " 2> /dev/null || true
  
  # Create countries table with data
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS countries CASCADE;
    CREATE TABLE countries (
      country_id INTEGER PRIMARY KEY,
      country_name_en TEXT,
      geom GEOMETRY(POLYGON, 4326)
    );
    INSERT INTO countries (country_id, country_name_en, geom) VALUES
    (1, 'Test Country', ST_MakeEnvelope(-180, -90, 180, 90, 4326));
  " 2> /dev/null || true
  
  # Run verification script
  run psql -d "${TEST_DBNAME}" -f "${VERIFY_SCHEMA_SQL}" 2>&1
  # Should succeed
  [ "$status" -eq 0 ]
  [[ "$output" == *"✅"* ]] || [[ "$output" == *"successfully"* ]] || [[ "$output" == *"completed"* ]]
}

# ============================================================================
# Column Name Edge Cases (lon/lat vs longitude/latitude)
# ============================================================================

@test "Schema verification edge case: should reject lon/lat column names" {
  if [[ "${MOCK_MODE:-0}" == "1" ]]; then
    skip "Skipping in mock mode"
  fi
  
  # Ensure PostGIS is installed
  psql -d "${TEST_DBNAME}" -c "CREATE EXTENSION IF NOT EXISTS postgis;" 2> /dev/null || true
  
  # Create notes table with lon/lat instead of longitude/latitude
  psql -d "${TEST_DBNAME}" -c "
    DROP TABLE IF EXISTS notes CASCADE;
    CREATE TABLE notes (
      note_id INTEGER PRIMARY KEY,
      created_at TIMESTAMP,
      closed_at TIMESTAMP,
      lon DOUBLE PRECISION,
      lat DOUBLE PRECISION
    );
  " 2> /dev/null || true
  
  # Run verification script with ON_ERROR_STOP to ensure errors are caught
  run psql -d "${TEST_DBNAME}" -v ON_ERROR_STOP=1 -f "${VERIFY_SCHEMA_SQL}" 2>&1
  # Should fail - schema must match OSM-Notes-Ingestion (longitude/latitude)
  [ "$status" -ne 0 ]
  [[ "$output" == *"longitude"* ]] || [[ "$output" == *"latitude"* ]] || [[ "$output" == *"ERROR"* ]] || [[ "$output" == *"Missing"* ]]
}

