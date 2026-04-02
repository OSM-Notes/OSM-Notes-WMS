-- Schema Verification Script for OSM-Notes-WMS
-- Verifies that the database schema matches the expected schema from OSM-Notes-Ingestion
--
-- Usage: psql -d notes -f sql/wms/verifySchema.sql
--
-- Author: Andres Gomez (AngocA)
-- Version: 2026-04-02
--
-- Note: Existence and column checks use pg_catalog (not information_schema).
-- information_schema.tables/columns only list objects visible to the current role
-- via privileges; a role without SELECT on public.notes may see no row there even
-- when the table exists — which falsely fails verification.

\echo '========================================'
\echo 'OSM-Notes-WMS Schema Verification'
\echo '========================================'
\echo ''

-- Check PostGIS extension
\echo '1. Checking PostGIS extension...'
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE EXCEPTION '❌ PostGIS extension is not installed. Please install PostGIS first.';
  ELSE
    RAISE NOTICE '✅ PostGIS extension is installed';
  END IF;
END $$;

SELECT PostGIS_Version() AS postgis_version;
\echo ''

-- Check notes table exists (pg_catalog: not privilege-filtered like information_schema)
\echo '2. Checking notes table...'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'notes'
      AND c.relkind IN ('r', 'p')
  ) THEN
    RAISE EXCEPTION '❌ Table "notes" does not exist in public schema.';
  ELSE
    RAISE NOTICE '✅ Table "notes" exists';
  END IF;
END $$;
\echo ''

-- Check required columns in notes table
\echo '3. Checking required columns in notes table...'
SELECT 
  a.attname AS column_name,
  pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
  CASE WHEN a.attnotnull THEN 'NO' ELSE 'YES' END AS is_nullable,
  CASE 
    WHEN a.attname IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude') THEN '✅ Required'
    WHEN a.attname = 'id_country' THEN '⚠️  Optional (recommended)'
    ELSE 'ℹ️  Other'
  END AS status
FROM pg_catalog.pg_attribute a
JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'notes'
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND a.attname IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude', 'id_country')
ORDER BY 
  CASE 
    WHEN a.attname IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude') THEN 1
    WHEN a.attname = 'id_country' THEN 2
    ELSE 3
  END,
  a.attname;

-- Verify all required columns exist
-- Support both note_id (standard) and id (legacy) column names
DO $$
DECLARE
  missing_columns TEXT[];
  has_note_id BOOLEAN;
  has_id BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'notes'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname = 'note_id'
  ) INTO has_note_id;
  
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'notes'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname = 'id'
  ) INTO has_id;
  
  -- Require either note_id or id
  IF NOT has_note_id AND NOT has_id THEN
    RAISE EXCEPTION '❌ Missing required column: note_id or id';
  END IF;
  
  -- Check for other required columns
  SELECT ARRAY_AGG(required_col)
  INTO missing_columns
  FROM (
    SELECT unnest(ARRAY['created_at', 'closed_at', 'longitude', 'latitude']) AS required_col
  ) req
  WHERE NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_attribute a
    JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'notes'
      AND a.attnum > 0
      AND NOT a.attisdropped
      AND a.attname = req.required_col
  );

  IF array_length(missing_columns, 1) > 0 THEN
    RAISE EXCEPTION '❌ Missing required columns: %', array_to_string(missing_columns, ', ');
  ELSE
    RAISE NOTICE '✅ All required columns exist';
  END IF;
END $$;
\echo ''

-- Check countries table
\echo '4. Checking countries table...'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'countries'
      AND c.relkind IN ('r', 'p')
  ) THEN
    RAISE WARNING '⚠️  Table "countries" does not exist. This is required for disputed areas view.';
  ELSE
    RAISE NOTICE '✅ Table "countries" exists';
  END IF;
END $$;
\echo ''

-- Check required columns in countries table
\echo '4.1. Checking required columns in countries table...'
SELECT 
  a.attname AS column_name,
  pg_catalog.format_type(a.atttypid, a.atttypmod) AS data_type,
  CASE WHEN a.attnotnull THEN 'NO' ELSE 'YES' END AS is_nullable,
  CASE 
    WHEN a.attname IN ('country_id', 'geom') THEN '✅ Required'
    WHEN a.attname IN ('country_name', 'country_name_en') THEN '✅ Required'
    ELSE 'ℹ️  Other'
  END AS status
FROM pg_catalog.pg_attribute a
JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public'
  AND c.relname = 'countries'
  AND a.attnum > 0
  AND NOT a.attisdropped
  AND a.attname IN ('country_id', 'country_name', 'country_name_en', 'geom')
ORDER BY 
  CASE 
    WHEN a.attname IN ('country_id', 'geom') THEN 1
    WHEN a.attname IN ('country_name', 'country_name_en') THEN 2
    ELSE 3
  END,
  a.attname;

-- Verify all required columns exist in countries table
DO $$
DECLARE
  missing_columns TEXT[];
