-- Installs the method to synchronize notes data with the tables used for WMS.
-- Also creates the view for disputed and unclaimed areas.
--
-- This script assumes that all database objects have been created, including
-- the countries table (i.e., processAPI/processPlanet have been executed).
--
-- This script requires the notes table schema as defined by OSM-Notes-Ingestion:
--   - note_id, created_at, closed_at, longitude, latitude, id_country
--
-- Author: Andres Gomez (AngocA)
-- Version: 2025-12-08

-- Check if PostGIS extension is available
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_extension WHERE extname = 'postgis') THEN
    RAISE EXCEPTION 'PostGIS extension is required but not installed. Please install PostGIS first.';
  END IF;
END $$;

-- Check if required columns exist in notes table
-- The notes table schema must match the one defined by OSM-Notes-Ingestion
-- Support both 'note_id' (standard) and 'id' (legacy) column names
DO $$
DECLARE
  has_note_id BOOLEAN;
  has_id BOOLEAN;
BEGIN
  -- Check for note_id or id column
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'note_id'
  ) INTO has_note_id;

  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'id'
  ) INTO has_id;

  -- Require either note_id or id
  IF NOT has_note_id AND NOT has_id THEN
    RAISE EXCEPTION 'Required column (note_id or id) not found in notes table. The notes table schema must match the one defined by OSM-Notes-Ingestion.';
  END IF;

  -- Check for other required columns
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes'
    AND column_name IN ('created_at', 'closed_at', 'longitude', 'latitude')
  ) THEN
    RAISE EXCEPTION 'Required columns (created_at, closed_at, longitude, latitude) not found in notes table. The notes table schema must match the one defined by OSM-Notes-Ingestion.';
  END IF;

  -- Check if id_country exists (optional, but recommended for country-based styling)
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes'
    AND column_name = 'id_country'
  ) THEN
    RAISE WARNING 'Column id_country not found in notes table. Country-based styling will not work. Consider running country assignment process.';
  END IF;
END $$;


-- Creates an independent schema for all objects related to WMS.
CREATE SCHEMA IF NOT EXISTS wms;
COMMENT ON SCHEMA wms IS 'Objects to publish the WMS layer';

-- Creates another table with only the necessary columns for WMS.
-- Use a more efficient approach with WHERE clause to avoid processing all records
-- Drop table if it exists to ensure clean creation
DROP TABLE IF EXISTS wms.notes_wms CASCADE;

-- Determine which ID column to use (note_id or id) and if id_country exists
DO $$
DECLARE
  use_note_id BOOLEAN;
  has_id_country BOOLEAN;
  sql_text TEXT;
  table_created BOOLEAN;
  notes_count INTEGER;
