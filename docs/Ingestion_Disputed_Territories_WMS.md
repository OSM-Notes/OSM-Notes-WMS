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

1. Ensure **`bin/process/updateDisputedTerritoriesWMS.sh`** has run at least once
   so **`public.disputed_territories_wms`** exists, geometries are refreshed where
   hints exist, and **`public.disputed_territories_wms_view`** is created (only
   rows with geometry; **`geom`** exposed as **`geometry`** for tooling such as
   OSM-Notes-WMS bbox helpers).
2. Add a **feature type** on the existing PostGIS datastore pointing to
   **`public.disputed_territories_wms_view`** (preferred). If you must target the
   base table, filter **`geom IS NOT NULL`** in the layer definition or SLD.
3. **`wmsManager.sh install`** / **`geoserverConfig_install`** publishes optional
   layer **`disputedterritories`** from the view when it exists; otherwise it
   falls back to an inline SQL layer on **`disputed_territories_wms`**.
4. Grant the GeoServer DB role **`SELECT`** on the view (and table if used); see
   **`sql/wms/grantGeoserverPermissions.sql`**.

## SQL view (ingestion-maintained)

The refresh script applies **`sql/wms/disputed_territories_wms_03_create_view.sql`**
in **OSM-Notes-Ingestion**. Manual recreate (same definition):

```sql
CREATE OR REPLACE VIEW public.disputed_territories_wms_view AS
SELECT
  id,
  kind::text AS kind,
  name,
  description,
  geom AS geometry,
  reference_url,
  updated_at
FROM public.disputed_territories_wms
WHERE geom IS NOT NULL;

COMMENT ON VIEW public.disputed_territories_wms_view IS
  'WMS-friendly view: only rows with geometry (from disputed_territories_wms refresh).';
```

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
**Version:** 2026-05-01
