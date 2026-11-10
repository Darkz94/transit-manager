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

The Stage 1 road strokes are schematic planning corridors. Stage 4 now treats their points as a lightweight prototype graph for route finding and truck animation. They are not surveyed road centerlines, turn-by-turn routes, or a complete road graph; their route distances are provisional and must not be presented as authoritative real-world distances.

Before importing production offline road geometry, the current candidate is the Geofabrik South Africa OpenStreetMap extract. The extract is available under ODbL 1.0; OpenStreetMap requires attribution and that the data's license be made clear. This source has not been downloaded or included in the game yet.

- **Candidate country extract:** https://download.geofabrik.de/africa/south-africa.html
- **OpenStreetMap attribution and license:** https://www.openstreetmap.org/copyright
- **Project implementation:** Current Stage 4 route graph is generated from `stage1_corridors.json`, the project schematic data described above.

## Stage 1 prototype layers

- **Major city and town pins:** 40 manually curated seed coordinates for a first map pass. These points are approximate visual anchors and must be checked against the selected road dataset before being used to calculate travel distance or delivery time.
- **Cape Town metro demo:** 11 manually curated suburb-district seed coordinates, including Table View. These are interface placeholders for zoom and selection; they are not a complete suburb boundary dataset.
- **National route strokes:** simplified, schematic centerlines for N1, N2, N3, and N4. Their purpose is to preview map hierarchy; they are not authoritative road geometry or routing paths. SANRAL's interactive network map and route data will guide the later road-graph research: https://www.nra.co.za/interactive-map/


## Terminal demonstration points

- **Source:** Project-created sample locations for the Stage 1 interface.
- **Data file:** `data/stage1_terminals.json`.
- **Scope:** Ten fictional, unowned demo terminal pins near Cape Town, Kimberley, Gqeberha, Bloemfontein, Durban, Mahikeng, Johannesburg, Pretoria, Polokwane, and Mbombela. The coordinates reuse sample city anchors or approximate city-center coordinates for visual placement.
- **Use limits:** These are interface placeholders, not existing facilities, operating rights, port access, or surveyed terminal sites. Stage 4 uses their city-center coordinates as provisional endpoints for the schematic N1–N4 route graph; resulting distances are game estimates, not authoritative road distances.