BEGIN
  -- Check if note_id column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'note_id'
  ) INTO use_note_id;

  -- Check if id_country column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'notes' AND column_name = 'id_country'
  ) INTO has_id_country;

  -- Check how many notes have valid coordinates
  IF use_note_id THEN
    SELECT COUNT(*) INTO notes_count
    FROM notes
    WHERE longitude IS NOT NULL AND latitude IS NOT NULL;
  ELSE
    SELECT COUNT(*) INTO notes_count
    FROM notes
    WHERE longitude IS NOT NULL AND latitude IS NOT NULL;
  END IF;

  RAISE NOTICE 'Creating wms.notes_wms table with % notes that have valid coordinates', notes_count;

  -- Build SQL dynamically based on which columns exist
  IF use_note_id THEN
    IF has_id_country THEN
      sql_text := '
        CREATE TABLE wms.notes_wms AS
         SELECT /* Notes-WMS */
          note_id,
          extract(year from created_at) AS year_created_at,
          extract (year from closed_at) AS year_closed_at,
          id_country,
          CASE
            WHEN id_country IS NOT NULL AND id_country > 0 THEN id_country % 12
            ELSE NULL
          END AS country_shape_mod,
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) AS geometry
         FROM notes
         WHERE longitude IS NOT NULL AND latitude IS NOT NULL
      ';
    ELSE
      sql_text := '
        CREATE TABLE wms.notes_wms AS
         SELECT /* Notes-WMS */
          note_id,
          extract(year from created_at) AS year_created_at,
          extract (year from closed_at) AS year_closed_at,
          NULL::INTEGER AS id_country,
          NULL::INTEGER AS country_shape_mod,
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) AS geometry
         FROM notes
         WHERE longitude IS NOT NULL AND latitude IS NOT NULL
      ';
    END IF;
  ELSE
    IF has_id_country THEN
      sql_text := '
        CREATE TABLE wms.notes_wms AS
         SELECT /* Notes-WMS */
          id AS note_id,
          extract(year from created_at) AS year_created_at,
          extract (year from closed_at) AS year_closed_at,
          id_country,
          CASE
            WHEN id_country IS NOT NULL AND id_country > 0 THEN id_country % 12
            ELSE NULL
          END AS country_shape_mod,
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) AS geometry
         FROM notes
         WHERE longitude IS NOT NULL AND latitude IS NOT NULL
      ';
    ELSE
      sql_text := '
        CREATE TABLE wms.notes_wms AS
         SELECT /* Notes-WMS */
          id AS note_id,
          extract(year from created_at) AS year_created_at,
          extract (year from closed_at) AS year_closed_at,
          NULL::INTEGER AS id_country,
          NULL::INTEGER AS country_shape_mod,
          ST_SetSRID(ST_MakePoint(longitude, latitude), 4326) AS geometry
         FROM notes
         WHERE longitude IS NOT NULL AND latitude IS NOT NULL
      ';
    END IF;
  END IF;

  -- Execute the CREATE TABLE statement
  RAISE NOTICE 'Executing CREATE TABLE statement...';
  BEGIN
    EXECUTE sql_text;
    RAISE NOTICE 'CREATE TABLE statement executed successfully';
  EXCEPTION
    WHEN OTHERS THEN
      RAISE EXCEPTION 'Failed to create wms.notes_wms table: %', SQLERRM;
  END;

  -- Verify that the table was created successfully
  -- Use pg_tables for more reliable checking
  SELECT EXISTS (
    SELECT 1 FROM pg_tables
    WHERE schemaname = 'wms' AND tablename = 'notes_wms'
  ) INTO table_created;

  IF NOT table_created THEN
    -- Also check information_schema as fallback
    SELECT EXISTS (
      SELECT 1 FROM information_schema.tables
      WHERE table_schema = 'wms' AND table_name = 'notes_wms'
    ) INTO table_created;

    IF NOT table_created THEN
      RAISE EXCEPTION 'Table wms.notes_wms was not created successfully. Check for errors in the CREATE TABLE statement.';
    END IF;
  END IF;

  RAISE NOTICE 'Table wms.notes_wms verified successfully';
END $$;
COMMENT ON TABLE wms.notes_wms IS
  'Locations of the notes and its opening and closing year';
COMMENT ON COLUMN wms.notes_wms.note_id IS 'OSM note id';
COMMENT ON COLUMN wms.notes_wms.year_created_at IS
  'Year when the note was created';
COMMENT ON COLUMN wms.notes_wms.year_closed_at IS
  'Year when the note was closed';
COMMENT ON COLUMN wms.notes_wms.id_country IS
  'Country id where the note is located (NULL for unclaimed/disputed areas)';
COMMENT ON COLUMN wms.notes_wms.country_shape_mod IS
  'Modulo 12 of id_country for shape assignment (0-11, NULL if no country)';
COMMENT ON COLUMN wms.notes_wms.geometry IS 'Location of the note';

-- Index for open notes. The most important.
CREATE INDEX IF NOT EXISTS notes_open ON wms.notes_wms (year_created_at);
COMMENT ON INDEX wms.notes_open IS 'Queries based on creation year';

