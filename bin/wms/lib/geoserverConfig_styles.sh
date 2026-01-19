#!/bin/bash
# GeoServer Configuration Style Functions
# Functions for managing GeoServer styles (SLD)
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-29
# Function to extract style name from SLD file
extract_style_name_from_sld() {
 local SLD_FILE="${1}"
 # Extract the first <se:Name> or <Name> tag content from the SLD
 local STYLE_NAME
 STYLE_NAME=$(grep -oP '<(se:)?Name[^>]*>.*?</(se:)?Name>' "${SLD_FILE}" 2> /dev/null | head -1 | sed 's/.*>\(.*\)<.*/\1/' | tr -d ' ')
 echo "${STYLE_NAME}"
}

# Function to upload style
upload_style() {
 local SLD_FILE="${1}"
 local STYLE_NAME="${2}"
 local FORCE_UPLOAD="${FORCE:-false}"

 # Validate SLD file using centralized validation
 if ! __validate_input_file "${SLD_FILE}" "SLD style file"; then
  print_status "${YELLOW}" "⚠️  SLD file validation failed: ${SLD_FILE}"
  if [[ "${FORCE_UPLOAD}" == "true" ]]; then
   return 0 # Continue with --force
  fi
  return 1
 fi

 # Extract actual style name from SLD (may differ from STYLE_NAME parameter)
 local ACTUAL_STYLE_NAME
 ACTUAL_STYLE_NAME=$(extract_style_name_from_sld "${SLD_FILE}")
 if [[ -z "${ACTUAL_STYLE_NAME}" ]]; then
  # Fallback to provided name if extraction fails
  ACTUAL_STYLE_NAME="${STYLE_NAME}"
 fi

 # Check if style already exists (try both the provided name and the actual name)
 # IMPORTANT: Check in workspace-specific styles first, then global styles
 local STYLE_CHECK_URL="${GEOSERVER_URL}/rest/styles/${ACTUAL_STYLE_NAME}"
 if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
  STYLE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles/${ACTUAL_STYLE_NAME}"
 fi
 local TEMP_CHECK_FILE="${TMP_DIR}/style_check_${STYLE_NAME}_$$.tmp"
 local CHECK_HTTP_CODE
 CHECK_HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_CHECK_FILE}" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  "${STYLE_CHECK_URL}" 2> /dev/null | tail -1)

 # If not found with actual name, try with provided name
 if [[ "${CHECK_HTTP_CODE}" != "200" ]] && [[ "${ACTUAL_STYLE_NAME}" != "${STYLE_NAME}" ]]; then
  STYLE_CHECK_URL="${GEOSERVER_URL}/rest/styles/${STYLE_NAME}"
  if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
   STYLE_CHECK_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles/${STYLE_NAME}"
  fi
  CHECK_HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_CHECK_FILE}" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   "${STYLE_CHECK_URL}" 2> /dev/null | tail -1)
  if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
   ACTUAL_STYLE_NAME="${STYLE_NAME}"
  fi
 fi

 local TEMP_RESPONSE_FILE="${TMP_DIR}/style_response_${STYLE_NAME}_$$.tmp"
 local HTTP_CODE
 local RESPONSE_BODY

 # If style exists, delete it first to avoid corruption issues, then create it
 # This is important because GeoServer may cache a corrupted version of the style
 # Also try to delete from both workspace-specific and global locations when using --force
 if [[ "${CHECK_HTTP_CODE}" == "200" ]] || [[ "${FORCE_UPLOAD}" == "true" ]]; then
  # Style exists or force mode - delete it first from all possible locations
  print_status "${BLUE}" "   Removing existing style '${ACTUAL_STYLE_NAME}' before recreating..."
  local DELETE_CODE
  local STYLE_DELETED=false
  
  # Try to delete from workspace-specific location first
  if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
   local WORKSPACE_DELETE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles/${ACTUAL_STYLE_NAME}"
   DELETE_CODE=$(curl -s -w "%{http_code}" -o /dev/null \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -X DELETE "${WORKSPACE_DELETE_URL}" 2> /dev/null | tail -1)
   if [[ "${DELETE_CODE}" == "200" ]] || [[ "${DELETE_CODE}" == "204" ]]; then
    STYLE_DELETED=true
   fi
  fi
  
  # Also try to delete from global location (in case it exists there)
  if [[ "${STYLE_DELETED}" == "false" ]] || [[ "${FORCE_UPLOAD}" == "true" ]]; then
   local GLOBAL_DELETE_URL="${GEOSERVER_URL}/rest/styles/${ACTUAL_STYLE_NAME}"
   DELETE_CODE=$(curl -s -w "%{http_code}" -o /dev/null \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -X DELETE "${GLOBAL_DELETE_URL}" 2> /dev/null | tail -1)
   if [[ "${DELETE_CODE}" == "200" ]] || [[ "${DELETE_CODE}" == "204" ]]; then
    STYLE_DELETED=true
   fi
  fi
  
  # Also try with provided name if different from actual name
  if [[ "${STYLE_NAME}" != "${ACTUAL_STYLE_NAME}" ]]; then
   if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
    local WORKSPACE_DELETE_URL_NAME="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles/${STYLE_NAME}"
    DELETE_CODE=$(curl -s -w "%{http_code}" -o /dev/null \
     -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
     -X DELETE "${WORKSPACE_DELETE_URL_NAME}" 2> /dev/null | tail -1)
    if [[ "${DELETE_CODE}" == "200" ]] || [[ "${DELETE_CODE}" == "204" ]]; then
     STYLE_DELETED=true
    fi
   fi
   local GLOBAL_DELETE_URL_NAME="${GEOSERVER_URL}/rest/styles/${STYLE_NAME}"
   DELETE_CODE=$(curl -s -w "%{http_code}" -o /dev/null \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -X DELETE "${GLOBAL_DELETE_URL_NAME}" 2> /dev/null | tail -1)
   if [[ "${DELETE_CODE}" == "200" ]] || [[ "${DELETE_CODE}" == "204" ]]; then
    STYLE_DELETED=true
   fi
  fi
  
  if [[ "${STYLE_DELETED}" == "true" ]]; then
   sleep 2 # Wait a moment for GeoServer to process the deletion and clear cache
  fi
 fi
 # Create the style (either new or after deletion)
 if true; then
  # Style doesn't exist, create it (use the name from SLD, not the parameter)
  # GeoServer will extract the name from the SLD file itself
  # Use --data-binary to ensure the entire file is read correctly
  # Use application/vnd.ogc.se+xml to preserve SLD 1.1.0 format and SvgParameter elements
  # IMPORTANT: Upload to workspace-specific styles endpoint to ensure styles are in the correct workspace
  local STYLE_UPLOAD_URL="${GEOSERVER_URL}/rest/styles?name=${ACTUAL_STYLE_NAME}"
  if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
   STYLE_UPLOAD_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles?name=${ACTUAL_STYLE_NAME}"
  fi
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
   -X POST \
   -H "Content-Type: application/vnd.ogc.se+xml" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   --data-binary "@${SLD_FILE}" \
   "${STYLE_UPLOAD_URL}" 2> /dev/null | tail -1)
 fi

 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 local STYLE_UPLOADED=false
 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  if [[ "${CHECK_HTTP_CODE}" == "200" ]]; then
   print_status "${GREEN}" "✅ Style '${ACTUAL_STYLE_NAME}' updated"
  else
   print_status "${GREEN}" "✅ Style '${ACTUAL_STYLE_NAME}' uploaded"
  fi
  STYLE_UPLOADED=true
 elif [[ "${HTTP_CODE}" == "409" ]] || [[ "${HTTP_CODE}" == "403" ]]; then
  # 403 or 409 means style already exists - try to update it
  if [[ "${CHECK_HTTP_CODE}" != "200" ]]; then
   # Style exists but we couldn't find it by name, try updating with actual name
   # Use --data-binary to ensure the entire file is read correctly
   # Use application/vnd.ogc.se+xml to preserve SLD 1.1.0 format and SvgParameter elements
   HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
    -X PUT \
    -H "Content-Type: application/vnd.ogc.se+xml" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    --data-binary "@${SLD_FILE}" \
    "${GEOSERVER_URL}/rest/styles/${ACTUAL_STYLE_NAME}" 2> /dev/null | tail -1)
   RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")
   if [[ "${HTTP_CODE}" == "200" ]]; then
    print_status "${GREEN}" "✅ Style '${ACTUAL_STYLE_NAME}' updated"
    STYLE_UPLOADED=true
   else
    print_status "${YELLOW}" "⚠️  Style '${ACTUAL_STYLE_NAME}' already exists (could not update)"
    if [[ "${FORCE_UPLOAD}" == "true" ]]; then
     STYLE_UPLOADED=true # Continue with --force
    fi
   fi
  else
   print_status "${YELLOW}" "⚠️  Style '${ACTUAL_STYLE_NAME}' already exists"
   STYLE_UPLOADED=true
  fi
 else
  print_status "${YELLOW}" "⚠️  Style upload skipped (HTTP ${HTTP_CODE})"
  if [[ "${HTTP_CODE}" == "403" ]]; then
   print_status "${YELLOW}" "   Permission denied (403 Forbidden) - Style must be created manually via web interface"
  elif [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Error:"
   echo "${RESPONSE_BODY}" | head -20 | sed 's/^/      /'
  else
   print_status "${YELLOW}" "   (No error message returned - check GeoServer logs)"
   print_status "${YELLOW}" "   Common causes:"
   print_status "${YELLOW}" "   - Invalid SLD format"
   print_status "${YELLOW}" "   - GeoServer out of memory"
   print_status "${YELLOW}" "   - File too large"
   print_status "${YELLOW}" "   - Check GeoServer logs: tail -f /opt/geoserver/logs/geoserver.log"
  fi
  if [[ "${HTTP_CODE}" == "403" ]]; then
   # Permission denied - return special code for manual intervention
   STYLE_UPLOADED=false
   rm -f "${TEMP_RESPONSE_FILE}" "${TEMP_CHECK_FILE}" 2> /dev/null || true
   return 2
  else
   # Other errors - mark as not uploaded but continue
   STYLE_UPLOADED=false
  fi
 fi

 rm -f "${TEMP_RESPONSE_FILE}" "${TEMP_CHECK_FILE}" 2> /dev/null || true

 # Return appropriate exit code
 if [[ "${STYLE_UPLOADED}" == "true" ]]; then
  return 0
 else
  # Return 2 for permission errors (403), 1 for other errors
  if [[ "${HTTP_CODE:-}" == "403" ]]; then
   return 2
  else
   return 1
  fi
 fi
}

