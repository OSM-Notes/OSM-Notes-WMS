#!/bin/bash
# GeoServer Configuration Install Functions
# Functions for installing GeoServer configuration
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-29
# Function to install GeoServer configuration
install_geoserver_config() {
 print_status "${BLUE}" "🚀 Installing GeoServer configuration..."

 # Check if GeoServer is already configured
 if is_geoserver_configured; then
  if [[ "${FORCE:-false}" != "true" ]]; then
   print_status "${YELLOW}" "⚠️  GeoServer is already configured. Use --force to reconfigure."
   print_status "${YELLOW}" "💡 Tip: If you're having issues, try: $0 remove && $0 install"
   return 0
  else
   print_status "${YELLOW}" "⚠️  Force mode: Reconfiguring existing GeoServer setup..."
   # Optionally clean up before reconfiguring
   # Note: We don't do full cleanup here to avoid accidental data loss
   # User should run 'remove' command explicitly if they want clean state
  fi
 fi

 if [[ "${DRY_RUN:-false}" == "true" ]]; then
  print_status "${YELLOW}" "DRY RUN: Would configure GeoServer for OSM notes WMS"
  return 0
 fi

 # Create workspace and namespace
 create_workspace
 create_namespace

 # Create datastore
 if ! create_datastore; then
  print_status "${RED}" "❌ ERROR: GeoServer configuration failed (datastore)"
  exit "${ERROR_GENERAL}"
 fi

 # Upload all styles first
 # Note: Style upload via REST API may fail due to permission restrictions (403 Forbidden)
 # In that case, styles must be created manually through the GeoServer web interface
 print_status "${BLUE}" "🎨 Attempting to upload styles via REST API..."
 print_status "${YELLOW}" "   Note: If upload fails (403 Forbidden), styles must be created manually via web interface"
 local STYLE_ERRORS=0
 local MANUAL_STYLES_NEEDED=false
 local STYLES_NEEDING_MANUAL=()

 if ! upload_style "${WMS_STYLE_OPEN_FILE}" "${WMS_STYLE_OPEN_NAME}"; then
  local UPLOAD_EXIT_CODE=$?
  ((STYLE_ERRORS++))
  if [[ ${UPLOAD_EXIT_CODE} -eq 2 ]]; then
   MANUAL_STYLES_NEEDED=true
   STYLES_NEEDING_MANUAL+=("notesopen:${WMS_STYLE_OPEN_FILE}")
  fi
 fi
 if ! upload_style "${WMS_STYLE_CLOSED_FILE}" "${WMS_STYLE_CLOSED_NAME}"; then
  local UPLOAD_EXIT_CODE=$?
  ((STYLE_ERRORS++))
  if [[ ${UPLOAD_EXIT_CODE} -eq 2 ]]; then
   MANUAL_STYLES_NEEDED=true
   STYLES_NEEDING_MANUAL+=("notesclosed:${WMS_STYLE_CLOSED_FILE}")
  fi
 fi
 if ! upload_style "${WMS_STYLE_COUNTRIES_FILE}" "${WMS_STYLE_COUNTRIES_NAME}"; then
  local UPLOAD_EXIT_CODE=$?
  ((STYLE_ERRORS++))
  if [[ ${UPLOAD_EXIT_CODE} -eq 2 ]]; then
   MANUAL_STYLES_NEEDED=true
   STYLES_NEEDING_MANUAL+=("countries:${WMS_STYLE_COUNTRIES_FILE}")
  fi
 fi
 if ! upload_style "${WMS_STYLE_DISPUTED_FILE}" "${WMS_STYLE_DISPUTED_NAME}"; then
  local UPLOAD_EXIT_CODE=$?
  ((STYLE_ERRORS++))
  if [[ ${UPLOAD_EXIT_CODE} -eq 2 ]]; then
   MANUAL_STYLES_NEEDED=true
   STYLES_NEEDING_MANUAL+=("disputed_and_unclaimed_areas:${WMS_STYLE_DISPUTED_FILE}")
  fi
 fi

 # IMPORTANT: After uploading styles via REST API, copy SLD files directly to preserve colors
 # GeoServer REST API transforms SLD 1.1.0 to 1.0.0 and loses SvgParameter elements (colors)
 # Process: 1) Upload via HTTP REST API (registers styles in GeoServer)
 #          2) Copy SLD files directly (preserves colors that REST API loses)
 print_status "${YELLOW}" ""
 print_status "${YELLOW}" "⚠️  IMPORTANT: Preserving SLD colors..."
 print_status "${YELLOW}" "   Styles uploaded via HTTP REST API (required for GeoServer registration)"
 print_status "${YELLOW}" "   Now copying SLD files directly to preserve colors (REST API loses them)..."
 local GEOSERVER_STYLES_DIR=""
 if [[ -n "${GEOSERVER_DATA_DIR:-}" ]] && [[ -d "${GEOSERVER_DATA_DIR}/styles" ]]; then
  GEOSERVER_STYLES_DIR="${GEOSERVER_DATA_DIR}/styles"
 elif [[ -n "${GEOSERVER_HOME:-}" ]] && [[ -d "${GEOSERVER_HOME}/data/geoserver/styles" ]]; then
  GEOSERVER_STYLES_DIR="${GEOSERVER_HOME}/data/geoserver/styles"
 elif [[ -d "/home/geoserver/data/geoserver/styles" ]]; then
  GEOSERVER_STYLES_DIR="/home/geoserver/data/geoserver/styles"
 fi

 if [[ -n "${GEOSERVER_STYLES_DIR}" ]]; then
  local COPY_FAILED=false
  local FILES_TO_COPY=()
  # Try to copy OpenNotes and ClosedNotes (the ones with colors)
  for STYLE_FILE in "${WMS_STYLE_OPEN_FILE}" "${WMS_STYLE_CLOSED_FILE}"; do
   local STYLE_BASENAME=$(basename "${STYLE_FILE}" .sld)
   local STYLE_NAME=""
   case "${STYLE_BASENAME}" in
    OpenNotes) STYLE_NAME="notesopen" ;;
    ClosedNotes) STYLE_NAME="notesclosed" ;;
    *) continue ;;
   esac
   local TARGET_SLD="${GEOSERVER_STYLES_DIR}/${STYLE_NAME}.sld"
   local COPY_SUCCESS=false

   # First try without sudo (if we have write permissions on directory or file)
   # Check if directory is writable OR if file exists and is writable
   if [[ -w "${GEOSERVER_STYLES_DIR}" ]] || ([[ -f "${TARGET_SLD}" ]] && [[ -w "${TARGET_SLD}" ]]); then
    if cp "${STYLE_FILE}" "${TARGET_SLD}" 2>/dev/null; then
     # Try to set ownership if we have permissions (chown may fail, but that's OK)
     if [[ -n "${GEOSERVER_USER:-geoserver}" ]] && id "${GEOSERVER_USER}" &>/dev/null; then
      chown "${GEOSERVER_USER}:${GEOSERVER_USER}" "${TARGET_SLD}" 2>/dev/null || true
     fi
     # Verify that colors are preserved (check for SvgParameter with fill)
     if grep -q 'SvgParameter.*fill' "${TARGET_SLD}" 2>/dev/null; then
      print_status "${GREEN}" "   ✅ ${STYLE_NAME}.sld copied directly (colors preserved)"
      COPY_SUCCESS=true
     else
      print_status "${YELLOW}" "   ⚠️  ${STYLE_NAME}.sld copied but colors missing - will need manual copy"
      COPY_FAILED=true
      FILES_TO_COPY+=("${STYLE_NAME}")
     fi
    fi
   fi

   # If copy failed and sudo is available, try with sudo (non-interactive)
   if [[ "${COPY_SUCCESS}" == "false" ]] && command -v sudo >/dev/null 2>&1; then
    # Try to copy with sudo -n (non-interactive, fails if password required)
    # This will only work if sudo is configured with NOPASSWD
    if sudo -n cp "${STYLE_FILE}" "${TARGET_SLD}" 2>/dev/null; then
     if [[ -n "${GEOSERVER_USER:-geoserver}" ]] && id "${GEOSERVER_USER}" &>/dev/null; then
      sudo chown "${GEOSERVER_USER}:${GEOSERVER_USER}" "${TARGET_SLD}" 2>/dev/null || true
     fi
     # Verify that colors are preserved (check for SvgParameter with fill)
     if grep -q 'SvgParameter.*fill' "${TARGET_SLD}" 2>/dev/null; then
      print_status "${GREEN}" "   ✅ ${STYLE_NAME}.sld copied directly with sudo (colors preserved)"
      COPY_SUCCESS=true
     else
      print_status "${YELLOW}" "   ⚠️  ${STYLE_NAME}.sld copied but colors missing - will need manual copy"
      COPY_FAILED=true
      FILES_TO_COPY+=("${STYLE_NAME}")
     fi
    else
     # sudo -n failed (requires password) - mark for manual copy
     COPY_FAILED=true
     local FOUND=false
     for EXISTING in "${FILES_TO_COPY[@]}"; do
      if [[ "${EXISTING}" == "${STYLE_NAME}" ]]; then
       FOUND=true
       break
      fi
     done
     if [[ "${FOUND}" == "false" ]]; then
      FILES_TO_COPY+=("${STYLE_NAME}")
     fi
    fi
   fi

   # If still failed, mark for manual copy
   if [[ "${COPY_SUCCESS}" == "false" ]]; then
    COPY_FAILED=true
    local FOUND=false
    for EXISTING in "${FILES_TO_COPY[@]}"; do
     if [[ "${EXISTING}" == "${STYLE_NAME}" ]]; then
      FOUND=true
      break
     fi
    done
    if [[ "${FOUND}" == "false" ]]; then
     FILES_TO_COPY+=("${STYLE_NAME}")
    fi
   fi
  done

  # Always show copy commands and restart instructions
  # Even if copy succeeded, GeoServer may need restart to reload styles from filesystem
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   ⚠️  IMPORTANT: GeoServer needs to reload styles from filesystem"
  print_status "${YELLOW}" "   GeoServer REST API transforms SLD 1.1.0 → 1.0.0 when storing internally"
  print_status "${YELLOW}" "   After copying SLD files, you need to:"
  print_status "${YELLOW}" ""
  if [[ "${COPY_FAILED}" == "true" ]] || [[ ${#FILES_TO_COPY[@]} -gt 0 ]]; then
   print_status "${YELLOW}" "   1. Copy SLD files manually (if not already copied):"
   print_status "${YELLOW}" "      sudo cp ${WMS_STYLE_OPEN_FILE} ${GEOSERVER_STYLES_DIR}/notesopen.sld"
   print_status "${YELLOW}" "      sudo cp ${WMS_STYLE_CLOSED_FILE} ${GEOSERVER_STYLES_DIR}/notesclosed.sld"
   if [[ -n "${GEOSERVER_USER:-geoserver}" ]]; then
    print_status "${YELLOW}" "      sudo chown ${GEOSERVER_USER}:${GEOSERVER_USER} ${GEOSERVER_STYLES_DIR}/notesopen.sld ${GEOSERVER_STYLES_DIR}/notesclosed.sld"
   fi
   print_status "${YELLOW}" ""
  fi
  print_status "${YELLOW}" "   2. Recreate styles to point to filesystem files:"
  print_status "${YELLOW}" "      curl -u \"\${GEOSERVER_USER}:\${GEOSERVER_PASSWORD}\" \"\${GEOSERVER_URL}/rest/styles/notesclosed\" -X DELETE"
  print_status "${YELLOW}" "      curl -u \"\${GEOSERVER_USER}:\${GEOSERVER_PASSWORD}\" \"\${GEOSERVER_URL}/rest/styles/notesopen\" -X DELETE"
  print_status "${YELLOW}" "      curl -u \"\${GEOSERVER_USER}:\${GEOSERVER_PASSWORD}\" \"\${GEOSERVER_URL}/rest/workspaces/\${GEOSERVER_WORKSPACE}/styles?name=notesclosed\" -X POST -H 'Content-Type: text/xml' -d '<style><name>notesclosed</name><filename>notesclosed.sld</filename></style>'"
  print_status "${YELLOW}" "      curl -u \"\${GEOSERVER_USER}:\${GEOSERVER_PASSWORD}\" \"\${GEOSERVER_URL}/rest/workspaces/\${GEOSERVER_WORKSPACE}/styles?name=notesopen\" -X POST -H 'Content-Type: text/xml' -d '<style><name>notesopen</name><filename>notesopen.sld</filename></style>'"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   3. Restart GeoServer to reload styles:"
  print_status "${YELLOW}" "      sudo systemctl restart geoserver"
  print_status "${YELLOW}" ""
  if [[ "${COPY_FAILED}" != "true" ]] && [[ ${#FILES_TO_COPY[@]} -eq 0 ]]; then
   print_status "${GREEN}" "   ✅ SLD files copied successfully with colors preserved"
  fi
 fi

 # Upload country-based styles (alternative styles)
 # If styles failed and not using --force, exit
 if [[ ${STYLE_ERRORS} -gt 0 ]] && [[ "${FORCE:-false}" != "true" ]]; then
  print_status "${RED}" "❌ ERROR: Failed to upload ${STYLE_ERRORS} style(s)"
  print_status "${YELLOW}" "   Use --force to continue despite style upload errors"
  exit "${ERROR_GENERAL}"
 elif [[ ${STYLE_ERRORS} -gt 0 ]]; then
  print_status "${YELLOW}" "⚠️  ${STYLE_ERRORS} style(s) failed to upload, continuing with --force"
 fi

 OPTIONAL_DISPUTED_TERRITORIES_CREATED=false

 # Create layer 1: Open Notes (direct view - no schema prefix since datastore uses public)
 # Datastore is configured with schema='public', so we can reference views directly
 print_status "${BLUE}" "📊 Creating layer 1/4: Open Notes..."
 local OPEN_LAYER_NAME="notesopen"
 local OPEN_VIEW_NAME="notes_open_view"
 if create_feature_type_from_table "${OPEN_LAYER_NAME}" "${OPEN_VIEW_NAME}" "${WMS_LAYER_OPEN_NAME}" "${WMS_LAYER_OPEN_DESCRIPTION}"; then
  # Extract actual style name from SLD
  local OPEN_STYLE_NAME
  OPEN_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_OPEN_FILE}")
  if [[ -z "${OPEN_STYLE_NAME}" ]]; then
   OPEN_STYLE_NAME="${WMS_STYLE_OPEN_NAME}"
  fi
  assign_style_to_layer "${OPEN_LAYER_NAME}" "${OPEN_STYLE_NAME}"
 fi

 # Create layer 2: Closed Notes (direct view - no schema prefix since datastore uses public)
 # Datastore is configured with schema='public', so we can reference views directly
 print_status "${BLUE}" "📊 Creating layer 2/4: Closed Notes..."
 local CLOSED_LAYER_NAME="notesclosed"
 local CLOSED_VIEW_NAME="notes_closed_view"
 if create_feature_type_from_table "${CLOSED_LAYER_NAME}" "${CLOSED_VIEW_NAME}" "${WMS_LAYER_CLOSED_NAME}" "${WMS_LAYER_CLOSED_DESCRIPTION}"; then
  # Extract actual style name from SLD
  local CLOSED_STYLE_NAME
  CLOSED_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_CLOSED_FILE}")
  if [[ -z "${CLOSED_STYLE_NAME}" ]]; then
   CLOSED_STYLE_NAME="${WMS_STYLE_CLOSED_NAME}"
  fi
  assign_style_to_layer "${CLOSED_LAYER_NAME}" "${CLOSED_STYLE_NAME}"
 fi

 # Create layer 3: Countries (SQL view)
 # Note: countries table is in public schema, not wms schema
 # Use SQL view to access public schema from wms datastore
 print_status "${BLUE}" "📊 Creating layer 3/4: Countries..."
 local COUNTRIES_LAYER_NAME="countries"
 local COUNTRIES_TITLE="Countries and Maritime Areas"
 local COUNTRIES_DESCRIPTION="Country boundaries and maritime zones from OpenStreetMap"
 local COUNTRIES_SQL="SELECT country_id, country_name, country_name_en, is_maritime, geom AS geometry FROM public.countries ORDER BY country_name"
 if create_sql_view_layer "${COUNTRIES_LAYER_NAME}" "${COUNTRIES_SQL}" "${COUNTRIES_TITLE}" "${COUNTRIES_DESCRIPTION}" "geometry"; then
  # Extract actual style name from SLD
  local COUNTRIES_STYLE_NAME
  COUNTRIES_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_COUNTRIES_FILE}")
  if [[ -z "${COUNTRIES_STYLE_NAME}" ]]; then
   COUNTRIES_STYLE_NAME="${WMS_STYLE_COUNTRIES_NAME}"
  fi
  assign_style_to_layer "${COUNTRIES_LAYER_NAME}" "${COUNTRIES_STYLE_NAME}"
 fi

 # Create layer 4: Disputed and Unclaimed Areas (direct view reference)
 # View is created in public schema to simplify GeoServer datastore configuration
 print_status "${BLUE}" "📊 Creating layer 4/4: Disputed and Unclaimed Areas..."
 local DISPUTED_LAYER_NAME="disputedareas"
 local DISPUTED_VIEW_NAME="disputed_areas_view"
 if create_feature_type_from_table "${DISPUTED_LAYER_NAME}" "${DISPUTED_VIEW_NAME}" "${WMS_LAYER_DISPUTED_NAME}" "${WMS_LAYER_DISPUTED_DESCRIPTION}"; then
  # Extract actual style name from SLD
  local DISPUTED_STYLE_NAME
  DISPUTED_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_DISPUTED_FILE}")
  if [[ -z "${DISPUTED_STYLE_NAME}" ]]; then
   DISPUTED_STYLE_NAME="${WMS_STYLE_DISPUTED_NAME}"
  fi
  assign_style_to_layer "${DISPUTED_LAYER_NAME}" "${DISPUTED_STYLE_NAME}"
 fi

 # Optional layer: curated disputed territories from OSM-Notes-Ingestion
 # This table is optional and may not exist until Ingestion runs the dedicated job.
 local HAS_DISPUTED_TERRITORIES=false
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
 local HAS_DISPUTED_TABLE
 HAS_DISPUTED_TABLE=$(eval "${PSQL_CMD} -c \"SELECT EXISTS(SELECT 1 FROM information_schema.tables WHERE table_schema = 'public' AND table_name = 'disputed_territories_wms');\"" 2> /dev/null | tr -d '[:space:]' || echo "f")
 if [[ -n "${DBPASSWORD}" ]]; then
  unset PGPASSWORD 2> /dev/null || true
 fi
 if [[ "${HAS_DISPUTED_TABLE}" == "t" ]]; then
  HAS_DISPUTED_TERRITORIES=true
 fi

 if [[ "${HAS_DISPUTED_TERRITORIES}" == "true" ]]; then
  print_status "${BLUE}" "📊 Creating optional layer: Disputed Territories (Ingestion)..."
  local DISPUTED_TERRITORIES_LAYER_NAME="disputedterritories"
  local DISPUTED_TERRITORIES_SQL="SELECT id, kind::text AS kind, name, description, reference_url, updated_at, geom AS geometry FROM public.disputed_territories_wms WHERE geom IS NOT NULL ORDER BY kind, name"
  if create_sql_view_layer "${DISPUTED_TERRITORIES_LAYER_NAME}" "${DISPUTED_TERRITORIES_SQL}" "Disputed Territories (Ingestion)" "Curated disputed/unclaimed territories provided by OSM-Notes-Ingestion." "geometry"; then
   OPTIONAL_DISPUTED_TERRITORIES_CREATED=true
   # Reuse the disputed style as fallback until a dedicated style is provided.
   local DISPUTED_STYLE_NAME
   DISPUTED_STYLE_NAME=$(extract_style_name_from_sld "${WMS_STYLE_DISPUTED_FILE}")
   if [[ -z "${DISPUTED_STYLE_NAME}" ]]; then
    DISPUTED_STYLE_NAME="${WMS_STYLE_DISPUTED_NAME}"
   fi
   assign_style_to_layer "${DISPUTED_TERRITORIES_LAYER_NAME}" "${DISPUTED_STYLE_NAME}"
  fi
 else
  print_status "${YELLOW}" "⚠️  Optional layer skipped: public.disputed_territories_wms not found"
  print_status "${YELLOW}" "   Run OSM-Notes-Ingestion disputed territories update to enable it."
 fi

 print_status "${GREEN}" "✅ GeoServer configuration completed successfully"
 show_configuration_summary

 # Show manual style configuration instructions only if styles failed to upload
 if [[ "${MANUAL_STYLES_NEEDED}" == "true" ]] || [[ ${STYLE_ERRORS} -gt 0 ]]; then
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "⚠️  IMPORTANT: Style configuration must be completed manually"
  if [[ "${MANUAL_STYLES_NEEDED}" == "true" ]]; then
   print_status "${YELLOW}" "   The GeoServer REST API cannot create styles due to permission restrictions (403 Forbidden)."
   print_status "${YELLOW}" "   The GeoServer user does not have ADMIN permissions to create styles via REST API."
  else
   print_status "${YELLOW}" "   Some styles failed to upload via REST API."
  fi
  print_status "${YELLOW}" "   You must complete the style configuration through the GeoServer web interface:"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   1. Open GeoServer web interface:"
  print_status "${YELLOW}" "      ${GEOSERVER_URL}/web"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   2. Navigate to Styles → Add a new style"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   3. Upload the following SLD files:"
  print_status "${YELLOW}" "      - Style name: notesopen"
  print_status "${YELLOW}" "        File: ${WMS_STYLE_OPEN_FILE}"
  print_status "${YELLOW}" "      - Style name: notesclosed"
  print_status "${YELLOW}" "        File: ${WMS_STYLE_CLOSED_FILE}"
  print_status "${YELLOW}" "      - Style name: countries"
  print_status "${YELLOW}" "        File: ${WMS_STYLE_COUNTRIES_FILE}"
  print_status "${YELLOW}" "      - Style name: disputed_and_unclaimed_areas"
  print_status "${YELLOW}" "        File: ${WMS_STYLE_DISPUTED_FILE}"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   4. Assign styles to layers:"
  print_status "${YELLOW}" "      - Navigate to Layers → osm_notes:notesopen"
  print_status "${YELLOW}" "        Set Default Style to: notesopen"
  print_status "${YELLOW}" "      - Navigate to Layers → osm_notes:notesclosed"
  print_status "${YELLOW}" "        Set Default Style to: notesclosed"
  print_status "${YELLOW}" "      - Navigate to Layers → osm_notes:countries"
  print_status "${YELLOW}" "        Set Default Style to: countries"
  print_status "${YELLOW}" "      - Navigate to Layers → osm_notes:disputedareas"
  print_status "${YELLOW}" "        Set Default Style to: disputed_and_unclaimed_areas"
  print_status "${YELLOW}" ""
  print_status "${YELLOW}" "   5. After assigning styles, restart GeoServer:"
  print_status "${YELLOW}" "      sudo systemctl restart geoserver"
  print_status "${YELLOW}" ""
 fi
}

# Function to show configuration summary
show_configuration_summary() {
 print_status "${BLUE}" "📋 Configuration Summary:"
 print_status "${BLUE}" "   - Workspace: ${GEOSERVER_WORKSPACE}"
 print_status "${BLUE}" "   - Datastore: ${GEOSERVER_STORE}"
 print_status "${BLUE}" "   - Database: ${DBHOST}:${DBPORT}/${DBNAME}"
 print_status "${BLUE}" "   - Schemas: wms, public (specified in SQL views)"
 print_status "${BLUE}" "   - WMS URL: ${GEOSERVER_URL}/wms"
 print_status "${BLUE}" ""
 print_status "${BLUE}" "📊 Layers created:"
 print_status "${BLUE}" "   1. ${GEOSERVER_WORKSPACE}:notesopen (Open Notes)"
 print_status "${BLUE}" "   2. ${GEOSERVER_WORKSPACE}:notesclosed (Closed Notes)"
 print_status "${BLUE}" "   3. ${GEOSERVER_WORKSPACE}:countries (Countries)"
 print_status "${BLUE}" "   4. ${GEOSERVER_WORKSPACE}:disputedareas (Disputed/Unclaimed Areas)"
 if [[ "${OPTIONAL_DISPUTED_TERRITORIES_CREATED:-false}" == "true" ]]; then
  print_status "${BLUE}" "   5. ${GEOSERVER_WORKSPACE}:disputedterritories (Disputed Territories from Ingestion)"
 else
  print_status "${BLUE}" "   5. ${GEOSERVER_WORKSPACE}:disputedterritories (optional; not created)"
 fi
}