-- Index for closed notes.
CREATE INDEX IF NOT EXISTS notes_closed ON wms.notes_wms (year_closed_at);
COMMENT ON INDEX wms.notes_closed IS 'Queries based on closed year';

-- Index for country-based queries
CREATE INDEX IF NOT EXISTS notes_wms_country_idx
  ON wms.notes_wms (id_country)
  WHERE id_country IS NOT NULL;
COMMENT ON INDEX wms.notes_wms_country_idx IS
  'Index for country-based queries';

-- Index for shape-based queries (for SLD filtering)
CREATE INDEX IF NOT EXISTS notes_wms_shape_mod_idx
  ON wms.notes_wms (country_shape_mod)
  WHERE country_shape_mod IS NOT NULL;
COMMENT ON INDEX wms.notes_wms_shape_mod_idx IS
  'Index for shape-based queries (country_shape_mod)';

-- Add spatial index for better performance
CREATE INDEX IF NOT EXISTS notes_wms_geometry_idx ON wms.notes_wms USING GIST (geometry);
COMMENT ON INDEX wms.notes_wms_geometry_idx IS 'Spatial index for geometry queries';

-- Function for trigger when inserting new notes.
-- Supports both note_id (standard) and id (legacy) column names
CREATE OR REPLACE FUNCTION wms.insert_new_notes()
  RETURNS TRIGGER AS
 $$
 DECLARE
  note_id_value INTEGER;
 BEGIN
  -- Only insert if coordinates are valid
  IF NEW.longitude IS NOT NULL AND NEW.latitude IS NOT NULL THEN
    -- Get note_id value (support both note_id and id columns)
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'note_id') THEN
      note_id_value := NEW.note_id;
    ELSE
      note_id_value := NEW.id;
    END IF;

    INSERT INTO wms.notes_wms
     VALUES
     (
      note_id_value,
      EXTRACT(YEAR FROM NEW.created_at),
      EXTRACT(YEAR FROM NEW.closed_at),
      COALESCE(NEW.id_country, NULL),
      CASE
        WHEN NEW.id_country IS NOT NULL AND NEW.id_country > 0 THEN NEW.id_country % 6
        ELSE NULL
      END,
      ST_SetSRID(ST_MakePoint(NEW.longitude, NEW.latitude), 4326)
     )
    ;
  END IF;
  RETURN NEW;
 END;
 $$ LANGUAGE plpgsql
 ;
COMMENT ON FUNCTION wms.insert_new_notes IS
  'Insert new notes for the WMS including country information';

-- Function for trigger when updating notes. This applies for 2 cases:
-- * From open to close (solving).
-- * From close to open (reopening).
-- * When country assignment changes.
-- It is not used when adding a comment.
-- Supports both note_id (standard) and id (legacy) column names
CREATE OR REPLACE FUNCTION wms.update_notes()
  RETURNS TRIGGER AS
 $$
 DECLARE
  note_id_value INTEGER;
 BEGIN
  -- Get note_id value (support both note_id and id columns)
  IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'notes' AND column_name = 'note_id') THEN
    note_id_value := NEW.note_id;
  ELSE
    note_id_value := NEW.id;
  END IF;

  UPDATE wms.notes_wms
   SET
     year_closed_at = EXTRACT(YEAR FROM NEW.closed_at),
     id_country = COALESCE(NEW.id_country, NULL),
     country_shape_mod = CASE
       WHEN NEW.id_country IS NOT NULL AND NEW.id_country > 0 THEN NEW.id_country % 6
       ELSE NULL
     END
   WHERE note_id = note_id_value
  ;
  RETURN NEW;
 END;
 $$ LANGUAGE plpgsql
 ;
COMMENT ON FUNCTION wms.update_notes IS
  'Updates the closing year, country, and shape modulo of a note when changed';

-- Trigger for new notes.
CREATE OR REPLACE TRIGGER insert_new_notes
  AFTER INSERT ON notes
  FOR EACH ROW
  EXECUTE FUNCTION wms.insert_new_notes()