# Function to remove a style
remove_style() {
 local STYLE_NAME="${1}"

 # Try to remove style from workspace-specific location first (if workspace is set)
 # Then try global location
 # Styles can exist in either location depending on how they were created
 local STYLE_REMOVED=false
 local TEMP_RESPONSE="${TMP_DIR}/style_delete_${STYLE_NAME}_$$.tmp"
 local HTTP_CODE
 local RESPONSE_BODY

 # First, try workspace-specific location
 if [[ -n "${GEOSERVER_WORKSPACE:-}" ]]; then
  local WORKSPACE_STYLE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/styles/${STYLE_NAME}"
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   -X DELETE "${WORKSPACE_STYLE_URL}" 2> /dev/null | tail -1)
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
  
  if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
   print_status "${GREEN}" "✅ Style '${STYLE_NAME}' removed (from workspace)"
   STYLE_REMOVED=true
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   # Not found in workspace, will try global location
   :
  else
   # Error but not 404, log it but continue to try global location
   if [[ "${VERBOSE:-false}" == "true" ]]; then
    print_status "${YELLOW}" "   Workspace removal attempt failed (HTTP ${HTTP_CODE})"
   fi
  fi
 fi

 # If not removed from workspace, try global location
 if [[ "${STYLE_REMOVED}" == "false" ]]; then
  local GLOBAL_STYLE_URL="${GEOSERVER_URL}/rest/styles/${STYLE_NAME}"
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE}" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   -X DELETE "${GLOBAL_STYLE_URL}" 2> /dev/null | tail -1)
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE}" 2> /dev/null || echo "")
  
  if [[ "${HTTP_CODE}" == "200" ]] || [[ "${HTTP_CODE}" == "204" ]]; then
   print_status "${GREEN}" "✅ Style '${STYLE_NAME}' removed (from global)"
   STYLE_REMOVED=true
  elif [[ "${HTTP_CODE}" == "404" ]]; then
   print_status "${YELLOW}" "⚠️  Style '${STYLE_NAME}' not found (already removed)"
   STYLE_REMOVED=true # Consider it removed if not found
  else
   print_status "${YELLOW}" "⚠️  Style '${STYLE_NAME}' removal failed (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
    print_status "${YELLOW}" "   Response: $(echo "${RESPONSE_BODY}" | head -3 | tr '\n' ' ')"
   fi
  fi
 fi

 rm -f "${TEMP_RESPONSE}" 2> /dev/null || true

 if [[ "${STYLE_REMOVED}" == "true" ]]; then
  return 0
 else
  return 1
 fi
}
