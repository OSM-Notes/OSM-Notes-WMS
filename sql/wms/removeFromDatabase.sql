-- Removes all tables related to the WMS layer.
--
-- Author: Andres Gomez (AngocA)
-- Version: 2025-11-30

-- Drop triggers first (in reverse order of creation)
DROP TRIGGER IF EXISTS update_notes ON notes;
DROP TRIGGER IF EXISTS insert_new_notes ON notes;

-- Drop functions
DROP FUNCTION IF EXISTS wms.update_notes();
DROP FUNCTION IF EXISTS wms.insert_new_notes();

-- Drop indexes
DROP INDEX IF EXISTS wms.notes_wms_geometry_idx;
DROP INDEX IF EXISTS wms.notes_closed;
DROP INDEX IF EXISTS wms.notes_open;

-- Drop views in public schema that depend on wms tables
-- These views are created in public schema for GeoServer compatibility
DROP VIEW IF EXISTS public.notes_open_view CASCADE;
DROP VIEW IF EXISTS public.notes_closed_view CASCADE;
DROP VIEW IF EXISTS public.disputed_areas_view CASCADE;

-- Drop materialized view for disputed and unclaimed areas
DROP MATERIALIZED VIEW IF EXISTS wms.disputed_and_unclaimed_areas CASCADE;
DROP MATERIALIZED VIEW IF EXISTS wms.disputed_and_unclaimed_areas_materialized CASCADE;

-- Drop table (should work now that dependent views are dropped)
DROP TABLE IF EXISTS wms.notes_wms CASCADE;

-- Drop schema (this will remove any remaining objects)
DROP SCHEMA IF EXISTS wms CASCADE;

-- Verify cleanup
DO $$
BEGIN
  IF EXISTS (SELECT 1 FROM information_schema.schemata WHERE schema_name = 'wms') THEN
    RAISE NOTICE 'WARNING: wms schema still exists after cleanup';
  ELSE
    RAISE NOTICE 'SUCCESS: WMS objects removed successfully';
  END IF;
END $$;
