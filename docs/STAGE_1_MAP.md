# Stage 1: South Africa map explorer

**Status:** Daytime/nighttime map, national city/terminal pins, map panning, pinch zoom, mouse wheel zoom, layer toggles, and zoom buttons are implemented. Country, Western Cape, Cape Town, and Operations phone screenshots have been reviewed; label spacing has been improved. Night-mode and tablet fit review remain.
**Project:** Transit Manager  
**Target:** Android phones and tablets in landscape orientation.

## Map design

The current Godot map follows the user's supplied daytime and nighttime examples: a clean light-blue daytime map with a cream land fill, and a deep navy nighttime version. A theme button switches between the two. The map uses the existing generalized province geometry, so its country outline follows South Africa's nine provinces rather than the sketch's illustrative outline.

The map shows the 15 national route numbers identified in the Department of Transport's published national road network map: N1–N12 (excluding N13), N14, N17, and N18. N1–N4 use individual colors; the remaining national roads use a quieter shared stroke so the main corridors remain easy to follow. National routes continue to appear at country, province, and city/town zoom. The legend distinguishes the main routes, other national roads, cities/towns, and terminals.

Map labels are placed around markers while avoiding other labels, with terminals and metro districts placed first. City and town labels outside the selected metro are suppressed in the city view so nearby locations do not compete with district names.

## Zoom and selection

Three map levels are available:

1. **Country:** all nine province outlines, national corridors, the full city/town pin set, and demo terminals.
2. **Province:** tap a province to zoom into its outline and locations; the view buttons also return to the currently selected province.
3. **City or town:** tap a city, town, or terminal to open a close-in view. Sample district pins are available for Cape Town, Johannesburg, Pretoria, Durban, Gqeberha, Bloemfontein, and East London. The selected province's clipped land outline and major corridor segments remain visible at city zoom. Other city views show only that place and any matching terminal until more local-area data is added.

The small orange links between a city center and included suburb-district pins are visual planning links, not street routes. The map does not calculate mileage, trip time, or contract values from the schematic lines. A scale bar changes with the current map zoom. Smaller local contracts can use the city-level view after we add sourced local road geometry.

The information strip shows the selected place or terminal. The terminal locations are demo pins; no terminal is owned and there is no purchase action yet. The view buttons support country, province, and city/town levels, and touch input is handled directly for Android.

The map can be dragged with one finger, zoomed with a two-finger pinch, and controlled with on-map plus, minus, and reset buttons. Routes, cities and towns, and terminals can each be hidden from the map layer panel. Layer rows use larger touch targets than the first implementation. Desktop editor use also supports drag and mouse-wheel zoom. Android touch-to-mouse emulation is disabled for the root input control so a gesture does not also trigger a map tap. The zoom level, map center, and layer choices are saved locally with the company.

## Offline data files

- `data/south_africa_provinces.geojson`: generalized outlines for all nine provinces.
- `data/municipalities.json`: 213 municipality anchors and their administrative parents.
- `data/stage1_settlements.json`: 40 sample cities, towns, and two Gauteng district pins (Soweto and Centurion).
- `data/stage1_metro_districts.json`: 35 project-curated district anchors across seven metros.
- `data/stage1_terminals.json`: 10 fictional, unowned terminal demo pins.
- `data/stage1_corridors.json`: illustrative national route strokes for 15 national route numbers.
- `data/SOURCES.md`: licenses, attribution, transformations, and accuracy limits.

The game loads these files from the project; it does not request online map tiles or a network service.

## Known limits

- The manually curated city/town and terminal coordinates are visual anchors, not surveyed terminal locations or guaranteed street-level coordinates.
- The 213 municipality anchors are administrative points, not a complete town/suburb catalogue.
- District anchors are approximate prototype points for seven metros, not verified suburb polygons or dispatch locations; the local-link strokes are schematic spokes, not roads.
- The national route strokes cover 15 national route numbers, but their hand-curated anchor paths are illustrative, not digitized road geometry. The expanded routes are map-only; game distances continue to use the existing N1–N4 prototype graph.
- Province borders and map pins are present, but no road graph, terminal ownership, capacity, or dispatch mechanics exist yet.
- Daytime phone screenshots show country, province, and city/town views. Night-mode colors and tablet layouts still need a device review.

## Remaining Stage 1 work

1. Review pinch zoom, panning, layer controls, label spacing, day and night palettes, and touch targets on Android phone and tablet landscape screens.
2. Tune map bounds and label placement further if the device review finds clipping or excessive label suppression.
3. Replace the approximate metro-district anchors with sourced district boundaries and add more metros.
4. Continue reviewing the native-node Greater Cape Town OSM candidates. The current arterial-plus-selected-local-road candidate is 2.20 MiB gzip and keeps 81.1% of active HGV nodes in its largest weak component. All twelve terminal/district anchors route within a 0.5 km snap for all six truck/cargo category probes; with a 0.2 km snap, Hout Bay still lacks a main-component access edge. Refine that anchor or its access before testing address-level dispatch. No OSM candidate is loaded by the game. See [data/SOURCES.md](../data/SOURCES.md) for processing commands, truck profiles, restrictions, and ODbL attribution notes.
5. Add terminal ownership and actions only after the Stage 2 save model exists.
6. Record the Android visual review and update the roadmap status.

## Stage 1 exit criteria

- [ ] All nine province outlines are readable in the country view.
- [ ] The player can drill down country → province → city/town and return using the view buttons.
- [x] The player can select sample places and demo terminals and see location details.
- [ ] Day and night palettes, labels, and touch targets are readable across target Android landscape sizes; the map layer controls have enlarged touch hit areas but still need on-device review.
- [ ] Every included data layer has attribution and documented accuracy limits.
- [ ] No gameplay route distance or contract value is derived from illustrative strokes.
