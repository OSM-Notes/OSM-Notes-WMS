-- Grant read-only permissions to GeoServer DB roles on 'notes' database
-- Roles: geoserver (legacy), osm_notes_wms_user (default GEOSERVER_DBUSER in geoserverConfig.sh)
-- Includes SELECT on public WMS views (notes_open_view, notes_closed_view, disputed_areas_view)
--
-- Run as database owner or superuser after sql/wms/prepareDatabase.sql (views must exist)
-- Usage: psql -d notes -f sql/wms/grantGeoserverPermissions.sql
--
-- Author: Andres Gomez (AngocA)
-- Version: 2026-04-02

-- Connect to notes database
\c notes

-- Check if geoserver user exists, create if not
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_user WHERE usename = 'geoserver') THEN
    CREATE USER geoserver;
    RAISE NOTICE 'User geoserver created';
  ELSE
    RAISE NOTICE 'User geoserver already exists';
  END IF;
END $$;

-- Grant CONNECT privilege on database
GRANT CONNECT ON DATABASE notes TO geoserver;

-- Grant USAGE on schemas
GRANT USAGE ON SCHEMA public TO geoserver;
GRANT USAGE ON SCHEMA wms TO geoserver;

-- Grant SELECT (read-only) on all existing tables in wms schema
GRANT SELECT ON ALL TABLES IN SCHEMA wms TO geoserver;

-- Grant SELECT on all existing sequences in wms schema (if any)
GRANT SELECT ON ALL SEQUENCES IN SCHEMA wms TO geoserver;

-- Set default privileges for future tables in wms schema
-- This ensures new tables created in wms schema will automatically have read permissions
ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON TABLES TO geoserver;
ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON SEQUENCES TO geoserver;

-- Grant SELECT on countries table (needed for WMS layers that use country data)
GRANT SELECT ON TABLE countries TO geoserver;

-- Public views used by GeoServer feature types (not included in ALL TABLES IN SCHEMA wms)
GRANT SELECT ON TABLE public.notes_open_view TO geoserver;
GRANT SELECT ON TABLE public.notes_closed_view TO geoserver;
GRANT SELECT ON TABLE public.disputed_areas_view TO geoserver;

-- =============================================================================
-- osm_notes_wms_user (default GEOSERVER_DBUSER in geoserverConfig.sh)
-- Same read-only profile as geoserver; required for WMS layers on public.* views
-- Skipped automatically if the role does not exist
-- =============================================================================
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'osm_notes_wms_user') THEN
    RAISE NOTICE 'Skipping grants: role osm_notes_wms_user does not exist (create it, then re-run this file)';
    RETURN;
  END IF;
  EXECUTE 'GRANT CONNECT ON DATABASE notes TO osm_notes_wms_user';
  EXECUTE 'GRANT USAGE ON SCHEMA public TO osm_notes_wms_user';
  EXECUTE 'GRANT USAGE ON SCHEMA wms TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA wms TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA wms TO osm_notes_wms_user';
  EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON TABLES TO osm_notes_wms_user';
  EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON SEQUENCES TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON TABLE countries TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON TABLE public.notes_open_view TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON TABLE public.notes_closed_view TO osm_notes_wms_user';
  EXECUTE 'GRANT SELECT ON TABLE public.disputed_areas_view TO osm_notes_wms_user';
  RAISE NOTICE 'Grants applied to osm_notes_wms_user';
END $$;

-- Verify permissions
\echo '✅ Permissions granted to geoserver user:'
\echo '   - CONNECT on database notes'
\echo '   - USAGE on schemas public and wms'
\echo '   - SELECT on all tables in wms schema'
\echo '   - SELECT on countries table and public WMS views (notes_*, disputed_areas_view)'
\echo '   - Default privileges set for future tables in wms schema'
\echo ''
\echo '✅ Same grants applied to osm_notes_wms_user (if role exists)'
\echo ''
\echo 'To verify, run as geoserver user:'
\echo '   psql -U geoserver -d notes -c "SELECT COUNT(*) FROM wms.notes_wms;"'
\echo 'To verify as datastore user:'
\echo '   psql -U osm_notes_wms_user -d notes -c "SELECT COUNT(*) FROM public.notes_open_view LIMIT 1;"'