BEGIN
  -- Check if countries table exists first
  IF EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public'
      AND c.relname = 'countries'
      AND c.relkind IN ('r', 'p')
  ) THEN
    -- Verify required columns: country_id, country_name_en (or country_name), geom
    SELECT ARRAY_AGG(required_col)
    INTO missing_columns
    FROM (
      SELECT unnest(ARRAY['country_id', 'geom']) AS required_col
    ) req
    WHERE NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_attribute a
      JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'countries'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND a.attname = req.required_col
    );

    -- Check for country_name_en, country_name, or name (at least one should exist)
    IF NOT EXISTS (
      SELECT 1
      FROM pg_catalog.pg_attribute a
      JOIN pg_catalog.pg_class c ON c.oid = a.attrelid
      JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
      WHERE n.nspname = 'public'
        AND c.relname = 'countries'
        AND a.attnum > 0
        AND NOT a.attisdropped
        AND a.attname IN ('country_name_en', 'country_name', 'name')
    ) THEN
      IF missing_columns IS NULL THEN
        missing_columns := ARRAY['country_name_en'];
      ELSE
        missing_columns := array_append(missing_columns, 'country_name_en');
      END IF;
    END IF;

    IF array_length(missing_columns, 1) > 0 THEN
      RAISE EXCEPTION '❌ Missing required columns in countries table: %', array_to_string(missing_columns, ', ');
    ELSE
      RAISE NOTICE '✅ All required columns exist in countries table';
    END IF;
  END IF;
END $$;
\echo ''

-- Check data exists (use EXECUTE so missing table countries does not abort whole script)
\echo '5. Checking data availability...'
DO $$
DECLARE
  notes_count BIGINT := 0;
  countries_count BIGINT := 0;
  notes_tbl BOOLEAN;
  countries_tbl BOOLEAN;
BEGIN
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'notes' AND c.relkind IN ('r', 'p')
  ) INTO notes_tbl;
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'countries' AND c.relkind IN ('r', 'p')
  ) INTO countries_tbl;

  IF notes_tbl THEN
    BEGIN
      EXECUTE 'SELECT COUNT(*) FROM public.notes' INTO notes_count;
    EXCEPTION
      WHEN insufficient_privilege THEN
        RAISE WARNING '⚠️  Cannot count public.notes (insufficient privileges). Grant SELECT ON public.notes to the verifying role.';
        notes_count := -1;
    END;
  END IF;

  IF countries_tbl THEN
    BEGIN
      EXECUTE 'SELECT COUNT(*) FROM public.countries' INTO countries_count;
    EXCEPTION
      WHEN insufficient_privilege THEN
        RAISE WARNING '⚠️  Cannot count public.countries (insufficient privileges).';
        countries_count := -1;
    END;
  END IF;

  IF notes_count = 0 THEN
    RAISE WARNING '⚠️  No notes found in database. Ensure OSM-Notes-Ingestion has populated the database.';
  ELSIF notes_count > 0 THEN
    RAISE NOTICE '✅ Found % notes in database', notes_count;
  END IF;

  IF countries_tbl AND countries_count = 0 THEN
    RAISE WARNING '⚠️  No countries found in database. Run country assignment process if needed.';
  ELSIF countries_count > 0 THEN
    RAISE NOTICE '✅ Found % countries in database', countries_count;
  END IF;
END $$;

-- Row counts (PL/pgSQL: plain SQL cannot skip parsing of FROM public.countries when the table is missing)
CREATE OR REPLACE FUNCTION pg_temp._wms_verify_row_counts()
RETURNS TABLE (notes_count bigint, countries_count bigint, notes_with_coordinates bigint)
LANGUAGE plpgsql AS $$
DECLARE
  has_countries BOOLEAN;
BEGIN
  EXECUTE 'SELECT COUNT(*)::bigint FROM public.notes' INTO notes_count;
  EXECUTE 'SELECT COUNT(*)::bigint FROM public.notes WHERE longitude IS NOT NULL AND latitude IS NOT NULL' INTO notes_with_coordinates;
  SELECT EXISTS (
    SELECT 1
    FROM pg_catalog.pg_class c
    JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND c.relname = 'countries' AND c.relkind IN ('r', 'p')
  ) INTO has_countries;
  IF has_countries THEN
    EXECUTE 'SELECT COUNT(*)::bigint FROM public.countries' INTO countries_count;
  ELSE
    countries_count := NULL;
  END IF;
  RETURN NEXT;
END $$;

SELECT * FROM pg_temp._wms_verify_row_counts();
\echo ''

-- Summary
\echo '========================================'
\echo 'Verification Summary'
\echo '========================================'
\echo 'If all checks passed (✅), your database schema is compatible with OSM-Notes-WMS.'
\echo 'If any checks failed (❌), please review the errors above and ensure your'
\echo 'database schema matches the expected schema from OSM-Notes-Ingestion.'
\echo ''