;
COMMENT ON TRIGGER insert_new_notes ON notes IS
  'Replicates the insertion of a note in the WMS';

-- Trigger for updated notes.
CREATE OR REPLACE TRIGGER update_notes
  AFTER UPDATE ON notes
  FOR EACH ROW
  WHEN (OLD.closed_at IS DISTINCT FROM NEW.closed_at)
  EXECUTE FUNCTION wms.update_notes()
;
COMMENT ON TRIGGER update_notes ON notes IS
  'Replicates the update of a note in the WMS when closed';

-- =============================================================================
-- Create materialized view for disputed and unclaimed areas
-- =============================================================================
-- This view identifies areas where countries overlap (disputed) or gaps
-- between countries (unclaimed).
-- This view is created assuming that the countries table already exists
-- (WMS installation happens after processAPI/processPlanet execution).
-- This MUST be created before the disputed_areas_view that depends on it.

-- Check if countries table exists and has required columns
DO $$
DECLARE
  has_geom BOOLEAN;
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_name = 'countries'
  ) THEN
    RAISE EXCEPTION 'Table countries does not exist. Please run processPlanet or processAPI first to create country data.';
  END IF;

  -- Check if geom column exists
  SELECT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_name = 'countries' AND column_name = 'geom'
  ) INTO has_geom;

  IF NOT has_geom THEN
    RAISE WARNING 'Column geom not found in countries table. Disputed areas view will not be created. Please run processPlanet or processAPI to populate countries with geometry data.';
  END IF;
END $$;

-- Create materialized view for disputed and unclaimed areas
-- This view is materialized because the query is computationally expensive
-- (ST_Union over all countries, ST_Difference operations).
-- The view should be refreshed after countries are updated (monthly).
-- Use: REFRESH MATERIALIZED VIEW CONCURRENTLY wms.disputed_and_unclaimed_areas;
-- Or run: sql/wms/refreshDisputedAreasView.sql
-- Drop existing view if it exists
DROP MATERIALIZED VIEW IF EXISTS wms.disputed_and_unclaimed_areas CASCADE;

