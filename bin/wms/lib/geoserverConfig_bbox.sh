#!/bin/bash
# GeoServer Configuration Bounding Box Functions
# Functions for calculating bounding boxes from PostgreSQL tables/views
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
# Function to calculate bounding box from PostgreSQL table/view
# Returns bounding box as comma-separated values: minx,miny,maxx,maxy
# If calculation fails, returns default worldwide bounding box
calculate_bbox_from_table() {
 local TABLE_NAME="${1}"

 # Query PostgreSQL to get the actual bounding box of the data
 # Handle both regular tables and views
 # Handle schema-qualified table names (e.g., "wms.table" or just "table")
 # If table name doesn't contain a dot, assume it's in the default schema
 local SCHEMA_QUALIFIED_TABLE="${TABLE_NAME}"
 if ! echo "${TABLE_NAME}" | grep -q '\\.'; then
  # Table name without schema - use public schema for views, wms for others
  if echo "${TABLE_NAME}" | grep -qi "view"; then
   SCHEMA_QUALIFIED_TABLE="public.${TABLE_NAME}"
  else
   SCHEMA_QUALIFIED_TABLE="wms.${TABLE_NAME}"
  fi
 fi
 local BBOX_QUERY="SELECT ST_XMin(bbox)::numeric, ST_YMin(bbox)::numeric, ST_XMax(bbox)::numeric, ST_YMax(bbox)::numeric FROM (SELECT ST_Extent(geometry)::box2d as bbox FROM ${SCHEMA_QUALIFIED_TABLE} WHERE geometry IS NOT NULL) t;"

 local PSQL_CMD="psql -d \"${DBNAME}\" -t -A"
 if [[ -n "${DBHOST}" ]]; then
  PSQL_CMD="psql -h \"${DBHOST}\" -d \"${DBNAME}\" -t -A"
 fi
 if [[ -n "${DBUSER}" ]]; then
  PSQL_CMD="${PSQL_CMD} -U \"${DBUSER}\""
 fi
 if [[ -n "${DBPORT}" ]]; then
  PSQL_CMD="${PSQL_CMD} -p \"${DBPORT}\""
 fi
 if [[ -n "${DBPASSWORD}" ]]; then
  export PGPASSWORD="${DBPASSWORD}"
 else
  unset PGPASSWORD 2> /dev/null || true
 fi

 local BBOX_RESULT
 local TEMP_ERROR="${TMP_DIR}/bbox_error_$$.tmp"
 # PostgreSQL returns values separated by | when using -A, convert to comma-separated
 BBOX_RESULT=$(eval "${PSQL_CMD} -c \"${BBOX_QUERY}\"" 2> "${TEMP_ERROR}" | tr '|' ',' | tr -d ' ' || echo "")

 if [[ -n "${DBPASSWORD}" ]]; then
  unset PGPASSWORD 2> /dev/null || true
 fi

 # Check for errors (table might not exist, might be empty, or query might fail)
 if [[ -s "${TEMP_ERROR}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
  local ERROR_MSG
  ERROR_MSG=$(head -3 "${TEMP_ERROR}" 2> /dev/null | tr '\n' ' ' || echo "")
  if [[ -n "${ERROR_MSG}" ]] && ! echo "${ERROR_MSG}" | grep -q "0 rows"; then
   print_status "${YELLOW}" "   ⚠️  Warning calculating bbox for ${TABLE_NAME}: ${ERROR_MSG}"
  fi
 fi
 rm -f "${TEMP_ERROR}" 2> /dev/null || true

 # If we got a valid bounding box, use it; otherwise use defaults
 # Valid bbox format: number,number,number,number (four decimal numbers)
 if [[ -n "${BBOX_RESULT}" ]] && echo "${BBOX_RESULT}" | grep -qE '^-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+$'; then
  echo "${BBOX_RESULT}"
 else
  # Return default bounding box (worldwide) - GeoServer will recalculate from data
  # This happens if table is empty, query fails, or result is invalid
  echo "${WMS_BBOX_MINX},${WMS_BBOX_MINY},${WMS_BBOX_MAXX},${WMS_BBOX_MAXY}"
 fi
}
