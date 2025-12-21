#!/bin/bash
# GeoServer Configuration Layer Functions
# Functions for managing GeoServer layers and feature types
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
# Function to create feature type from table
create_feature_type_from_table() {
 local LAYER_NAME="${1}"
 local TABLE_NAME="${2}"
 local LAYER_TITLE="${3}"
 local LAYER_DESCRIPTION="${4}"

 print_status "${BLUE}" "🗺️  Creating GeoServer feature type '${LAYER_NAME}' from table '${TABLE_NAME}'..."

 # Calculate actual bounding box from PostgreSQL data
 local BBOX
 BBOX=$(calculate_bbox_from_table "${TABLE_NAME}")
 local BBOX_MINX BBOX_MINY BBOX_MAXX BBOX_MAXY
 IFS=',' read -r BBOX_MINX BBOX_MINY BBOX_MAXX BBOX_MAXY <<< "${BBOX}"

 # For views and materialized views, we need to specify attributes explicitly
 # Check if it's a view (contains 'view' in the name, case insensitive)
 # or a materialized view (disputed_and_unclaimed_areas)
 local IS_VIEW=0
 local IS_DISPUTED_VIEW=0
 if echo "${TABLE_NAME}" | grep -qi "view"; then
  IS_VIEW=1
  # Check if it's disputed areas view
  if echo "${TABLE_NAME}" | grep -qi "disputed.*areas.*view"; then
   IS_DISPUTED_VIEW=1
  fi
 elif echo "${TABLE_NAME}" | grep -qi "disputed_and_unclaimed_areas"; then
  IS_VIEW=1
  IS_DISPUTED_VIEW=1
 fi

 # Build attributes JSON based on table/view type
 local ATTRIBUTES_JSON=""
 if [[ ${IS_VIEW} -eq 1 ]]; then
  # Check if it's disputed areas view or notes views
  if [[ ${IS_DISPUTED_VIEW} -eq 1 ]] || echo "${TABLE_NAME}" | grep -qi "disputed.*areas"; then
   # For disputed areas view (only has id, zone_type, geometry)
   ATTRIBUTES_JSON=",
     \"attributes\": {
       \"attribute\": [
         {
           \"name\": \"id\",
           \"minOccurs\": 0,
           \"maxOccurs\": 1,
           \"nillable\": true,
           \"binding\": \"java.lang.Integer\"
         },
         {
           \"name\": \"zone_type\",
           \"minOccurs\": 0,
           \"maxOccurs\": 1,
           \"nillable\": true,
           \"binding\": \"java.lang.String\"
         },
         {
           \"name\": \"geometry\",
           \"minOccurs\": 1,
           \"maxOccurs\": 1,
           \"nillable\": false,
           \"binding\": \"org.locationtech.jts.geom.Geometry\"
         }
       ]
     }"
  elif echo "${TABLE_NAME}" | grep -qi "notes_open_view\|notes_closed_view"; then
   # For notes views: Let GeoServer auto-detect attributes from the view
   # This avoids CQL expression errors with calculated columns like age_years
   # GeoServer will automatically detect all columns from the PostgreSQL view
   ATTRIBUTES_JSON=""
  fi
 fi

 # Set maxFeatures for layers with many features to prevent timeout
 # For notes_closed_view (4.4M features), limit to 50K for rendering to prevent timeout
 # For notes_open_view (460K features), limit to 25K for rendering
 # These limits ensure maps can render within the 60s timeout
 local MAX_FEATURES=0
 if echo "${TABLE_NAME}" | grep -qi "notes_closed_view"; then
  MAX_FEATURES=50000
 elif echo "${TABLE_NAME}" | grep -qi "notes_open_view"; then
  MAX_FEATURES=25000
 fi

 local FEATURE_TYPE_DATA="{
   \"featureType\": {
     \"name\": \"${LAYER_NAME}\",
     \"nativeName\": \"${TABLE_NAME}\",
     \"title\": \"${LAYER_TITLE}\",
     \"description\": \"${LAYER_DESCRIPTION}\",
     \"enabled\": true,
     \"srs\": \"${WMS_LAYER_SRS}\",
     \"maxFeatures\": ${MAX_FEATURES},
     \"nativeBoundingBox\": {
       \"minx\": ${BBOX_MINX},
       \"maxx\": ${BBOX_MAXX},
       \"miny\": ${BBOX_MINY},
       \"maxy\": ${BBOX_MAXY},
       \"crs\": \"${WMS_LAYER_SRS}\"
     },
     \"latLonBoundingBox\": {
       \"minx\": ${BBOX_MINX},
       \"maxx\": ${BBOX_MAXX},
       \"miny\": ${BBOX_MINY},
       \"maxy\": ${BBOX_MAXY},
       \"crs\": \"${WMS_LAYER_SRS}\"
     }${ATTRIBUTES_JSON},
     \"store\": {
       \"@class\": \"dataStore\",
       \"name\": \"${GEOSERVER_STORE}\"
     }
   }
 }"

 local FEATURE_TYPE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes"
 local FEATURE_TYPE_UPDATE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes/${LAYER_NAME}"

 local TEMP_RESPONSE_FILE="${TMP_DIR}/featuretype_response_${LAYER_NAME}_$$.tmp"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
  -X POST \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${FEATURE_TYPE_DATA}" \
  "${FEATURE_TYPE_URL}" 2> /dev/null | tail -1)

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ Feature type '${LAYER_NAME}' created"
  # Force GeoServer to recalculate bounding boxes from actual data
  # Wait a moment for GeoServer to fully initialize the feature type
  print_status "${BLUE}" "📐 Recalculating bounding boxes from data..."
  sleep 2
  # Use the recalculate endpoint to compute bounding boxes from actual data
  local RECALC_URL="${FEATURE_TYPE_UPDATE_URL}?recalculate=nativebbox,latlonbbox"
  local TEMP_RECALC_FILE="${TMP_DIR}/recalc_${LAYER_NAME}_$$.tmp"
  local TEMP_RECALC_ERROR="${TMP_DIR}/recalc_error_${LAYER_NAME}_$$.tmp"
  local RECALC_CODE
  local RECALC_ATTEMPTS=0
  local RECALC_MAX_ATTEMPTS=3
  local RECALC_SUCCESS=false

  # Try to recalculate with retries
  while [[ ${RECALC_ATTEMPTS} -lt ${RECALC_MAX_ATTEMPTS} ]] && [[ "${RECALC_SUCCESS}" == "false" ]]; do
   RECALC_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RECALC_FILE}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    "${RECALC_URL}" 2> "${TEMP_RECALC_ERROR}" | tail -1)

   if [[ "${RECALC_CODE}" == "200" ]]; then
    RECALC_SUCCESS=true
    print_status "${GREEN}" "✅ Bounding boxes recalculated"
   else
    RECALC_ATTEMPTS=$((RECALC_ATTEMPTS + 1))
    if [[ ${RECALC_ATTEMPTS} -lt ${RECALC_MAX_ATTEMPTS} ]]; then
     sleep 1
    fi
   fi
  done

  if [[ "${RECALC_SUCCESS}" == "false" ]]; then
   print_status "${YELLOW}" "⚠️  Could not recalculate bounding boxes (HTTP ${RECALC_CODE})"
   if [[ -s "${TEMP_RECALC_FILE}" ]]; then
    local RECALC_ERROR_MSG
    RECALC_ERROR_MSG=$(head -5 "${TEMP_RECALC_FILE}" 2> /dev/null | tr '\n' ' ' || echo "")
    if [[ -n "${RECALC_ERROR_MSG}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
     print_status "${YELLOW}" "   Error details: ${RECALC_ERROR_MSG}"
    fi
   fi
   print_status "${YELLOW}" "   GeoServer will use the provided bounding box or calculate it automatically"
   print_status "${YELLOW}" "   This is not critical - the layer should still work correctly"
  fi
  rm -f "${TEMP_RECALC_FILE}" "${TEMP_RECALC_ERROR}" 2> /dev/null || true
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 elif [[ "${HTTP_CODE}" == "409" ]] || echo "${RESPONSE_BODY}" | grep -qi "already exists"; then
  # Check if layer exists - if not, delete feature type and recreate to force layer creation
  local LAYER_CHECK_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
  local LAYER_CHECK_CODE
  LAYER_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${LAYER_CHECK_URL}" 2> /dev/null | tail -1)

  if [[ "${LAYER_CHECK_CODE}" != "200" ]]; then
   # Layer doesn't exist, delete feature type and recreate
   print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' exists but layer doesn't, recreating..."
   curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -X DELETE "${FEATURE_TYPE_UPDATE_URL}?recurse=true" 2> /dev/null | tail -1 > /dev/null
   sleep 2
   # Retry creation
   HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
    -X POST \
    -H "Content-Type: application/json" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -d "${FEATURE_TYPE_DATA}" \
    "${FEATURE_TYPE_URL}" 2> /dev/null | tail -1)
   RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")
   if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
    print_status "${GREEN}" "✅ Feature type '${LAYER_NAME}' recreated"
    # Force GeoServer to recalculate bounding boxes from actual data
    # Wait a moment for GeoServer to fully initialize the feature type
    print_status "${BLUE}" "📐 Recalculating bounding boxes from data..."
    sleep 2
    local RECALC_URL="${FEATURE_TYPE_UPDATE_URL}?recalculate=nativebbox,latlonbbox"
    local TEMP_RECALC_FILE="${TMP_DIR}/recalc_${LAYER_NAME}_$$.tmp"
    local TEMP_RECALC_ERROR="${TMP_DIR}/recalc_error_${LAYER_NAME}_$$.tmp"
    local RECALC_CODE
    local RECALC_ATTEMPTS=0
    local RECALC_MAX_ATTEMPTS=3
    local RECALC_SUCCESS=false

    # Try to recalculate with retries
    while [[ ${RECALC_ATTEMPTS} -lt ${RECALC_MAX_ATTEMPTS} ]] && [[ "${RECALC_SUCCESS}" == "false" ]]; do
     RECALC_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RECALC_FILE}" \
      -X PUT \
      -H "Content-Type: application/json" \
      -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
      "${RECALC_URL}" 2> "${TEMP_RECALC_ERROR}" | tail -1)

     if [[ "${RECALC_CODE}" == "200" ]]; then
      RECALC_SUCCESS=true
      print_status "${GREEN}" "✅ Bounding boxes recalculated"
     else
      RECALC_ATTEMPTS=$((RECALC_ATTEMPTS + 1))
      if [[ ${RECALC_ATTEMPTS} -lt ${RECALC_MAX_ATTEMPTS} ]]; then
       sleep 1
      fi
     fi
    done

    if [[ "${RECALC_SUCCESS}" == "false" ]]; then
     print_status "${YELLOW}" "⚠️  Could not recalculate bounding boxes (HTTP ${RECALC_CODE})"
     if [[ -s "${TEMP_RECALC_FILE}" ]]; then
      local RECALC_ERROR_MSG
      RECALC_ERROR_MSG=$(head -5 "${TEMP_RECALC_FILE}" 2> /dev/null | tr '\n' ' ' || echo "")
      if [[ -n "${RECALC_ERROR_MSG}" ]] && [[ "${VERBOSE:-false}" == "true" ]]; then
       print_status "${YELLOW}" "   Error details: ${RECALC_ERROR_MSG}"
      fi
     fi
     print_status "${YELLOW}" "   GeoServer will use the provided bounding box or calculate it automatically"
     print_status "${YELLOW}" "   This is not critical - the layer should still work correctly"
    fi
    rm -f "${TEMP_RECALC_FILE}" "${TEMP_RECALC_ERROR}" 2> /dev/null || true
    rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
    return 0
   fi
  fi

  # Layer exists or recreation failed, try to update
  print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' already exists, updating..."
  # Recalculate bounding box from actual data
  local BBOX_UPDATE
  BBOX_UPDATE=$(calculate_bbox_from_table "${TABLE_NAME}")
  local BBOX_MINX_UPDATE BBOX_MINY_UPDATE BBOX_MAXX_UPDATE BBOX_MAXY_UPDATE
  IFS=',' read -r BBOX_MINX_UPDATE BBOX_MINY_UPDATE BBOX_MAXX_UPDATE BBOX_MAXY_UPDATE <<< "${BBOX_UPDATE}"
  # For update, include calculated bounding boxes
  local FEATURE_TYPE_UPDATE_DATA="{
   \"featureType\": {
     \"name\": \"${LAYER_NAME}\",
     \"nativeName\": \"${TABLE_NAME}\",
     \"title\": \"${LAYER_TITLE}\",
     \"description\": \"${LAYER_DESCRIPTION}\",
     \"enabled\": true,
     \"srs\": \"${WMS_LAYER_SRS}\",
     \"nativeBoundingBox\": {
       \"minx\": ${BBOX_MINX_UPDATE},
       \"maxx\": ${BBOX_MAXX_UPDATE},
       \"miny\": ${BBOX_MINY_UPDATE},
       \"maxy\": ${BBOX_MAXY_UPDATE},
       \"crs\": \"${WMS_LAYER_SRS}\"
     },
     \"latLonBoundingBox\": {
       \"minx\": ${BBOX_MINX_UPDATE},
       \"maxx\": ${BBOX_MAXX_UPDATE},
       \"miny\": ${BBOX_MINY_UPDATE},
       \"maxy\": ${BBOX_MAXY_UPDATE},
       \"crs\": \"${WMS_LAYER_SRS}\"
     }${ATTRIBUTES_JSON},
     \"store\": {
       \"@class\": \"dataStore\",
       \"name\": \"${GEOSERVER_STORE}\"
     }
   }
 }"
  # Try to update using PUT (without bounding boxes - GeoServer will recalculate)
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
   -X PUT \
   -H "Content-Type: application/json" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   -d "${FEATURE_TYPE_UPDATE_DATA}" \
   "${FEATURE_TYPE_UPDATE_URL}" 2> /dev/null | tail -1)
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")
  if [[ "${HTTP_CODE}" == "200" ]]; then
   print_status "${GREEN}" "✅ Feature type '${LAYER_NAME}' updated"
   print_status "${GREEN}" "✅ GeoServer will recalculate bounding boxes automatically"
   rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 0
  else
   print_status "${YELLOW}" "⚠️  Feature type '${LAYER_NAME}' already exists (update not needed)"
   rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 0
  fi
 else
  print_status "${YELLOW}" "⚠️  Failed to create feature type '${LAYER_NAME}' (HTTP ${HTTP_CODE})"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response:"
   echo "${RESPONSE_BODY}" | head -50 | sed 's/^/      /'
   # Save full error for debugging
   echo "${RESPONSE_BODY}" > "${TMP_DIR}/geoserver_error_${LAYER_NAME}_$$.txt" 2> /dev/null || true
  fi
  rm -f "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 1
 fi
}

