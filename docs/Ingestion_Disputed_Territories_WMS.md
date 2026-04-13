# Ingestion table `disputed_territories_wms` (WMS consumption)

The **[OSM-Notes-Ingestion](https://github.com/OSM-Notes/OSM-Notes-Ingestion)**
repository creates and refreshes **`public.disputed_territories_wms`** in the
same PostgreSQL database used for notes. This document explains how
**OSM-Notes-WMS** can publish it.

## Table summary

| Column | Type | Notes |
|--------|------|--------|
| `id` | `bigserial` | Primary key |
| `kind` | `disputed_territory_kind` | `country_maritime_intersection`, `disputed_tagged`, `unclaimed_territory` |
| `name` | `varchar(256)` | Canonical label (unique with `kind`) |
| `description` | `text` | |
| `geom` | `geometry(MultiPolygon,4326)` | May be NULL until refresh |
| `osm_id` | `bigint` | Optional |
| `osm_type` | `varchar(8)` | Optional |
| `reference_url` | `text` | |
| `updated_at` | `timestamptz` | |

Refresh job:  
`OSM-Notes-Ingestion/bin/process/updateDisputedTerritoriesWMS.sh`  
(monthly cron after `updateCountries.sh`; first run with `--init`).

Source names and optional geometry hints:  
`OSM-Notes-Ingestion/data/disputed_territories_wms_names.json`.

## GeoServer (high level)

1. Ensure the ingestion refresh has run at least once so the table exists and
   `geom` is populated where hints exist.
2. Add a **feature type** on the existing PostGIS datastore pointing to
   `public.disputed_territories_wms`.
3. Publish a layer (e.g. `disputed_territories_wms`). Use an SLD that filters
   `geom IS NOT NULL` if you want to hide rows without geometry.
4. Grant the GeoServer DB role `SELECT` on the table (same pattern as
   `sql/wms/grantGeoserverPermissions.sql` for other objects).

## SQL view (optional)

If you prefer a stable view name for WMS:

```sql
CREATE OR REPLACE VIEW public.disputed_territories_wms_view AS
SELECT
  id,
  kind::text AS kind,
  name,
  description,
  geom,
  reference_url,
  updated_at
FROM public.disputed_territories_wms
WHERE geom IS NOT NULL;

COMMENT ON VIEW public.disputed_territories_wms_view IS
  'WMS-friendly view: only rows with geometry (from OSM-Notes-Ingestion refresh).';
```

Adjust schema (`public` vs `wms`) to match your deployment conventions.

## Difference from `wms.disputed_and_unclaimed_areas`

`prepareDatabase.sql` in this repo builds **derived** disputed/unclaimed
polygons from country topology. **`disputed_territories_wms`** is a **curated**
list with human-readable names aligned to wiki references. You may publish
**either** or **both** layers.

## Contract

The table is **not** part of the core ingestion `schema_version` contract for
note processing. WMS may treat it as an **optional** layer: if the table is
missing, skip publishing until ingestion `--init` has been run.

---
**Author:** Andres Gomez (AngocA)  
**Version:** 2026-04-06
