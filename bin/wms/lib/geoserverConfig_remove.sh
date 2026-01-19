#!/bin/bash
# GeoServer Configuration Remove Functions
# Functions for removing GeoServer configuration
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
# Function to remove a layer
remove_layer() {
 local LAYER_NAME="${1}"

 # Remove layer
 local LAYER_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${LAYER_URL}" 2> /dev/null)
 if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
  print_status "${GREEN}" "✅ Layer '${LAYER_NAME}' removed"
 elif [[ "${HTTP_CODE}" == "404" ]]; then
  print_status "${YELLOW}" "⚠️  Layer '${LAYER_NAME}' not found (already removed)"
 else
  print_status "${YELLOW}" "⚠️  Layer '${LAYER_NAME}' removal failed (HTTP ${HTTP_CODE})"
 fi

 # Remove feature type
 local FEATURE_TYPE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes/${LAYER_NAME}"
 HTTP_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${FEATURE_TYPE_URL}" 2> /dev/null)
 if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
  print_status "${GREEN}" "✅ Feature type '${LAYER_NAME}' removed"
 elif [[ "${HTTP_CODE}" == "404" ]]; then
  print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' not found (already removed)"
 else
  print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' removal failed (HTTP ${HTTP_CODE})"
 fi
}
# Function to remove GeoServer configuration
remove_geoserver_config() {
 print_status "${BLUE}" "🗑️  Removing GeoServer configuration..."

 if [[ "${DRY_RUN:-false}" == "true" ]]; then
  print_status "${YELLOW}" "DRY RUN: Would remove GeoServer configuration"
  return 0
 fi

 # Validate required variables
 if [[ -z "${GEOSERVER_URL:-}" ]]; then
  print_status "${RED}" "❌ ERROR: GEOSERVER_URL is not set"
  print_status "${YELLOW}" "💡 Set it in etc/wms.properties.sh or as environment variable"
  return 1
 fi
 if [[ -z "${GEOSERVER_USER:-}" ]]; then
  print_status "${RED}" "❌ ERROR: GEOSERVER_USER is not set"
  print_status "${YELLOW}" "💡 Set it in etc/wms.properties.sh or as environment variable"
  return 1
 fi
 if [[ -z "${GEOSERVER_PASSWORD:-}" ]]; then
  print_status "${RED}" "❌ ERROR: GEOSERVER_PASSWORD is not set"
  print_status "${YELLOW}" "💡 Set it in etc/wms.properties.sh or as environment variable"
  return 1
 fi
 if [[ -z "${GEOSERVER_WORKSPACE:-}" ]]; then
  print_status "${RED}" "❌ ERROR: GEOSERVER_WORKSPACE is not set"
  print_status "${YELLOW}" "💡 Set it in etc/wms.properties.sh or as environment variable"
  return 1
 fi

 # Check if workspace exists first
 local WORKSPACE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}"
 local WORKSPACE_CHECK_CODE
 local TEMP_CURL_OUTPUT="${TMP_DIR}/workspace_check_$$.tmp"
 local TEMP_CURL_ERROR="${TMP_DIR}/workspace_check_error_$$.tmp"
 
 # Use a subshell to avoid set -e from stopping the script
 WORKSPACE_CHECK_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_CURL_OUTPUT}" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  --connect-timeout 5 --max-time 10 \
  "${WORKSPACE_CHECK_URL}" 2> "${TEMP_CURL_ERROR}" | tail -1) || WORKSPACE_CHECK_CODE="000"
 
 # Check if curl failed completely (connection error)
 if [[ "${WORKSPACE_CHECK_CODE}" == "000" ]] || [[ -z "${WORKSPACE_CHECK_CODE}" ]]; then
  local CURL_ERROR_MSG
  CURL_ERROR_MSG=$(cat "${TEMP_CURL_ERROR}" 2> /dev/null || echo "Connection failed")
  rm -f "${TEMP_CURL_OUTPUT}" "${TEMP_CURL_ERROR}" 2> /dev/null || true
  print_status "${RED}" "❌ ERROR: Failed to connect to GeoServer at ${GEOSERVER_URL}"
  print_status "${YELLOW}" "💡 Check if GeoServer is running and credentials are correct"
  if [[ -n "${CURL_ERROR_MSG}" ]] && [[ "${CURL_ERROR_MSG}" != "Connection failed" ]]; then
   print_status "${YELLOW}" "   Error: ${CURL_ERROR_MSG}"
  fi
  return 1
 fi
 rm -f "${TEMP_CURL_OUTPUT}" "${TEMP_CURL_ERROR}" 2> /dev/null || true

 if [[ "${WORKSPACE_CHECK_CODE}" != "200" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace '${GEOSERVER_WORKSPACE}' not found (HTTP ${WORKSPACE_CHECK_CODE})"
  print_status "${GREEN}" "✅ GeoServer configuration already removed (workspace does not exist)"
  return 0
 fi

 # Track what was successfully removed
 local TOTAL_LAYERS_REMOVED=0
 local TOTAL_LAYERS_FAILED=0
 local TOTAL_FEATURES_REMOVED=0
 local TOTAL_FEATURES_FAILED=0
 local TOTAL_STYLES_REMOVED=0
 local TOTAL_STYLES_FAILED=0
 local DATASTORE_REMOVED=false
 local WORKSPACE_REMOVED=false

 # Step 1: Remove all layers first (they depend on feature types)
 # GeoServer requires removing layers before feature types
 print_status "${BLUE}" "🗑️  Removing layers..."
 local LAYERS=("notesopen" "notesclosed" "countries" "disputedareas")
 for LAYER_NAME in "${LAYERS[@]}"; do
  local LAYER_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
  local HTTP_CODE
  local TEMP_RESPONSE="${TMP_DIR}/layer_delete_${LAYER_NAME}_$$.tmp"
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${LAYER_URL}" 2> /dev/null | tail -1)
  local RESPONSE_BODY
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
  rm -f "${TEMP_RESPONSE}" 2> /dev/null || true
  if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
   print_status "${GREEN}" "✅ Layer '${LAYER_NAME}' removed"
   TOTAL_LAYERS_REMOVED=$((TOTAL_LAYERS_REMOVED + 1))
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   # Layer doesn't exist, which is fine - count as removed
   TOTAL_LAYERS_REMOVED=$((TOTAL_LAYERS_REMOVED + 1))
  else
   print_status "${YELLOW}" "⚠️  Layer '${LAYER_NAME}' removal failed (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
    print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
   fi
   TOTAL_LAYERS_FAILED=$((TOTAL_LAYERS_FAILED + 1))
  fi
 done
 if [[ ${TOTAL_LAYERS_REMOVED} -eq 0 ]] && [[ ${TOTAL_LAYERS_FAILED} -eq 0 ]]; then
  print_status "${YELLOW}" "   No layers found to remove"
 elif [[ ${TOTAL_LAYERS_FAILED} -gt 0 ]]; then
  print_status "${YELLOW}" "   ⚠️  ${TOTAL_LAYERS_FAILED} layer(s) could not be removed - may need manual cleanup"
 fi

 # Wait a moment for GeoServer to process layer deletions
 sleep 1

 # Step 2: Remove all feature types (after layers are removed)
 # Check if datastore exists before trying to remove feature types
 local DATASTORE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}"
 local DATASTORE_EXISTS
 DATASTORE_EXISTS=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${DATASTORE_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${DATASTORE_EXISTS}" == "200" ]]; then
  print_status "${BLUE}" "🗑️  Removing feature types..."
  for LAYER_NAME in "${LAYERS[@]}"; do
   local FEATURE_TYPE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes/${LAYER_NAME}"
   local HTTP_CODE
   local TEMP_RESPONSE="${TMP_DIR}/featuretype_delete_${LAYER_NAME}_$$.tmp"
   # Use recurse=true to ensure all related resources are removed
   HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -X DELETE "${FEATURE_TYPE_URL}?recurse=true" 2> /dev/null | tail -1)
   local RESPONSE_BODY
   RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
   rm -f "${TEMP_RESPONSE}" 2> /dev/null || true
   if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
    print_status "${GREEN}" "✅ Feature type '${LAYER_NAME}' removed"
    TOTAL_FEATURES_REMOVED=$((TOTAL_FEATURES_REMOVED + 1))
   elif [[ "${HTTP_CODE}" == "404" ]]; then
    # Feature type doesn't exist, which is fine - count as removed
    TOTAL_FEATURES_REMOVED=$((TOTAL_FEATURES_REMOVED + 1))
   else
    print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' removal failed (HTTP ${HTTP_CODE})"
    if [[ -n "${RESPONSE_BODY}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
     print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
    fi
    TOTAL_FEATURES_FAILED=$((TOTAL_FEATURES_FAILED + 1))
   fi
  done
  if [[ ${TOTAL_FEATURES_REMOVED} -eq 0 ]] && [[ ${TOTAL_FEATURES_FAILED} -eq 0 ]]; then
   print_status "${YELLOW}" "   No feature types found to remove"
  elif [[ ${TOTAL_FEATURES_FAILED} -gt 0 ]]; then
   print_status "${YELLOW}" "   ⚠️  ${TOTAL_FEATURES_FAILED} feature type(s) could not be removed - may need manual cleanup"
  fi
 else
  print_status "${YELLOW}" "⚠️  Datastore not found, skipping feature type removal"
 fi

 # Step 3: Remove datastore (must be empty of feature types)
 # Check if datastore exists before attempting to remove
 local DATASTORE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}"
 local DATASTORE_CHECK_CODE
 DATASTORE_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${DATASTORE_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${DATASTORE_CHECK_CODE}" == "200" ]]; then
  print_status "${BLUE}" "🗑️  Removing datastore..."
  local DATASTORE_URL="${DATASTORE_CHECK_URL}"
  local TEMP_RESPONSE="${TMP_DIR}/datastore_delete_$$.tmp"
  local HTTP_CODE
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${DATASTORE_URL}" 2> /dev/null)
  local RESPONSE_BODY
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
  rm -f "${TEMP_RESPONSE}" 2> /dev/null || true

  if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
   print_status "${GREEN}" "✅ Datastore removed"
   DATASTORE_REMOVED=true
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   print_status "${YELLOW}" "⚠️  Datastore not found (already removed)"
   DATASTORE_REMOVED=true
  elif [[ "${HTTP_CODE}" == "403" ]]; then
   print_status "${YELLOW}" "⚠️  Datastore removal failed (HTTP 403 - Forbidden)"
   print_status "${YELLOW}" "   User '${GEOSERVER_USER}' may not have permission to delete datastores"
   print_status "${YELLOW}" "   Datastore may still have feature types - try removing them first"
   print_status "${YELLOW}" "   💡 You may need to use an admin user with full permissions"
   print_status "${YELLOW}" "   💡 Or remove the datastore manually from GeoServer UI"
   if [[ -n "${RESPONSE_BODY}" ]]; then
    print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
   fi
  elif [[ "${HTTP_CODE}" == "401" ]]; then
   print_status "${YELLOW}" "⚠️  Datastore removal failed (HTTP 401 - Authentication failed)"
   print_status "${YELLOW}" "   Check GeoServer credentials: ${GEOSERVER_USER}"
  else
   print_status "${YELLOW}" "⚠️  Datastore removal failed (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]]; then
    print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
   fi
  fi
 else
  print_status "${YELLOW}" "⚠️  Datastore not found (already removed or workspace was removed)"
 fi

 # Step 4: Remove styles (global resources, not workspace-specific)
 # Styles are global in GeoServer and must be removed explicitly
 print_status "${BLUE}" "🗑️  Removing styles..."

 # Get style names from SLD files and properties
 local STYLE_NAMES=()

 # Try to extract style names from SLD files
 if [[ -f "${WMS_STYLE_OPEN_FILE}" ]]; then
  local OPEN_STYLE_NAME
  OPEN_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_OPEN_FILE}")
  if [[ -n "${OPEN_STYLE_NAME}" ]]; then
   STYLE_NAMES+=("${OPEN_STYLE_NAME}")
  fi
  # Also try the property name
  if [[ -n "${WMS_STYLE_OPEN_NAME}" ]] && [[ "${OPEN_STYLE_NAME}" != "${WMS_STYLE_OPEN_NAME}" ]]; then
   STYLE_NAMES+=("${WMS_STYLE_OPEN_NAME}")
  fi
 fi

 if [[ -f "${WMS_STYLE_CLOSED_FILE}" ]]; then
  local CLOSED_STYLE_NAME
  CLOSED_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_CLOSED_FILE}")
  if [[ -n "${CLOSED_STYLE_NAME}" ]]; then
   STYLE_NAMES+=("${CLOSED_STYLE_NAME}")
  fi
  # Also try the property name
  if [[ -n "${WMS_STYLE_CLOSED_NAME}" ]] && [[ "${CLOSED_STYLE_NAME}" != "${WMS_STYLE_CLOSED_NAME}" ]]; then
   STYLE_NAMES+=("${WMS_STYLE_CLOSED_NAME}")
  fi
 fi

 if [[ -f "${WMS_STYLE_COUNTRIES_FILE}" ]]; then
  local COUNTRIES_STYLE_NAME
  COUNTRIES_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_COUNTRIES_FILE}")
  if [[ -n "${COUNTRIES_STYLE_NAME}" ]]; then
   STYLE_NAMES+=("${COUNTRIES_STYLE_NAME}")
  fi
  # Also try the property name
  if [[ -n "${WMS_STYLE_COUNTRIES_NAME}" ]] && [[ "${COUNTRIES_STYLE_NAME}" != "${WMS_STYLE_COUNTRIES_NAME}" ]]; then
   STYLE_NAMES+=("${WMS_STYLE_COUNTRIES_NAME}")
  fi
 fi

 if [[ -f "${WMS_STYLE_DISPUTED_FILE}" ]]; then
  local DISPUTED_STYLE_NAME
  DISPUTED_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_DISPUTED_FILE}")
  if [[ -n "${DISPUTED_STYLE_NAME}" ]]; then
   STYLE_NAMES+=("${DISPUTED_STYLE_NAME}")
  fi
  # Also try the property name
  if [[ -n "${WMS_STYLE_DISPUTED_NAME}" ]] && [[ "${DISPUTED_STYLE_NAME}" != "${WMS_STYLE_DISPUTED_NAME}" ]]; then
   STYLE_NAMES+=("${WMS_STYLE_DISPUTED_NAME}")
  fi
 fi

 # Also try common style name variations that might exist
 STYLE_NAMES+=("notesopen" "notesclosed")

 # Remove duplicate style names
 local UNIQUE_STYLE_NAMES=()
 for STYLE_NAME in "${STYLE_NAMES[@]}"; do
  local IS_DUPLICATE=false
  for UNIQUE_NAME in "${UNIQUE_STYLE_NAMES[@]}"; do
   if [[ "${STYLE_NAME}" == "${UNIQUE_NAME}" ]]; then
    IS_DUPLICATE=true
    break
   fi
  done
  if [[ "${IS_DUPLICATE}" == "false" ]]; then
   UNIQUE_STYLE_NAMES+=("${STYLE_NAME}")
  fi
 done

 # Remove each unique style
 for STYLE_NAME in "${UNIQUE_STYLE_NAMES[@]}"; do
  if remove_style "${STYLE_NAME}"; then
   TOTAL_STYLES_REMOVED=$((TOTAL_STYLES_REMOVED + 1))
  else
   TOTAL_STYLES_FAILED=$((TOTAL_STYLES_FAILED + 1))
  fi
 done

 if [[ ${TOTAL_STYLES_REMOVED} -eq 0 ]] && [[ ${TOTAL_STYLES_FAILED} -eq 0 ]]; then
  print_status "${YELLOW}" "   No styles found to remove"
 elif [[ ${TOTAL_STYLES_FAILED} -gt 0 ]]; then
  print_status "${YELLOW}" "   ⚠️  ${TOTAL_STYLES_FAILED} style(s) could not be removed - may need manual cleanup"
 fi

 # Step 5: Remove namespace (before workspace, as namespace is linked to workspace)
 # Check if namespace exists before attempting to remove
 local NAMESPACE_CHECK_URL="${GEOSERVER_URL}/rest/namespaces/${GEOSERVER_WORKSPACE}"
 local NAMESPACE_CHECK_CODE
 NAMESPACE_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${NAMESPACE_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${NAMESPACE_CHECK_CODE}" == "200" ]]; then
  print_status "${BLUE}" "🗑️  Removing namespace..."
  local NAMESPACE_URL="${NAMESPACE_CHECK_URL}"
  local TEMP_RESPONSE="${TMP_DIR}/namespace_delete_$$.tmp"
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${NAMESPACE_URL}" 2> /dev/null)
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
  rm -f "${TEMP_RESPONSE}" 2> /dev/null || true

  if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
   print_status "${GREEN}" "✅ Namespace removed"
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   print_status "${YELLOW}" "⚠️  Namespace not found (already removed)"
  elif [[ "${HTTP_CODE}" == "401" ]]; then
   print_status "${YELLOW}" "⚠️  Namespace removal failed (HTTP 401 - Authentication failed)"
   print_status "${YELLOW}" "   Check GeoServer credentials: ${GEOSERVER_USER}"
  elif [[ "${HTTP_CODE}" == "403" ]]; then
   print_status "${YELLOW}" "⚠️  Namespace removal failed (HTTP 403 - Forbidden)"
   print_status "${YELLOW}" "   User '${GEOSERVER_USER}' may not have permission to delete namespaces"
   print_status "${YELLOW}" "   Namespace may be linked to workspace - will be removed with workspace"
   print_status "${YELLOW}" "   You may need to remove it manually from GeoServer UI or use admin user"
  else
   print_status "${YELLOW}" "⚠️  Namespace removal failed (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]]; then
    print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
   fi
  fi
 else
  print_status "${YELLOW}" "⚠️  Namespace not found (already removed or workspace was removed)"
 fi

 # Step 6: Remove workspace (this will also remove linked namespace if permissions allow)
 print_status "${BLUE}" "🗑️  Removing workspace..."
 local WORKSPACE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}?recurse=true"
 local TEMP_RESPONSE="${TMP_DIR}/workspace_delete_$$.tmp"
 HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" -X DELETE "${WORKSPACE_URL}" 2> /dev/null)
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
 rm -f "${TEMP_RESPONSE}" 2> /dev/null || true

 if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
  print_status "${GREEN}" "✅ Workspace removed (with recurse=true, this also removes linked resources)"
  WORKSPACE_REMOVED=true
 elif [[ "${HTTP_CODE}" == "404" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace not found (already removed)"
  WORKSPACE_REMOVED=true
 elif [[ "${HTTP_CODE}" == "401" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace removal failed (HTTP 401 - Authentication failed)"
  print_status "${YELLOW}" "   Check GeoServer credentials: ${GEOSERVER_USER}"
 elif [[ "${HTTP_CODE}" == "403" ]]; then
  print_status "${YELLOW}" "⚠️  Workspace removal failed (HTTP 403 - Forbidden)"
  print_status "${YELLOW}" "   User '${GEOSERVER_USER}' may not have permission to delete workspaces"
  print_status "${YELLOW}" "   Workspace may still have layers/datastores - ensure they are removed first"
  print_status "${YELLOW}" "   💡 You may need to use an admin user with full permissions"
  print_status "${YELLOW}" "   💡 Or remove the workspace manually from GeoServer UI"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -5 | tr '\n' ' ')"
  fi
 else
  print_status "${YELLOW}" "⚠️  Workspace removal failed (HTTP ${HTTP_CODE})"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -5 | tr '\n' ' ')"
  fi
 fi

 # Show removal summary
 print_status "${BLUE}" ""
 print_status "${BLUE}" "📋 Removal Summary:"
 print_status "${BLUE}" "   - Layers removed: ${TOTAL_LAYERS_REMOVED}/4"
 if [[ ${TOTAL_LAYERS_FAILED} -gt 0 ]]; then
  print_status "${YELLOW}" "   - Layers failed: ${TOTAL_LAYERS_FAILED}"
 fi
 print_status "${BLUE}" "   - Feature types removed: ${TOTAL_FEATURES_REMOVED}/4"
 if [[ ${TOTAL_FEATURES_FAILED} -gt 0 ]]; then
  print_status "${YELLOW}" "   - Feature types failed: ${TOTAL_FEATURES_FAILED}"
 fi
 print_status "${BLUE}" "   - Styles removed: ${TOTAL_STYLES_REMOVED}"
 if [[ ${TOTAL_STYLES_FAILED} -gt 0 ]]; then
  print_status "${YELLOW}" "   - Styles failed: ${TOTAL_STYLES_FAILED}"
 fi
 if [[ "${DATASTORE_REMOVED}" == "true" ]]; then
  print_status "${GREEN}" "   - Datastore: Removed"
 else
  print_status "${YELLOW}" "   - Datastore: Still exists (may need manual removal)"
 fi
 if [[ "${WORKSPACE_REMOVED}" == "true" ]]; then
  print_status "${GREEN}" "   - Workspace: Removed"
 else
  print_status "${YELLOW}" "   - Workspace: Still exists (may need manual removal)"
 fi

 # Final status message
 if [[ "${WORKSPACE_REMOVED}" == "true" ]] && [[ "${DATASTORE_REMOVED}" == "true" ]] && [[ ${TOTAL_LAYERS_FAILED} -eq 0 ]] && [[ ${TOTAL_FEATURES_FAILED} -eq 0 ]]; then
  print_status "${GREEN}" ""
  print_status "${GREEN}" "✅ GeoServer configuration removal completed successfully"
  print_status "${GREEN}" "   All resources have been removed"
 else
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "⚠️  GeoServer configuration removal completed with warnings"
  if [[ "${WORKSPACE_REMOVED}" != "true" ]] || [[ "${DATASTORE_REMOVED}" != "true" ]]; then
   print_status "${YELLOW}" "   Some resources may still exist. To remove them:"
   print_status "${YELLOW}" "   1. Use an admin user with full permissions, or"
   print_status "${YELLOW}" "   2. Remove them manually from GeoServer UI"
   print_status "${YELLOW}" "   3. Or run this script again after fixing permissions"
  fi
  if [[ ${TOTAL_LAYERS_FAILED} -gt 0 ]] || [[ ${TOTAL_FEATURES_FAILED} -gt 0 ]]; then
   print_status "${YELLOW}" "   Some layers or feature types could not be removed automatically"
  fi
 fi
}