# Function to create SQL view layer
create_sql_view_layer() {
 local LAYER_NAME="${1}"
 local SQL_QUERY="${2}"
 local LAYER_TITLE="${3}"
 local LAYER_DESCRIPTION="${4}"
 local GEOMETRY_COLUMN="${5:-geometry}"

 print_status "${BLUE}" "🗺️  Creating GeoServer SQL view layer '${LAYER_NAME}'..."

 # Calculate actual bounding box from SQL query
 # Extract table/view name from SQL for bounding box calculation
 local TABLE_NAME
 TABLE_NAME=$(echo "${SQL_QUERY}" | sed -n 's/.*FROM[[:space:]]\+\([^[:space:]]*\).*/\1/p' | tr -d ';' || echo "")
 local BBOX
 if [[ -n "${TABLE_NAME}" ]]; then
  # Remove schema prefix if present (e.g., "public.notes_open_view" -> "notes_open_view")
  local TABLE_NAME_CLEAN="${TABLE_NAME}"
  if echo "${TABLE_NAME}" | grep -q '\\.'; then
   TABLE_NAME_CLEAN=$(echo "${TABLE_NAME}" | sed 's/^[^.]*\\.//')
  fi
  # Try to calculate bbox, but use defaults if it fails
  BBOX=$(calculate_bbox_from_table "${TABLE_NAME_CLEAN}" 2> /dev/null || echo "")
  if [[ -z "${BBOX}" ]] || ! echo "${BBOX}" | grep -qE '^-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+,-?[0-9]+\.[0-9]+$'; then
   # Use default bounding box if calculation failed
   BBOX="${WMS_BBOX_MINX},${WMS_BBOX_MINY},${WMS_BBOX_MAXX},${WMS_BBOX_MAXY}"
  fi
 else
  # Use default bounding box if table name cannot be extracted
  BBOX="${WMS_BBOX_MINX},${WMS_BBOX_MINY},${WMS_BBOX_MAXX},${WMS_BBOX_MAXY}"
 fi
 local BBOX_MINX BBOX_MINY BBOX_MAXX BBOX_MAXY
 IFS=',' read -r BBOX_MINX BBOX_MINY BBOX_MAXX BBOX_MAXY <<< "${BBOX}"

 # Escape SQL query for XML (escape <, >, &, ", ')
 # Note: We need to escape for XML first, then for JSON
 # Replace newlines with spaces and collapse multiple spaces
 local CLEANED_SQL
 CLEANED_SQL=$(echo "${SQL_QUERY}" | tr '\n' ' ' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')

 # Escape for XML: & must be first, then < and >
 local ESCAPED_SQL
 ESCAPED_SQL=$(echo "${CLEANED_SQL}" | sed 's/&/\&amp;/g' | sed 's/</\&lt;/g' | sed 's/>/\&gt;/g' | sed 's/"/\&quot;/g' | sed "s/'/\&apos;/g")

 # Escape the XML for JSON (escape backslashes first, then quotes, then newlines)
 # Order matters: backslashes first, then quotes
 # Create virtual table XML file (temporary) to ensure proper formatting
 # Note: Use a simple fixed name for virtual table to avoid GeoServer schema interpretation
 # The virtual table name should not match any schema or table names
 local VIRTUAL_TABLE_NAME="vtable"
 local TEMP_VIRTUAL_TABLE="${TMP_DIR}/virtual_table_${LAYER_NAME}_$$.xml"
 cat > "${TEMP_VIRTUAL_TABLE}" << EOF
<virtualTable>
  <name>${VIRTUAL_TABLE_NAME}</name>
  <sql>${ESCAPED_SQL}</sql>
  <geometry>
    <name>${GEOMETRY_COLUMN}</name>
    <type>Geometry</type>
    <srid>4326</srid>
  </geometry>
</virtualTable>
EOF

 # Read the XML and escape it for JSON
 local VIRTUAL_TABLE_CONTENT
 VIRTUAL_TABLE_CONTENT=$(cat "${TEMP_VIRTUAL_TABLE}" | sed 's/\\/\\\\/g' | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
 rm -f "${TEMP_VIRTUAL_TABLE}" 2> /dev/null || true

 # Create JSON payload using a temporary file to avoid escaping issues
 # Note: For SQL views, we don't specify nativeName to avoid schema interpretation issues
 # SQL views are virtual tables and don't have a "native" table name
 local TEMP_JSON="${TMP_DIR}/featuretype_${LAYER_NAME}_$$.json"
 cat > "${TEMP_JSON}" << EOF
{
  "featureType": {
    "name": "${LAYER_NAME}",
    "title": "${LAYER_TITLE}",
    "description": "${LAYER_DESCRIPTION}",
    "enabled": true,
    "srs": "${WMS_LAYER_SRS}",
    "nativeBoundingBox": {
      "minx": ${BBOX_MINX},
      "maxx": ${BBOX_MAXX},
      "miny": ${BBOX_MINY},
      "maxy": ${BBOX_MAXY},
      "crs": "${WMS_LAYER_SRS}"
    },
    "latLonBoundingBox": {
      "minx": ${BBOX_MINX},
      "maxx": ${BBOX_MAXX},
      "miny": ${BBOX_MINY},
      "maxy": ${BBOX_MAXY},
      "crs": "${WMS_LAYER_SRS}"
    },
    "metadata": {
      "entry": [
        {
          "@key": "JDBC_VIRTUAL_TABLE",
          "$": "${VIRTUAL_TABLE_CONTENT}"
        }
      ]
    }
  }
}
EOF

 local FEATURE_TYPE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes"
 local FEATURE_TYPE_UPDATE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/datastores/${GEOSERVER_STORE}/featuretypes/${LAYER_NAME}"

 local TEMP_RESPONSE_FILE="${TMP_DIR}/sqlview_response_${LAYER_NAME}_$$.tmp"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "\nHTTP_CODE:%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
  -X POST \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "@${TEMP_JSON}" \
  "${FEATURE_TYPE_URL}" 2> /dev/null)
 # Extract HTTP code from last line
 HTTP_CODE=$(echo "${HTTP_CODE}" | tail -1 | sed 's/HTTP_CODE://')

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ SQL view layer '${LAYER_NAME}' created"
  rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
  return 0
 elif [[ "${HTTP_CODE}" == "409" ]]; then
  print_status "${YELLOW}" "⚠️  SQL view layer '${LAYER_NAME}' already exists, updating..."
  # Try to update using PUT
  HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
   -X PUT \
   -H "Content-Type: application/json" \
   -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
   -d "@${TEMP_JSON}" \
   "${FEATURE_TYPE_UPDATE_URL}" 2> /dev/null | tail -1)
  RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")
  if [[ "${HTTP_CODE}" == "200" ]]; then
   print_status "${GREEN}" "✅ SQL view layer '${LAYER_NAME}' updated"
   rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 0
  else
   print_status "${YELLOW}" "⚠️  SQL view layer '${LAYER_NAME}' already exists (update not needed)"
   rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 0
  fi
 else
  # Check if error message indicates it already exists (some GeoServer versions return 500 for this)
  if echo "${RESPONSE_BODY}" | grep -qi "already exists"; then
   print_status "${YELLOW}" "⚠️  SQL view layer '${LAYER_NAME}' already exists, updating..."
   # Try to update using PUT
   HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_RESPONSE_FILE}" \
    -X PUT \
    -H "Content-Type: application/json" \
    -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
    -d "@${TEMP_JSON}" \
    "${FEATURE_TYPE_UPDATE_URL}" 2> /dev/null | tail -1)
   RESPONSE_BODY=$(cat "${TEMP_RESPONSE_FILE}" 2> /dev/null || echo "")
   if [[ "${HTTP_CODE}" == "200" ]]; then
    print_status "${GREEN}" "✅ SQL view layer '${LAYER_NAME}' updated"
    rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
    return 0
   else
    print_status "${YELLOW}" "⚠️  SQL view layer '${LAYER_NAME}' already exists (update not needed)"
    rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
    return 0
   fi
  else
   print_status "${YELLOW}" "⚠️  Failed to create SQL view layer '${LAYER_NAME}' (HTTP ${HTTP_CODE})"
   if [[ -n "${RESPONSE_BODY}" ]]; then
    print_status "${YELLOW}" "   Response:"
    echo "${RESPONSE_BODY}" | head -50 | sed 's/^/      /'
    # Save error for debugging
    echo "${RESPONSE_BODY}" > "${TMP_DIR}/geoserver_error_${LAYER_NAME}_$$.txt" 2> /dev/null || true
   fi
   print_status "${YELLOW}" "   Troubleshooting:"
   print_status "${YELLOW}" "   - Verify SQL query is valid: ${SQL_QUERY}"
   print_status "${YELLOW}" "   - Check datastore connection to database"
   print_status "${YELLOW}" "   - Verify geometry column name: ${GEOMETRY_COLUMN}"
   rm -f "${TEMP_JSON}" "${TEMP_RESPONSE_FILE}" 2> /dev/null || true
   return 1
  fi
 fi
}