-- Create materialized view for disputed and unclaimed areas
-- Note: This requires the countries table to have a geom column
CREATE MATERIALIZED VIEW wms.disputed_and_unclaimed_areas AS
WITH
  -- Step 1: Filter valid countries (fix SRID and geometry type issues)
  -- Some countries have SRID 0 or invalid geometry types (GeometryCollection)
  -- Filter and fix these before processing
  valid_countries AS (
    SELECT
      c.country_id,
      -- Use country_name_en (preferred) or fallback to country_name (local language)
      -- Based on actual schema: country_name_en VARCHAR(100), country_name VARCHAR(100) NOT NULL
      COALESCE(c.country_name_en, c.country_name) AS country_name_en,
      CASE
        WHEN ST_SRID(c.geom) = 0 OR ST_SRID(c.geom) IS NULL THEN
          ST_SetSRID(c.geom, 4326)
        ELSE
          c.geom
      END AS geom
    FROM
      countries c
    WHERE
      ST_GeometryType(c.geom) IN ('ST_Polygon', 'ST_MultiPolygon')
      AND c.geom IS NOT NULL
      AND NOT ST_IsEmpty(c.geom)
  ),
  -- Step 2: Find all overlapping areas (disputed zones)
  -- This finds intersections where 2 or more countries overlap
  -- Using a self-join to find pairs of overlapping countries
  -- Exclude maritime zones (those with parentheses in name) from disputed calculation
  -- as they can legitimately overlap with countries and each other (EEZ zones)
  -- Optimized: Calculate ST_Intersection only once
  country_pairs AS (
    SELECT
      c1.country_id AS country_id_1,
      c1.country_name_en AS country_name_1,
      c2.country_id AS country_id_2,
      c2.country_name_en AS country_name_2,
      ST_Intersection(c1.geom, c2.geom) AS intersection_geom
    FROM
      valid_countries c1
      INNER JOIN valid_countries c2 ON (
        c1.country_id < c2.country_id
        AND ST_Intersects(c1.geom, c2.geom)
        AND ST_Overlaps(c1.geom, c2.geom)
        -- Exclude maritime zones from disputed calculation
        -- Maritime zones can have parentheses in their name (e.g., "Colombia (200nm EEZ)")
        -- or contain keywords like "EEZ", "Exclusive Economic Zone", "Economic Zone", "Contiguous Zone", "Territorial Waters", "Intervention zone"
        AND c1.country_name_en NOT LIKE '%(%)%'
        AND c2.country_name_en NOT LIKE '%(%)%'
        AND c1.country_name_en NOT ILIKE '%EEZ%'
        AND c2.country_name_en NOT ILIKE '%EEZ%'
        AND c1.country_name_en NOT ILIKE '%Exclusive Economic Zone%'
        AND c2.country_name_en NOT ILIKE '%Exclusive Economic Zone%'
        AND c1.country_name_en NOT ILIKE '%Economic Zone%'
        AND c2.country_name_en NOT ILIKE '%Economic Zone%'
        AND c1.country_name_en NOT ILIKE '%Contiguous Zone%'
        AND c2.country_name_en NOT ILIKE '%Contiguous Zone%'
        AND c1.country_name_en NOT ILIKE '%Territorial Waters%'
        AND c2.country_name_en NOT ILIKE '%Territorial Waters%'
        AND c1.country_name_en NOT ILIKE '%baseline%'
        AND c2.country_name_en NOT ILIKE '%baseline%'
        AND c1.country_name_en NOT ILIKE '%Intervention zone%'
        AND c2.country_name_en NOT ILIKE '%Intervention zone%'
        AND c1.country_name_en NOT ILIKE '%Special Area%'
        AND c2.country_name_en NOT ILIKE '%Special Area%'
        AND c1.country_name_en NOT ILIKE '%Fishing territory%'
        AND c2.country_name_en NOT ILIKE '%Fishing territory%'
      )
  ),
  -- Step 3: Extract individual polygons from intersections
  -- Optimized: Filter using the already calculated intersection_geom
  disputed_polygons_raw AS (
    SELECT
      intersection_geom AS geometry,
      ARRAY[country_id_1, country_id_2] AS country_ids,
      ARRAY[country_name_1, country_name_2] AS country_names
    FROM
      country_pairs
    WHERE
      intersection_geom IS NOT NULL
      AND NOT ST_IsEmpty(intersection_geom)
      AND ST_GeometryType(intersection_geom) IN ('ST_Polygon', 'ST_MultiPolygon')
  ),
  -- Step 4: Dump MultiPolygon to individual polygons
  disputed_polygons_dumped AS (
    SELECT
      (ST_Dump(dp.geometry)).geom AS geometry,
      dp.country_ids,
      dp.country_names
    FROM
      disputed_polygons_raw dp
  ),
  -- Step 5: Filter and format disputed polygons
  disputed_polygons AS (
    SELECT
      geometry,
      country_ids,
      country_names,
      'disputed' AS area_type
    FROM
      disputed_polygons_dumped
    WHERE
      ST_GeometryType(geometry) = 'ST_Polygon'
      AND ST_Area(geometry) > 0.0001
  ),
  -- Step 6: Calculate unclaimed areas (gaps between countries)
  -- Union all country geometries to get total coverage
  -- Exclude maritime zones (those with parentheses in name) for unclaimed
  -- calculation, as they are intentionally not claimed
  -- Use valid_countries CTE to ensure only valid geometries
  all_countries_union AS (
    SELECT
      ST_Union(
        CASE
          WHEN ST_SRID(c.geom) = 0 OR ST_SRID(c.geom) IS NULL THEN
            ST_SetSRID(c.geom, 4326)
          ELSE
            c.geom
        END
      ) AS geom
    FROM
      valid_countries c
    WHERE
      -- Exclude maritime zones (those with parentheses in name or maritime keywords)
      -- Use country_name_en from valid_countries CTE which handles column name differences
      c.country_name_en NOT LIKE '%(%)%'
      AND c.country_name_en NOT ILIKE '%EEZ%'
      AND c.country_name_en NOT ILIKE '%Exclusive Economic Zone%'
      AND c.country_name_en NOT ILIKE '%Economic Zone%'
      AND c.country_name_en NOT ILIKE '%Contiguous Zone%'
      AND c.country_name_en NOT ILIKE '%Territorial Waters%'
      AND c.country_name_en NOT ILIKE '%baseline%'
      AND c.country_name_en NOT ILIKE '%Intervention zone%'
      AND c.country_name_en NOT ILIKE '%Special Area%'
      AND c.country_name_en NOT ILIKE '%Fishing territory%'
      AND ST_GeometryType(c.geom) IN ('ST_Polygon', 'ST_MultiPolygon')
      AND c.geom IS NOT NULL
      AND NOT ST_IsEmpty(c.geom)
  ),
  -- Calculate world bounds (approximate: -180 to 180 longitude, -90 to 90 latitude)
  world_bounds AS (
    SELECT
      ST_MakeEnvelope(-180, -90, 180, 90, 4326) AS geom
  ),
  -- Calculate difference between world bounds and all countries
  unclaimed_difference_raw AS (
    SELECT
      ST_Difference(
        wb.geom,
        COALESCE(acu.geom, ST_GeomFromText('POLYGON EMPTY', 4326))
      ) AS geom
    FROM
      world_bounds wb
      CROSS JOIN all_countries_union acu
  ),
  unclaimed_difference AS (
    SELECT
      geom
    FROM
      unclaimed_difference_raw
    WHERE
      geom IS NOT NULL
      AND NOT ST_IsEmpty(geom)
  ),
  unclaimed_polygons_dumped AS (
    SELECT
      (ST_Dump(ud.geom)).geom AS geometry
    FROM
      unclaimed_difference ud
  ),
  unclaimed_polygons AS (
    SELECT
      geometry,
      ARRAY[]::INTEGER[] AS country_ids,
      ARRAY[]::VARCHAR[] AS country_names,
      'unclaimed' AS area_type
    FROM
      unclaimed_polygons_dumped
    WHERE
      ST_GeometryType(geometry) = 'ST_Polygon'
      AND ST_Area(geometry) > 0.0001
  ),
  -- Step 7: Combine disputed and unclaimed areas
  all_areas AS (
    SELECT
      geometry,
      country_ids,
      country_names,
      area_type
    FROM
      disputed_polygons
    UNION ALL
    SELECT
      geometry,
      country_ids,
      country_names,
      area_type
    FROM
      unclaimed_polygons
  )
