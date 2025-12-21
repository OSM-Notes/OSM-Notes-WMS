-- Schema Verification Script for OSM-Notes-WMS
-- Verifies that the database schema matches the expected schema from OSM-Notes-Ingestion
--
-- Usage: psql -d notes -f sql/wms/verifySchema.sql
--
-- Author: Andres Gomez (AngocA)
-- Version: 2025-12-08

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

-- Check notes table exists
\echo '2. Checking notes table...'
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'notes'
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
  column_name, 
  data_type,
  is_nullable,
  CASE 
    WHEN column_name IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude') THEN '✅ Required'
    WHEN column_name = 'id_country' THEN '⚠️  Optional (recommended)'
    ELSE 'ℹ️  Other'
  END AS status
FROM information_schema.columns 
WHERE table_schema = 'public'
  AND table_name = 'notes' 
  AND column_name IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude', 'id_country')
ORDER BY 
  CASE 
    WHEN column_name IN ('note_id', 'created_at', 'closed_at', 'longitude', 'latitude') THEN 1
    WHEN column_name = 'id_country' THEN 2
    ELSE 3
  END,
  column_name;

-- Verify all required columns exist
DO $$
DECLARE
  missing_columns TEXT[];
BEGIN
  SELECT ARRAY_AGG(required_col)
  INTO missing_columns
  FROM (
    SELECT unnest(ARRAY['note_id', 'created_at', 'closed_at', 'longitude', 'latitude']) AS required_col
  ) req
  WHERE NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
      AND table_name = 'notes' 
      AND column_name = req.required_col
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
    SELECT 1 FROM information_schema.tables 
    WHERE table_schema = 'public' AND table_name = 'countries'
  ) THEN
    RAISE WARNING '⚠️  Table "countries" does not exist. This is required for disputed areas view.';
  ELSE
    RAISE NOTICE '✅ Table "countries" exists';
  END IF;
END $$;
\echo ''

-- Check data exists
\echo '5. Checking data availability...'
DO $$
DECLARE
  notes_count INTEGER;
  countries_count INTEGER;
BEGIN
  SELECT COUNT(*) INTO notes_count FROM notes;
  SELECT COUNT(*) INTO countries_count FROM countries;
  
  IF notes_count = 0 THEN
    RAISE WARNING '⚠️  No notes found in database. Ensure OSM-Notes-Ingestion has populated the database.';
  ELSE
    RAISE NOTICE '✅ Found % notes in database', notes_count;
  END IF;
  
  IF countries_count = 0 THEN
    RAISE WARNING '⚠️  No countries found in database. Run country assignment process if needed.';
  ELSE
    RAISE NOTICE '✅ Found % countries in database', countries_count;
  END IF;
END $$;

SELECT 
  (SELECT COUNT(*) FROM notes) AS notes_count,
  (SELECT COUNT(*) FROM countries) AS countries_count,
  (SELECT COUNT(*) FROM notes WHERE longitude IS NOT NULL AND latitude IS NOT NULL) AS notes_with_coordinates;
\echo ''

-- Summary
\echo '========================================'
\echo 'Verification Summary'
\echo '========================================'
\echo 'If all checks passed (✅), your database schema is compatible with OSM-Notes-WMS.'
\echo 'If any checks failed (❌), please review the errors above and ensure your'
\echo 'database schema matches the expected schema from OSM-Notes-Ingestion.'
\echo ''


