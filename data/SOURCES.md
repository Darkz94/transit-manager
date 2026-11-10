# Stage 1 map data sources

## Province boundaries

- **Source:** Natural Earth Admin 1 States and Provinces, generalized provincial polygons.
- **License:** Public domain. Natural Earth states its vector and raster data may be used, modified, and distributed for any purpose.
- **Data page:** https://www.naturalearthdata.com/downloads/10m-cultural-vectors/10m-admin-1-states-provinces/
- **Terms:** https://www.naturalearthdata.com/about/terms-of-use/
- **Credits:** Made with Natural Earth.
- **Project transformation:** Filtered to South Africa's nine provinces, simplified for a small offline game map, and normalized the historical source label "Orange Free State" to "Free State".

## Municipality anchor points

- **Source:** South Africa Administrative Divisions dataset, Open Admin Data, last updated 1 June 2026.
- **License:** Creative Commons Attribution 4.0 International (CC BY 4.0).
- **Source repository:** https://github.com/open-admin-data/south-africa-administrative-divisions
- **License text:** https://creativecommons.org/licenses/by/4.0/
- **Attribution:** South Africa Administrative Divisions Dataset (CC BY 4.0), Open Admin Data.
- **Project transformation:** Retained municipality id, English and local names, parent district, province, and coordinates; omitted unrelated source fields; normalized the source spelling "Nothern Cape" to "Northern Cape".
- **Data scope:** 213 municipality anchor points. These are administrative place anchors, not a complete settlement, suburb, or street catalogue.

## Road corridors

The Stage 1 road strokes are schematic planning corridors. They are not turn-by-turn routes or a complete road graph. We will select and document a suitable source and licensing approach before importing detailed offline road geometry.
