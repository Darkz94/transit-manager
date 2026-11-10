# Stage 1: South Africa map explorer

**Status:** Map, selection details, and demo terminal pins implemented; Stage 1 remains in progress.  
**Project:** Transit Manager  
**Target:** Offline-first Android game for phones and tablets in landscape orientation. PC builds are out of scope for this phase.

## What is in the first pass

The main scene now loads local map data and draws a geographic overview with three selectable views:

1. **South Africa:** generalized outlines for all nine provinces, 213 municipality anchor points, and selected major-city/town pins.
2. **Western Cape:** provincial outline, its municipality anchors, and the Western Cape sample settlement pins.
3. **Cape Town metro:** a close-in view with eleven sample suburb/district pins.

Tap the view selector to cycle between views. Tap a visible place marker to select it; blank map taps do not change the view. The information panel shows the selected place type and its province or district. Three fictional demo terminal pins, near Cape Town, Johannesburg, and Durban, can also be selected. They are visual examples, not actual facilities or owned locations. The layout uses a side information panel on wide landscape screens and a compact overlay on narrower landscape screens.

The country overview also includes schematic N1, N2, N3, N4, and N7 strokes. The interface calls these illustrative corridors and explicitly says they are not routing geometry or distances. They exist to establish the long-haul visual layer only; contract routing and delivery-time calculations must wait for a properly sourced road graph.

## Local data files

- `data/south_africa_provinces.geojson`: generalized outlines for all nine provinces.
- `data/municipalities.json`: 213 municipality anchors and their parent administrative area.
- `data/stage1_settlements.json`: 20 manually curated sample cities and towns.
- `data/cape_town_suburbs.json`: 11 manually curated Cape Town suburb/district examples.
- `data/stage1_terminals.json`: three fictional demo terminal points for selection and panel layout.
- `data/stage1_corridors.json`: illustrative route strokes for the national overview.
- `data/SOURCES.md`: licensing, attribution, transformations, and known data limits.

This is an offline data load: the running game reads files packaged with the project and does not request map tiles or a network service.

## Known limits

- The settlement and suburb pins are visual seed coordinates, not verified delivery-zone boundaries.
- Municipality anchors are administrative points, not a full catalogue of every town, suburb, or settlement.
- The simplified province polygons are suitable for a first overview, not detailed navigation.
- Corridor lines must not be used for mileage, travel time, route selection, or contract pricing.
- Terminal purchase, ownership, capacity, and operations are not implemented; the three visible pins are demo locations only.
- Road-network navigation and gesture-based zoom are not implemented yet.
- Godot and Android visual review remains outstanding; this code pass has not been run in the engine.

## Remaining Stage 1 work

1. Open the project in Godot and review the national, Western Cape, and Cape Town views on target Android phone and tablet landscape sizes.
2. Adjust scale, label density, selection targets, and panel layout based on that visual review.
3. Review and refine place/terminal detail panel content and selection behavior from a visual pass.
4. Add terminal ownership actions only after the Stage 2 save model exists.
5. Replace the schematic corridor art only after selecting a road source, documenting its terms, and preparing an offline routing graph.
6. Record the final Stage 1 exit review in this document and update the roadmap status.

## Stage 1 exit criteria

- [ ] All nine province outlines can be inspected in the national view.
- [ ] The player can move from the national view to a detailed Western Cape view and Cape Town metro view.
- [x] Place selection shows its name, type, and administrative area; demo terminal pins can be selected.
- [ ] A terminal can be opened as a gameplay location with a future ownership action.
- [ ] The map and touch targets remain readable in target landscape aspect ratios.
- [ ] All included data has a source, license, attribution, and documented accuracy limits.
- [ ] No gameplay distance or contract value is derived from illustrative lines.