SELECT
  ROW_NUMBER() OVER (ORDER BY area_type, geometry) AS id,
  geometry,
  area_type,
  country_ids,
  country_names,
  -- Helper field for SLD styling (simplified: same as area_type)
  area_type AS zone_type
FROM
  all_areas
WHERE
  geometry IS NOT NULL
  AND NOT ST_IsEmpty(geometry)
  AND ST_Area(geometry) > 0.0001  -- Filter out very small areas (increased threshold)
;

-- Create unique index for CONCURRENT refresh (required for REFRESH MATERIALIZED VIEW CONCURRENTLY)
CREATE UNIQUE INDEX IF NOT EXISTS idx_disputed_unclaimed_areas_id
  ON wms.disputed_and_unclaimed_areas (id);

-- Create index on materialized view for better query performance
CREATE INDEX IF NOT EXISTS idx_disputed_unclaimed_areas_zone_type
  ON wms.disputed_and_unclaimed_areas (zone_type);
CREATE INDEX IF NOT EXISTS idx_disputed_unclaimed_areas_geometry
  ON wms.disputed_and_unclaimed_areas USING GIST (geometry);

COMMENT ON MATERIALIZED VIEW wms.disputed_and_unclaimed_areas IS
  'Areas that are either disputed (overlapping countries) or unclaimed (gaps between countries). Maritime zones (those with parentheses in name) are excluded from both calculations as they can legitimately overlap with countries and each other. This is a materialized view that should be refreshed after countries are updated (monthly).';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.id IS
  'Unique identifier for each area';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.geometry IS
  'Polygon geometry of the disputed or unclaimed area';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.area_type IS
  'Type of area: disputed (overlapping countries) or unclaimed (gaps)';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.country_ids IS
  'Array of country IDs involved in the dispute (empty for unclaimed areas)';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.country_names IS
  'Array of country names involved in the dispute (empty for unclaimed areas)';
