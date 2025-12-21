#!/bin/bash
# GeoServer Configuration Workspace Functions
# Functions for managing GeoServer workspaces and namespaces
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08

# Function to check if GeoServer is configured
# Returns 0 if configured (workspace and datastore exist), 1 otherwise
is_geoserver_configured() {
 local WORKSPACE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}"
 local DATASTORE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}"
 local TEMP_FILE="${TMP_DIR}/geoserver_check_$$.tmp"
 local HTTP_CODE
 local WORKSPACE_EXISTS=false
 local DATASTORE_EXISTS=false

 # Check if workspace exists (verify HTTP status code is 200)
 HTTP_CODE=$(curl -s -o "${TEMP_FILE}" -w "%{http_code}" --connect-timeout 10 --max-time 30 \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  "${WORKSPACE_URL}" 2> /dev/null)

 if [[ "${HTTP_CODE}" == "200" ]]; then
  # Check if response contains workspace name (verify it's not empty or error)
  if [[ -s "${TEMP_FILE}" ]] && grep -q "\"name\".*\"${GEOSERVER_WORKSPACE}\"" "${TEMP_FILE}" 2> /dev/null; then
   WORKSPACE_EXISTS=true
  fi
 fi

 # Check if datastore exists (only if workspace exists)
 if [[ "${WORKSPACE_EXISTS}" == "true" ]]; then
  HTTP_CODE=$(curl -s -o "${TEMP_FILE}" -w "%{http_code}" --connect-timeout 10 --max-time 30 \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   "${DATASTORE_URL}" 2> /dev/null)

  if [[ "${HTTP_CODE}" == "200" ]]; then
   # Check if response contains datastore name (verify it's not empty or error)
   if [[ -s "${TEMP_FILE}" ]] && grep -q "\"name\".*\"${GEOSERVER_STORE}\"" "${TEMP_FILE}" 2> /dev/null; then
    DATASTORE_EXISTS=true
   fi
  fi
 fi

 rm -f "${TEMP_FILE}" 2> /dev/null || true

 # Consider configured if workspace and datastore exist
 # Layers are optional (they may fail to create but configuration is still valid)
 if [[ "${WORKSPACE_EXISTS}" == "true" ]] && [[ "${DATASTORE_EXISTS}" == "true" ]]; then
  return 0
 else
  return 1
 fi
}

# Function to create workspace
create_workspace() {
 print_status "${BLUE}" "🏗️  Creating GeoServer workspace..."

 # Check if workspace already exists
 local WORKSPACE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}"
 local CHECK_HTTP_CODE
 CHECK_HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${WORKSPACE_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace '${GEOSERVER_WORKSPACE}' already exists"
  return 0
 fi

 # Workspace doesn't exist, create it
 local WORKSPACE_DATA="{
   \"workspace\": {
     \"name\": \"${GEOSERVER_WORKSPACE}\",
     \"isolated\": false
   }
 }"

 local TEMP_RESPONSE_FILE="${TMP_DIR}/workspace_response_$$.tmp"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
  -X POST \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${WORKSPACE_DATA}" \
  "${GEOSERVER_URL}/rest/workspaces" 2> /dev/null | tail -1)

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ Workspace '${GEOSERVER_WORKSPACE}' created"
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 elif [[ "${HTTP_CODE}" == "409" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace '${GEOSERVER_WORKSPACE}' already exists"
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 else
  print_status "${RED}" "❌ ERROR: Failed to create workspace (HTTP ${HTTP_CODE})"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response:"
   echo "${RESPONSE_BODY}" | head -10 | sed 's/^/      /'
  fi
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 1
 fi
}

# Function to create namespace
create_namespace() {
 print_status "${BLUE}" "🏷️  Creating GeoServer namespace..."

 # Check if namespace already exists
 # Note: GeoServer automatically creates a namespace when a workspace is created
 local NAMESPACE_CHECK_URL="${GEOSERVER_URL}/rest/namespaces/${GEOSERVER_WORKSPACE}"
 local CHECK_HTTP_CODE
 CHECK_HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${NAMESPACE_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ Namespace '${GEOSERVER_WORKSPACE}' already exists (created automatically with workspace)"
  return 0
 fi

 # Namespace doesn't exist, create it
 local NAMESPACE_DATA="{
   \"namespace\": {
     \"prefix\": \"${GEOSERVER_WORKSPACE}\",
     \"uri\": \"${GEOSERVER_NAMESPACE}\",
     \"isolated\": false
   }
 }"

 local TEMP_RESPONSE_FILE="${TMP_DIR}/namespace_response_$$.tmp"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
  -X POST \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${NAMESPACE_DATA}" \
  "${GEOSERVER_URL}/rest/namespaces" 2> /dev/null | tail -1)

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ Namespace '${GEOSERVER_WORKSPACE}' created"
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 elif [[ "${HTTP_CODE}" == "409" ]]; then
  print_status "${YELLOW}" "⚠️  Namespace '${GEOSERVER_WORKSPACE}' already exists"
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 else
  # Check if error message indicates it already exists (some GeoServer versions return 500 for this)
  if echo "${RESPONSE_BODY}" | grep -qi "already exists"; then
   print_status "${YELLOW}" "⚠️  Namespace '${GEOSERVER_WORKSPACE}' already exists"
   rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 0
  else
   print_status "${RED}" "❌ ERROR: Failed to create namespace (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]]; then
    print_status "${YELLOW}" "   Response:"
    echo "${RESPONSE_BODY}" | head -10 | sed 's/^/      /'
   fi
   rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 1
  fi
 fi
}

