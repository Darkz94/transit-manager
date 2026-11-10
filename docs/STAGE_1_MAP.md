# Stage 1: South Africa map explorer

**Status:** User-directed daytime/nighttime map design and national city/terminal pins are implemented; Stage 1 remains in progress pending Android visual review.  
**Project:** Transit Manager  
**Target:** Android phones and tablets in landscape orientation.

## Map design

The current Godot map follows the user's supplied daytime and nighttime examples: a clean light-blue daytime map with a cream land fill, and a deep navy nighttime version. A theme button switches between the two. The map uses the existing generalized province geometry, so its country outline follows South Africa's nine provinces rather than the sketch's illustrative outline.

The national view shows province labels, nearby country names, ocean labels, city and town pins, terminal markers, and color-coded N1, N2, N3, and N4 route strokes. The N7 stroke is retained as an additional national corridor. The legend distinguishes routes, cities, and terminals.

## Zoom and selection

Three map levels are available:

1. **Country:** all nine province outlines, national corridors, the full city/town pin set, and demo terminals.
2. **Province:** tap a province to zoom into its outline and locations; the view buttons also return to the currently selected province.
3. **City or town:** tap a city, town, or terminal to open a close-in view. Cape Town shows its sample suburb-district pins. Johannesburg and Pretoria show the supplied Soweto and Centurion district seeds when they fall in view. Other city views are ready to accept further local-area data.

The small orange links between a city center and included suburb-district pins are visual planning links, not street routes. The map does not calculate mileage, trip time, or contract values from the schematic lines. Smaller local contracts can use the city-level view after we add sourced local road geometry.

The information strip shows the selected place or terminal. The terminal locations are demo pins; no terminal is owned and there is no purchase action yet. The view buttons support country, province, and city/town levels, and touch input is handled directly for Android.

## Offline data files

- `data/south_africa_provinces.geojson`: generalized outlines for all nine provinces.
- `data/municipalities.json`: 213 municipality anchors and their administrative parents.
- `data/stage1_settlements.json`: 40 sample cities, towns, and metro-district pins.
- `data/cape_town_suburbs.json`: 11 sample Cape Town suburb/district pins.
- `data/stage1_terminals.json`: 10 fictional, unowned terminal demo pins.
- `data/stage1_corridors.json`: illustrative national route strokes.
- `data/SOURCES.md`: licenses, attribution, transformations, and accuracy limits.

The game loads these files from the project; it does not request online map tiles or a network service.

## Known limits

- The manually curated city/town and terminal coordinates are visual anchors, not surveyed terminal locations or guaranteed street-level coordinates.
- The 213 municipality anchors are administrative points, not a complete town/suburb catalogue.
- Cape Town, Soweto, and Centurion are the only metro-district samples in this pass; the local-link strokes are schematic spokes, not roads.
- The national route strokes are illustrative, not routing geometry. No distance, travel time, or contract value should use them.
- Province borders and map pins are present, but no road graph, terminal ownership, capacity, or dispatch mechanics exist yet.
- The Android map has not yet been opened on-device for a visual fit review.

## Remaining Stage 1 work

1. Review the day and night palettes, labels, and touch targets on Android phone and tablet landscape screens.
2. Tune the map bounds and label placement from that review.
3. Expand metro-district data beyond the current Cape Town, Soweto, and Centurion examples.
4. Select and document a suitable offline road source before adding usable local or national routes.
5. Add terminal ownership and actions only after the Stage 2 save model exists.
6. Record the Android visual review and update the roadmap status.

## Stage 1 exit criteria

- [ ] All nine province outlines are readable in the country view.
- [ ] The player can drill down country → province → city/town and return using the view buttons.
- [x] The player can select sample places and demo terminals and see location details.
- [ ] Day and night palettes, labels, and touch targets are readable across target Android landscape sizes.
- [ ] Every included data layer has attribution and documented accuracy limits.
- [ ] No gameplay route distance or contract value is derived from illustrative strokes.