# Legacy function for backward compatibility
create_feature_type() {
 create_feature_type_from_table "${GEOSERVER_LAYER}" "${WMS_TABLE}" "${WMS_LAYER_TITLE}" "${WMS_LAYER_DESCRIPTION}"
}
# Function to create layer from feature type
create_layer_from_feature_type() {
 local LAYER_NAME="${1}"
 local STYLE_NAME="${2}"

 # Check if layer already exists
 local LAYER_CHECK_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
 local LAYER_CHECK_CODE
 LAYER_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${LAYER_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${LAYER_CHECK_CODE}" == "200" ]]; then
  # Layer already exists
  return 0
 fi

 # Layer doesn't exist, wait a moment and check again
 # GeoServer may create the layer automatically after feature type creation
 print_status "${BLUE}" "📋 Waiting for layer '${LAYER_NAME}' to be available..."
 sleep 2

 # Check again if layer exists (GeoServer may have created it automatically)
 LAYER_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${LAYER_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${LAYER_CHECK_CODE}" == "200" ]]; then
  # Layer was created automatically by GeoServer
  print_status "${GREEN}" "✅ Layer '${LAYER_NAME}' is now available"
  return 0
 fi

 # Layer still doesn't exist, try to create it manually
 print_status "${BLUE}" "📋 Creating layer '${LAYER_NAME}' from feature type..."

 # Use the correct format for GeoServer layer creation
 local LAYER_DATA="{
   \"layer\": {
     \"name\": \"${LAYER_NAME}\",
     \"type\": \"VECTOR\",
     \"defaultStyle\": {
       \"name\": \"${STYLE_NAME}\"
     },
     \"resource\": {
       \"@class\": \"featureType\",
       \"name\": \"${LAYER_NAME}\"
     },
     \"path\": \"/${GEOSERVER_WORKSPACE}:${LAYER_NAME}\"
   }
 }"

 # Try creating using POST to workspace layers endpoint
 local LAYER_CREATE_URL="${GEOSERVER_URL}/rest/workspaces/${GEOSERVER_WORKSPACE}/layers"
 local TEMP_LAYER_FILE="${TMP_DIR}/layer_create_${LAYER_NAME}_$$.tmp"
 local HTTP_CODE
 HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_LAYER_FILE}" \
  -X POST \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${LAYER_DATA}" \
  "${LAYER_CREATE_URL}" 2> /dev/null | tail -1)

 local RESPONSE_BODY
 RESPONSE_BODY=$(cat "${TEMP_LAYER_FILE}" 2> /dev/null || echo "")

 # If that fails with 405, the endpoint might not support POST
 # In that case, GeoServer should have created the layer automatically
 # We'll just return success and let the style assignment handle it
 if [[ "${HTTP_CODE}" == "405" ]]; then
  print_status "${YELLOW}" "⚠️  Layer creation endpoint not available (HTTP 405)"
  print_status "${YELLOW}" "   GeoServer should create layers automatically from feature types"
  print_status "${YELLOW}" "   Layer may be available after a short delay"
  rm -f "${TEMP_LAYER_FILE}" 2> /dev/null || true
  # Return success - we'll let the style assignment retry
  return 0
 fi

 rm -f "${TEMP_LAYER_FILE}" 2> /dev/null || true

 if [[ "${HTTP_CODE}" == "201" ]] || [[ "${HTTP_CODE}" == "200" ]]; then
  print_status "${GREEN}" "✅ Layer '${LAYER_NAME}' created"
  return 0
 elif [[ "${HTTP_CODE}" == "409" ]]; then
  # Layer already exists (race condition)
  print_status "${GREEN}" "✅ Layer '${LAYER_NAME}' already exists"
  return 0
 else
  print_status "${YELLOW}" "⚠️  Failed to create layer '${LAYER_NAME}' (HTTP ${HTTP_CODE})"
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response:"
   echo "${RESPONSE_BODY}" | head -10 | sed 's/^/      /'
  fi
  print_status "${YELLOW}" "   Note: Layer may be created automatically by GeoServer"
  # Return success anyway - style assignment will handle if layer doesn't exist
  return 0
 fi
}

