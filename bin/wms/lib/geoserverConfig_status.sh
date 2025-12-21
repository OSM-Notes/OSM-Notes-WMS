#!/bin/bash
# GeoServer Configuration Status Functions
# Functions for checking GeoServer configuration status
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
# Function to show configuration status
show_status() {
 print_status "${BLUE}" "📊 GeoServer Configuration Status"

 # Debug: Show credentials being used (without exposing password)
 print_status "${BLUE}" "🔐 Using credentials: User='${GEOSERVER_USER}', Password='${GEOSERVER_PASSWORD:+***}' (${#GEOSERVER_PASSWORD} chars)"
 print_status "${BLUE}" "🌐 GeoServer URL: ${GEOSERVER_URL}"

 # Check if GeoServer is accessible
 local STATUS_RESPONSE
 STATUS_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${GEOSERVER_URL}/rest/about/status" 2> /dev/null)
 local HTTP_CODE
 HTTP_CODE=$(echo "${STATUS_RESPONSE}" | tail -1)

 if [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ GeoServer is accessible at ${GEOSERVER_URL}"
 else
  print_status "${RED}" "❌ GeoServer is not accessible (HTTP ${HTTP_CODE})"
  print_status "${YELLOW}" "   Check: ${GEOSERVER_URL}/rest/about/status"
  if [[ "${HTTP_CODE}" == "401" ]]; then
   print_status "${YELLOW}" "   💡 Authentication failed - check credentials in etc/wms.properties.sh"
   print_status "${YELLOW}" "   💡 Or set: export GEOSERVER_USER=admin GEOSERVER_PASSWORD=your_password"
  fi
  return 1
 fi

 # Check workspace
 local WORKSPACE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}"
 local WORKSPACE_RESPONSE
 WORKSPACE_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${WORKSPACE_URL}" 2> /dev/null)
 HTTP_CODE=$(echo "${WORKSPACE_RESPONSE}" | tail -1)

 if [[ "${HTTP_CODE}" == "200" ]] && echo "${WORKSPACE_RESPONSE}" | grep -q "\"name\".*\"${GEOSERVER_WORKSPACE}\""; then
  print_status "${GREEN}" "✅ Workspace '${GEOSERVER_WORKSPACE}' exists"
 else
  print_status "${YELLOW}" "⚠️  Workspace '${GEOSERVER_WORKSPACE}' not found (HTTP ${HTTP_CODE})"
  print_status "${YELLOW}" "   URL: ${WORKSPACE_URL}"
  print_status "${YELLOW}" "   List all workspaces: ${GEOSERVER_URL}/rest/workspaces.xml"
 fi

 # Check namespace
 local NAMESPACE_URL="${GEOSERVER_URL}/rest/namespaces/${GEOSERVER_WORKSPACE}"
 local NAMESPACE_RESPONSE
 NAMESPACE_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${NAMESPACE_URL}" 2> /dev/null)
 HTTP_CODE=$(echo "${NAMESPACE_RESPONSE}" | tail -1)

 if [[ "${HTTP_CODE}" == "200" ]] && echo "${NAMESPACE_RESPONSE}" | grep -q "\"prefix\".*\"${GEOSERVER_WORKSPACE}\""; then
  print_status "${GREEN}" "✅ Namespace '${GEOSERVER_WORKSPACE}' exists"
 else
  print_status "${YELLOW}" "⚠️  Namespace '${GEOSERVER_WORKSPACE}' not found (HTTP ${HTTP_CODE})"
 fi

 # Check datastore
 local DATASTORE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}"
 local DATASTORE_RESPONSE
 DATASTORE_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${DATASTORE_URL}" 2> /dev/null)
 HTTP_CODE=$(echo "${DATASTORE_RESPONSE}" | tail -1)

 if [[ "${HTTP_CODE}" == "200" ]] && echo "${DATASTORE_RESPONSE}" | grep -q "\"name\".*\"${GEOSERVER_STORE}\""; then
  print_status "${GREEN}" "✅ Datastore '${GEOSERVER_STORE}' exists"
 else
  print_status "${YELLOW}" "⚠️  Datastore '${GEOSERVER_STORE}' not found (HTTP ${HTTP_CODE})"
  print_status "${YELLOW}" "   URL: ${DATASTORE_URL}"
  print_status "${YELLOW}" "   List all datastores: ${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores.xml"
 fi

 # Check layers
 print_status "${BLUE}" ""
 print_status "${BLUE}" "📊 Checking layers..."
 local LAYERS=("notesopen" "notesclosed" "countries" "disputedareas")
 local LAYER_NAMES=("Open Notes" "Closed Notes" "Countries" "Disputed/Unclaimed Areas")
 local LAYER_COUNT=0
 for I in "${!LAYERS[@]}"; do
  local LAYER_NAME="${LAYERS[$I]}"
  local LAYER_DISPLAY="${LAYER_NAMES[$I]}"
  local LAYER_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
  local LAYER_RESPONSE
  LAYER_RESPONSE=$(curl -s -w "\n%{http_code}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${LAYER_URL}" 2> /dev/null)
  HTTP_CODE=$(echo "${LAYER_RESPONSE}" | tail -1)

  if [[ "${HTTP_CODE}" == "200" ]] && echo "${LAYER_RESPONSE}" | grep -q "\"name\".*\"${LAYER_NAME}\""; then
   print_status "${GREEN}" "✅ Layer '${LAYER_DISPLAY}' (${LAYER_NAME}) exists"
   ((LAYER_COUNT++))
  else
   print_status "${YELLOW}" "⚠️  Layer '${LAYER_DISPLAY}' (${LAYER_NAME}) not found (HTTP ${HTTP_CODE})"
  fi
 done

 if [[ ${LAYER_COUNT} -gt 0 ]]; then
  # Show WMS URL
  local WMS_URL="${GEOSERVER_URL}/wms"
  print_status "${BLUE}" ""
  print_status "${BLUE}" "🌐 WMS Service URL: ${WMS_URL}"
  print_status "${BLUE}" "📋 Available layers: ${LAYER_COUNT}/4"
 fi

 # Show web interface URLs
 print_status "${BLUE}" ""
 print_status "${BLUE}" "📱 GeoServer Web Interface:"
 print_status "${BLUE}" "   ${GEOSERVER_URL}/web"
 print_status "${BLUE}" "   Workspaces: ${GEOSERVER_URL}/web/?wicket:bookmarkablePage=:org.geoserver.web.data.workspace.WorkspacePage"
 print_status "${BLUE}" "   Stores: ${GEOSERVER_URL}/web/?wicket:bookmarkablePage=:org.geoserver.web.data.store.DataStoresPage"
 print_status "${BLUE}" "   Layers: ${GEOSERVER_URL}/web/?wicket:bookmarkablePage=:org.geoserver.web.data.layers.LayersPage"
 print_status "${BLUE}" "   Styles: ${GEOSERVER_URL}/web/?wicket:bookmarkablePage=:org.geoserver.web.data.style.StylesPage"
}
