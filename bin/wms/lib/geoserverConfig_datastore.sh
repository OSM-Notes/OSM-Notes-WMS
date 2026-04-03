#!/bin/bash
# GeoServer Configuration Datastore Functions
# Functions for managing GeoServer datastores
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
# Function to create or update datastore
create_datastore() {
 print_status "${BLUE}" "🗄️  Creating/updating GeoServer datastore..."

 # Check if datastore already exists
 local DATASTORE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}"
 local CHECK_RESPONSE
 CHECK_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${DATASTORE_CHECK_URL}" 2> /dev/null)
 local CHECK_HTTP_CODE
 CHECK_HTTP_CODE=$(echo "${CHECK_RESPONSE}" | tail -1)

 # Note: We specify 'public' as default schema since views are created there
 # SQL views can still access other schemas (like 'wms') using fully qualified names
 # IMPORTANT: GeoServer requires database user and password (cannot use peer authentication)
 # These credentials are stored in GeoServer's datastore configuration
 # The user should have read-only permissions (typically 'geoserver' user)
 if [[ -z "${DBPASSWORD}" ]]; then
  print_status "${YELLOW}" "⚠️  WARNING: GEOSERVER_DBPASSWORD is unset"
  print_status "${YELLOW}" "   GeoServer datastore requires a password for database connection"
  print_status "${YELLOW}" "   Set GEOSERVER_DBPASSWORD in etc/wms.properties.sh"
  print_status "${YELLOW}" "   GeoServer will fail to connect without a password"
 fi
 local DATASTORE_DATA="{
   \"dataStore\": {
     \"name\": \"${GEOSERVER_STORE}\",
     \"type\": \"PostGIS\",
     \"enabled\": true,
     \"connectionParameters\": {
       \"entry\": [
         {\"@key\": \"host\", \"$\": \"${DBHOST}\"},
         {\"@key\": \"port\", \"$\": \"${DBPORT}\"},
         {\"@key\": \"database\", \"$\": \"${DBNAME}\"},
         {\"@key\": \"schema\", \"$\": \"public\"},
         {\"@key\": \"user\", \"$\": \"${DBUSER}\"},
         {\"@key\": \"passwd\", \"$\": \"${DBPASSWORD}\"},
         {\"@key\": \"dbtype\", \"$\": \"postgis\"},
         {\"@key\": \"validate connections\", \"$\": \"true\"}
       ]
     }
   }
 }"

 local TEMP_RESPONSE_FILE="${TMP_DIR}/datastore_response_$$.tmp"
 local HTTP_CODE
 local DATASTORE_URL

 if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
  # Datastore exists, read current configuration to check for schema parameter
  local CURRENT_CONFIG
  CURRENT_CONFIG=$(echo "${CHECK_RESPONSE}" | head -n -1) # Remove HTTP code line
  if echo "${CURRENT_CONFIG}" | grep -q "\"schema\""; then
   print_status "${YELLOW}" "   ⚠️  Datastore has 'schema' parameter set, attempting to remove it..."
   # Try to delete and recreate to ensure clean state
   local DELETE_HTTP_CODE
   DELETE_HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${DATASTORE_CHECK_URL}" 2> /dev/null)
   if [[ "${DELETE_HTTP_CODE}" == "200" ]] || [[ "${DELETE_HTTP_CODE}" == "204" ]]; then
    print_status "${BLUE}" "   Old datastore removed, creating new one without schema parameter..."
    # Create new datastore
    DATASTORE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores"
    HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
     -X POST \
     -H "Content-Type: application/json" \
     -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
     -d "${DATASTORE_DATA}" \
     "${DATASTORE_URL}" 2> /dev/null | tail -1)
   else
    # If deletion fails (e.g., HTTP 403), try to update with explicit schema removal
    print_status "${YELLOW}" "   ⚠️  Could not remove datastore (HTTP ${DELETE_HTTP_CODE}), updating without schema parameter..."
    print_status "${YELLOW}" "   Note: If update fails, you may need to manually remove the 'schema' parameter from the datastore in GeoServer UI"
    DATASTORE_URL="${DATASTORE_CHECK_URL}"
    HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
     -X PUT \
     -H "Content-Type: application/json" \
     -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
     -d "${DATASTORE_DATA}" \
     "${DATASTORE_URL}" 2> /dev/null | tail -1)
   fi
  else
   # No schema parameter, just update normally
   print_status "${BLUE}" "   Datastore exists, updating connection parameters..."
   DATASTORE_URL="${DATASTORE_CHECK_URL}"
   HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -d "${DATASTORE_DATA}" \
    "${DATASTORE_URL}" 2> /dev/null | tail -1)
  fi
 else
  # Datastore doesn't exist, create it
  print_status "${BLUE}" "   Creating new datastore..."
  DATASTORE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores"
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
   -X POST \
   -H "Content-Type: application/json" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   -d "${DATASTORE_DATA}" \
   "${DATASTORE_URL}" 2> /dev/null | tail -1)
 fi

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
   print_status "${GREEN}" "✅ Datastore '${GEOSERVER_STORE}' updated"
  else
   print_status "${GREEN}" "✅ Datastore '${GEOSERVER_STORE}' created"
  fi
 elif [[ "${HTTP_CODE}" == "409" ]]; then
  print_status "${YELLOW}" "⚠️  Datastore '${GEOSERVER_STORE}' already exists"
 else
  print_status "${RED}" "❌ ERROR: Failed to create/update datastore (HTTP ${HTTP_CODE})"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -10)"
  fi
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 1
 fi

 rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
}