COMMENT ON COLUMN wms.disputed_and_unclaimed_areas.zone_type IS
  'Helper field for SLD styling: disputed or unclaimed';

-- =============================================================================
-- Create views for open and closed notes (for GeoServer layers)
-- =============================================================================
-- These views filter the notes_wms table to separate open and closed notes
-- for use in GeoServer feature types
-- Note: Views are created in 'public' schema to simplify GeoServer datastore
--       configuration (single schema for all layers)

CREATE OR REPLACE VIEW public.notes_open_view AS
SELECT
  note_id,
  year_created_at,
  year_closed_at,
  -- Calculate age dynamically (years since creation) as INTEGER for SLD filtering
  FLOOR(EXTRACT(YEAR FROM CURRENT_DATE) - year_created_at)::INTEGER AS age_years,
  -- Country information for country-based styling
  id_country,
  country_shape_mod,
  geometry
FROM wms.notes_wms
WHERE year_closed_at IS NULL
  AND geometry IS NOT NULL;

COMMENT ON VIEW public.notes_open_view IS
  'View of open notes (not closed) for WMS layer display';
COMMENT ON COLUMN public.notes_open_view.age_years IS
  'Age of the note in years (calculated dynamically from current year)';
COMMENT ON COLUMN public.notes_open_view.id_country IS
  'Country id where the note is located (NULL for unclaimed/disputed areas)';
COMMENT ON COLUMN public.notes_open_view.country_shape_mod IS
  'Modulo 12 of id_country for shape assignment (0-11, NULL if no country)';

CREATE OR REPLACE VIEW public.notes_closed_view AS
SELECT
  note_id,
  year_created_at,
  year_closed_at,
  -- Calculate age dynamically (years since closure) as INTEGER for SLD filtering
  FLOOR(EXTRACT(YEAR FROM CURRENT_DATE) - year_closed_at)::INTEGER AS years_since_closed,
  -- Country information for country-based styling
  id_country,
  country_shape_mod,
  geometry
FROM wms.notes_wms
WHERE year_closed_at IS NOT NULL
  AND geometry IS NOT NULL;

COMMENT ON VIEW public.notes_closed_view IS
  'View of closed notes for WMS layer display';
COMMENT ON COLUMN public.notes_closed_view.years_since_closed IS
  'Years since the note was closed (calculated dynamically from current year)';
COMMENT ON COLUMN public.notes_closed_view.id_country IS
  'Country id where the note is located (NULL for unclaimed/disputed areas)';
COMMENT ON COLUMN public.notes_closed_view.country_shape_mod IS
  'Modulo 12 of id_country for shape assignment (0-11, NULL if no country)';

-- Create view for disputed and unclaimed areas (for GeoServer layer)
-- Note: View is created in 'public' schema to simplify GeoServer datastore
--       configuration (single schema for all layers)
CREATE OR REPLACE VIEW public.disputed_areas_view AS
SELECT
  id,
  zone_type,
  geometry
FROM wms.disputed_and_unclaimed_areas
WHERE geometry IS NOT NULL;

COMMENT ON VIEW public.disputed_areas_view IS
  'View of disputed and unclaimed areas for WMS layer display';

