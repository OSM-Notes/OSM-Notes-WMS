#!/bin/bash
# GeoServer Configuration Install Functions
# Functions for installing GeoServer configuration
#
# Author: Andres Gomez (AngocA)
# Version: 2025-12-08
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
 print_status "${BLUE}" "🎨 Uploading styles..."
 local STYLE_ERRORS=0
 if ! upload_style "${WMS_STYLE_OPEN_FILE}" "${WMS_STYLE_OPEN_NAME}"; then
  ((STYLE_ERRORS++))
 fi
 if ! upload_style "${WMS_STYLE_CLOSED_FILE}" "${WMS_STYLE_CLOSED_NAME}"; then
  ((STYLE_ERRORS++))
 fi
 if ! upload_style "${WMS_STYLE_COUNTRIES_FILE}" "${WMS_STYLE_COUNTRIES_NAME}"; then
  ((STYLE_ERRORS++))
 fi
 if ! upload_style "${WMS_STYLE_DISPUTED_FILE}" "${WMS_STYLE_DISPUTED_NAME}"; then
  ((STYLE_ERRORS++))
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
 local COUNTRIES_SQL="SELECT country_id, country_name, country_name_en, geom AS geometry FROM public.countries ORDER BY country_name"
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

 print_status "${GREEN}" "✅ GeoServer configuration completed successfully"
 show_configuration_summary
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
}