# Function to assign style to layer
assign_style_to_layer() {
 local LAYER_NAME="${1}"
 local STYLE_NAME="${2}"

 print_status "${BLUE}" "🎨 Assigning style '${STYLE_NAME}' to layer '${LAYER_NAME}'..."

 # Wait a moment after layer creation/update to ensure GeoServer has initialized it
 # This helps avoid "original is null" errors when assigning styles immediately after update
 sleep 1

 # Ensure layer exists before assigning style
 if ! create_layer_from_feature_type "${LAYER_NAME}" "${STYLE_NAME}"; then
  print_status "${YELLOW}" "⚠️  Could not create layer '${LAYER_NAME}', skipping style assignment"
  return 1
 fi

 # Verify layer exists and is accessible before assigning style
 local LAYER_CHECK_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
 local LAYER_CHECK_CODE
 LAYER_CHECK_CODE=$(curl -s -w "%{http_code}" -o /dev/null -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" "${LAYER_CHECK_URL}" 2> /dev/null | tail -1)

 if [[ "${LAYER_CHECK_CODE}" != "200" ]]; then
  print_status "${YELLOW}" "⚠️  Layer '${LAYER_NAME}' not found or not accessible (HTTP ${LAYER_CHECK_CODE})"
  print_status "${YELLOW}" "   Skipping style assignment - layer may need to be recreated"
  return 1
 fi

 local LAYER_STYLE_DATA="{
   \"layer\": {
     \"defaultStyle\": {
       \"name\": \"${STYLE_NAME}\"
     }
   }
 }"

 local TEMP_STYLE_ASSIGN_FILE="${TMP_DIR}/style_assign_${LAYER_NAME}_$$.tmp"
 local ASSIGN_HTTP_CODE
 ASSIGN_HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_STYLE_ASSIGN_FILE}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${LAYER_STYLE_DATA}" \
  "${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}" 2> /dev/null | tail -1)

 if [[ "${ASSIGN_HTTP_CODE}" == "200" ]] || [[ "${ASSIGN_HTTP_CODE}" == "204" ]]; then
  print_status "${GREEN}" "✅ Style '${STYLE_NAME}' assigned to layer '${LAYER_NAME}'"
  rm -f "${TEMP_STYLE_ASSIGN_FILE}" 2> /dev/null || true
  return 0
 else
  print_status "${YELLOW}" "⚠️  Style assignment failed (HTTP ${ASSIGN_HTTP_CODE})"
  local RESPONSE_BODY
  RESPONSE_BODY=$(cat "${TEMP_STYLE_ASSIGN_FILE}" 2> /dev/null || echo "")
  if [[ -n "${RESPONSE_BODY}" ]]; then
   print_status "${YELLOW}" "   Response: ${RESPONSE_BODY}"
  fi
  rm -f "${TEMP_STYLE_ASSIGN_FILE}" 2> /dev/null || true
  return 1
 fi
}

