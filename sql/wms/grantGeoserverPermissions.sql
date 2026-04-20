-- Grant read-only permissions for GeoServer datastore role and optional legacy role.
-- Pass from psql: -v dbname=YOUR_DB -v read_role=YOUR_GEOSERVER_USER
--   (dbname must match the database you connect to with -d)
--
-- Run as database owner or superuser after sql/wms/prepareDatabase.sql (views must exist).
-- wmsManager.sh install runs this automatically; if it fails, run the same command as superuser/DBA.
--
-- Author: Andres Gomez (AngocA)
-- Version: 2026-04-03

-- Legacy role "geoserver" (optional): create only if privileges allow
DO $legacy$
BEGIN
  IF EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'geoserver') THEN
    RAISE NOTICE 'Role geoserver already exists';
  ELSE
    BEGIN
      CREATE USER geoserver;
      RAISE NOTICE 'User geoserver created';
    EXCEPTION
      WHEN SQLSTATE '42501' THEN
        RAISE NOTICE 'Skipping CREATE USER geoserver: permission denied (requires superuser or CREATEROLE).';
      WHEN OTHERS THEN
        RAISE NOTICE 'Skipping CREATE USER geoserver: %', SQLERRM;
    END;
  END IF;
END
$legacy$;

-- Grants to legacy geoserver when that role exists
DO $ggeo$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'geoserver') THEN
    RAISE NOTICE 'Skipping grants to geoserver: role does not exist';
    RETURN;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms') THEN
    RAISE NOTICE 'Skipping grants to geoserver: schema wms does not exist';
    RETURN;
  END IF;
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO geoserver', current_database());
  EXECUTE 'GRANT USAGE ON SCHEMA public TO geoserver';
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'schema_version'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.schema_version TO geoserver';
  END IF;
  EXECUTE 'GRANT USAGE ON SCHEMA wms TO geoserver';
  EXECUTE 'GRANT SELECT ON ALL TABLES IN SCHEMA wms TO geoserver';
  EXECUTE 'GRANT SELECT ON ALL SEQUENCES IN SCHEMA wms TO geoserver';
  EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON TABLES TO geoserver';
  EXECUTE 'ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON SEQUENCES TO geoserver';
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'countries'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.countries TO geoserver';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'notes_open_view'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.notes_open_view TO geoserver';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'notes_closed_view'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.notes_closed_view TO geoserver';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'disputed_areas_view'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.disputed_areas_view TO geoserver';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'disputed_territories_wms'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.disputed_territories_wms TO geoserver';
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'disputed_territories_wms_view'
  ) THEN
    EXECUTE 'GRANT SELECT ON TABLE public.disputed_territories_wms_view TO geoserver';
  END IF;
  RAISE NOTICE 'Grants applied to geoserver';
END
$ggeo$;

-- Datastore role (read_role): name passed via psql -v (stored in temp row so substitution is outside dollar-quotes)
CREATE TEMP TABLE IF NOT EXISTS _wms_grant_read_role (role_name text PRIMARY KEY);
DELETE FROM _wms_grant_read_role;
INSERT INTO _wms_grant_read_role VALUES (:'read_role');

DO $gread$
DECLARE
  r name;
BEGIN
  SELECT role_name::name INTO STRICT r FROM _wms_grant_read_role;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
    RAISE EXCEPTION 'GeoServer read role "%" does not exist. Create it first (CREATE ROLE ... LOGIN), then re-run this script.', r;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms') THEN
    RAISE EXCEPTION 'Schema wms does not exist. Run sql/wms/prepareDatabase.sql before this script.';
  END IF;
  EXECUTE format('GRANT CONNECT ON DATABASE %I TO %I', current_database(), r);
  EXECUTE format('GRANT USAGE ON SCHEMA public TO %I', r);
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'schema_version'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.schema_version TO %I', r);
  END IF;
  EXECUTE format('GRANT USAGE ON SCHEMA wms TO %I', r);
  EXECUTE format('GRANT SELECT ON ALL TABLES IN SCHEMA wms TO %I', r);
  EXECUTE format('GRANT SELECT ON ALL SEQUENCES IN SCHEMA wms TO %I', r);
  EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON TABLES TO %I', r);
  EXECUTE format('ALTER DEFAULT PRIVILEGES IN SCHEMA wms GRANT SELECT ON SEQUENCES TO %I', r);
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'countries'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.countries TO %I', r);
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'notes_open_view'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.notes_open_view TO %I', r);
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'notes_closed_view'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.notes_closed_view TO %I', r);
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'disputed_areas_view'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.disputed_areas_view TO %I', r);
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema = 'public' AND table_name = 'disputed_territories_wms'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.disputed_territories_wms TO %I', r);
  END IF;
  IF EXISTS (
    SELECT 1 FROM information_schema.views
    WHERE table_schema = 'public' AND table_name = 'disputed_territories_wms_view'
  ) THEN
    EXECUTE format('GRANT SELECT ON TABLE public.disputed_territories_wms_view TO %I', r);
  END IF;
  RAISE NOTICE 'Grants applied to %', r;
END
$gread$;

DROP TABLE IF EXISTS _wms_grant_read_role;

\echo ''
\echo 'GeoServer DB permissions applied to read_role (and geoserver if present).'
