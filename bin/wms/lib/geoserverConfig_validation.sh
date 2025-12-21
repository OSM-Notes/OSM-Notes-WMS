#!/bin/bash
# GeoServer Configuration Validation Functions
# Prerequisites validation for GeoServer configuration
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08

# Function to validate prerequisites
validate_prerequisites() {
 print_status "${BLUE}" "🔍 Validating prerequisites..."

 # Check if curl is available
 if ! command -v curl &> /dev/null; then
  print_status "${RED}" "❌ ERROR: curl is not installed"
  exit "${ERROR_MISSING_LIBRARY}"
 fi

 # Check if jq is available
 if ! command -v jq &> /dev/null; then
  print_status "${RED}" "❌ ERROR: jq is not installed"
  exit 1
 fi

 # Check if GeoServer is accessible
 # Try to connect to GeoServer with retry logic and verify HTTP status code
 local GEOSERVER_STATUS_URL="${GEOSERVER_URL}/rest/about/status"
 local TEMP_STATUS_FILE="${TMP_DIR}/geoserver_status_$$.tmp"
 local TEMP_ERROR_FILE="${TMP_DIR}/geoserver_error_$$.tmp"
 local MAX_RETRIES=3
 local RETRY_COUNT=0
 local CONNECTED=false
 local HTTP_CODE

 while [[ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]]; do
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_STATUS_FILE}" \
   --connect-timeout 10 --max-time 30 \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   "${GEOSERVER_STATUS_URL}" 2> "${TEMP_ERROR_FILE}")

  if [[ "${HTTP_CODE}" == "200" ]]; then
   if [[ -f "${TEMP_STATUS_FILE}" ]] && [[ -s "${TEMP_STATUS_FILE}" ]]; then
    CONNECTED=true
    break
   fi
  elif [[ "${HTTP_CODE}" == "401" ]]; then
   # Authentication failed - don't retry, show error immediately
   local ERROR_MSG
   ERROR_MSG=$(cat "${TEMP_ERROR_FILE}" 2> /dev/null || echo "Authentication failed")
   rm -f "${TEMP_STATUS_FILE}" "${TEMP_ERROR_FILE}" 2> /dev/null || true
   print_status "${RED}" "❌ ERROR: Authentication failed (HTTP 401)"
   print_status "${YELLOW}" "   Invalid credentials for GeoServer at ${GEOSERVER_URL}"
   print_status "${YELLOW}" "   User: ${GEOSERVER_USER}"
   print_status "${YELLOW}" "   💡 Check credentials in etc/wms.properties.sh:"
   print_status "${YELLOW}" "      GEOSERVER_USER=\"${GEOSERVER_USER}\""
   print_status "${YELLOW}" "      GEOSERVER_PASSWORD=\"your_password\""
   print_status "${YELLOW}" "   💡 Or set environment variables:"
   print_status "${YELLOW}" "      export GEOSERVER_USER=admin"
   print_status "${YELLOW}" "      export GEOSERVER_PASSWORD=your_password"
   exit "${ERROR_GENERAL}"
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   # GeoServer URL might be wrong
   print_status "${YELLOW}" "⚠️  GeoServer endpoint not found (HTTP 404) - checking URL..."
  fi

  RETRY_COUNT=$((RETRY_COUNT + 1))
  if [[ ${RETRY_COUNT} -lt ${MAX_RETRIES} ]]; then
   sleep 2
  fi
 done

 rm -f "${TEMP_STATUS_FILE}" "${TEMP_ERROR_FILE}" 2> /dev/null || true

 if [[ "${CONNECTED}" != "true" ]]; then
  print_status "${RED}" "❌ ERROR: Cannot connect to GeoServer at ${GEOSERVER_URL}"
  if [[ -n "${HTTP_CODE}" ]]; then
   print_status "${RED}" "   HTTP Status Code: ${HTTP_CODE}"
   if [[ "${HTTP_CODE}" == "000" ]]; then
    print_status "${YELLOW}" "   Connection failed - GeoServer may not be running or URL is incorrect"
    if [[ -f "${TEMP_ERROR_FILE}" ]]; then
     local CURL_ERROR
     CURL_ERROR=$(cat "${TEMP_ERROR_FILE}" 2> /dev/null || echo "")
     if [[ -n "${CURL_ERROR}" ]]; then
      print_status "${YELLOW}" "   Error details: ${CURL_ERROR}"
     fi
    fi
   fi
  fi
  print_status "${YELLOW}" "💡 Make sure GeoServer is running and credentials are correct"
  print_status "${YELLOW}" "💡 You can override the URL with: export GEOSERVER_URL=https://geoserver.osm.lat/geoserver"
  print_status "${YELLOW}" "💡 Or set it in etc/wms.properties.sh: GEOSERVER_URL=\"https://geoserver.osm.lat/geoserver\""
  print_status "${YELLOW}" "💡 To find GeoServer port, try: netstat -tlnp | grep java | grep LISTEN"
  exit "${ERROR_GENERAL}"
 fi

 # Check if PostgreSQL is accessible
 local PSQL_CMD="psql -d \"${DBNAME}\""
 if [[ -n "${DBHOST}" ]]; then
  PSQL_CMD="psql -h \"${DBHOST}\" -d \"${DBNAME}\""
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

 # Test connection and capture error message
 # Note: This validation is optional - GeoServer will validate the connection when creating the datastore
 # If password is not provided, skip validation (GeoServer may have different credentials)
 if [[ -n "${DBPASSWORD}" ]]; then
  # Ensure PGPASSWORD is set and exported for psql
  export PGPASSWORD="${DBPASSWORD}"
  local TEMP_ERROR_FILE="${TMP_DIR}/psql_error_$$.tmp"
  # Use PGPASSWORD environment variable to avoid interactive password prompt
  if ! eval "${PSQL_CMD} -c \"SELECT 1;\" > /dev/null 2> \"${TEMP_ERROR_FILE}\""; then
   local ERROR_MSG
   ERROR_MSG=$(cat "${TEMP_ERROR_FILE}" 2> /dev/null | head -1 || echo "Unknown error")
   rm -f "${TEMP_ERROR_FILE}" 2> /dev/null || true
   unset PGPASSWORD 2> /dev/null || true

   print_status "${YELLOW}" "⚠️  WARNING: Cannot validate PostgreSQL connection to '${DBNAME}'"
   print_status "${YELLOW}" "   Error: ${ERROR_MSG}"
   print_status "${YELLOW}" "   This is not fatal - GeoServer will validate the connection when creating the datastore"
   if [[ -n "${DBHOST}" ]]; then
    print_status "${YELLOW}" "   Host: ${DBHOST}"
   fi
   if [[ -n "${DBPORT}" ]]; then
    print_status "${YELLOW}" "   Port: ${DBPORT}"
   fi
   if [[ -n "${DBUSER}" ]]; then
    print_status "${YELLOW}" "   User: ${DBUSER}"
   fi
  else
   print_status "${GREEN}" "✅ PostgreSQL connection validated"
   unset PGPASSWORD 2> /dev/null || true
  fi
 else
  print_status "${YELLOW}" "⚠️  Skipping PostgreSQL validation (no password provided)"
  print_status "${YELLOW}" "   GeoServer will validate the connection when creating the datastore"
  print_status "${YELLOW}" "   💡 To enable validation, set WMS_DBPASSWORD or DBPASSWORD environment variable"
 fi

 # Check if WMS schema exists (only if we can connect to PostgreSQL)
 if [[ -n "${DBPASSWORD}" ]]; then
  # Ensure PGPASSWORD is set for the schema check
  export PGPASSWORD="${DBPASSWORD}"
  if ! eval "${PSQL_CMD} -c \"SELECT EXISTS(SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms');\"" 2> /dev/null | grep -q 't'; then
   unset PGPASSWORD 2> /dev/null || true
   print_status "${RED}" "❌ ERROR: WMS schema not found. Please install WMS components first:"
   print_status "${YELLOW}" "   bin/wms/wmsManager.sh install"
   exit "${ERROR_GENERAL}"
  fi
  unset PGPASSWORD 2> /dev/null || true
 else
  print_status "${YELLOW}" "⚠️  Skipping WMS schema validation (no password provided)"
  print_status "${YELLOW}" "   Make sure WMS components are installed: bin/wms/wmsManager.sh install"
 fi

 print_status "${GREEN}" "✅ Prerequisites validated"
}