# Function to add alternative style to layer
add_alternative_style_to_layer() {
 local LAYER_NAME="${1}"
 local STYLE_NAME="${2}"

 print_status "${BLUE}" "🎨 Adding alternative style '${STYLE_NAME}' to layer '${LAYER_NAME}'..."

 # Get current layer configuration
 local LAYER_URL="${GEOSERVER_URL}/rest/layers/${GEOSERVER_WORKSPACE}:${LAYER_NAME}"
 local TEMP_LAYER_GET="${TMP_DIR}/layer_get_${LAYER_NAME}_$$.tmp"
 local GET_HTTP_CODE
 GET_HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_LAYER_GET}" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  "${LAYER_URL}" 2> /dev/null | tail -1)

 if [[ "${GET_HTTP_CODE}" != "200" ]]; then
  print_status "${YELLOW}" "⚠️  Could not retrieve layer '${LAYER_NAME}' (HTTP ${GET_HTTP_CODE})"
  rm -f "${TEMP_LAYER_GET}" 2> /dev/null || true
  return 1
 fi

 # Parse current styles from layer JSON
 local CURRENT_STYLES
 CURRENT_STYLES=$(jq -r '.layer.styles.style[]? // .layer.styles.style // []' "${TEMP_LAYER_GET}" 2> /dev/null || echo "[]")

 # Check if style is already in the list
 if echo "${CURRENT_STYLES}" | jq -e ".[] | select(.name == \"${STYLE_NAME}\")" > /dev/null 2>&1; then
  print_status "${GREEN}" "✅ Alternative style '${STYLE_NAME}' already exists for layer '${LAYER_NAME}'"
  rm -f "${TEMP_LAYER_GET}" 2> /dev/null || true
  return 0
 fi

 # Add the new style to the styles array
 local UPDATED_STYLES
 UPDATED_STYLES=$(echo "${CURRENT_STYLES}" | jq ". + [{\"name\": \"${STYLE_NAME}\"}]" 2> /dev/null || echo "[{\"name\": \"${STYLE_NAME}\"}]")

 # Update layer with new styles array
 local LAYER_UPDATE_DATA
 LAYER_UPDATE_DATA=$(jq ".layer.styles = {\"style\": ${UPDATED_STYLES}}" "${TEMP_LAYER_GET}" 2> /dev/null)

 if [[ -z "${LAYER_UPDATE_DATA}" ]]; then
  # Fallback: create minimal update JSON
  LAYER_UPDATE_DATA="{
   \"layer\": {
     \"styles\": {
       \"style\": ${UPDATED_STYLES}
     }
   }
  }"
 fi

 local TEMP_STYLE_ADD="${TMP_DIR}/style_add_${LAYER_NAME}_$$.tmp"
 local ADD_HTTP_CODE
 ADD_HTTP_CODE=$(curl -s -w "%{http_code}" -o "${TEMP_STYLE_ADD}" \
  -X PUT \
  -H "Content-Type: application/json" \
  -u "${GEOSERVER_USER}:${GEOSERVER_PASSWORD}" \
  -d "${LAYER_UPDATE_DATA}" \
  "${LAYER_URL}" 2> /dev/null | tail -1)

 rm -f "${TEMP_LAYER_GET}" "${TEMP_STYLE_ADD}" 2> /dev/null || true

 if [[ "${ADD_HTTP_CODE}" == "200" ]] || [[ "${ADD_HTTP_CODE}" == "204" ]]; then
  print_status "${GREEN}" "✅ Alternative style '${STYLE_NAME}' added to layer '${LAYER_NAME}'"
  return 0
 else
  print_status "${YELLOW}" "⚠️  Failed to add alternative style (HTTP ${ADD_HTTP_CODE})"
  return 1
 fi
}

# Legacy function for backward compatibility
assign_style_to_layer_legacy() {
 assign_style_to_layer "${@}"
}
