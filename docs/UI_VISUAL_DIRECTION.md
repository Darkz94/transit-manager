# Transit Manager UI visual direction

**Status:** The map now has an expanded place card and navigation dock. A game-style HUD and section icons are added to Operations; landscape Android review remains.

## Direction

Transit Manager is a truck fleet and logistics strategy game. Its interface should make the player feel like they are running a South African carrier: a live national map, a working garage, a dispatch desk, visible freight, and trucks moving between terminals. Use an original dark-navy, road-orange, and signal-cyan visual identity, with readable day and night map palettes.

Truck Manager 2027 was reviewed as a category reference. Its public product material describes fleet management, detailed truck models, live truck tracking on a map, route planning, and operating economics. These categories inform what Transit Manager should communicate visually; its branding, art, vehicle designs, wording, screen layouts, and balance are not reused. See the [official product listing](https://apps.apple.com/sa/app/truck-manager-2027/id6474616329?platform=ipad).

## First refresh

- Replaced thin orange outlines on every control with filled primary actions, quieter secondary controls, rounded cards, clearer active tabs, and stronger text hierarchy.
- Added an original, code-drawn truck illustration to the garage, dispatch route, active-delivery panel, and moving map markers.
- Added persistent company balance, fleet, driver, and active-trip status cards to Operations.
- Reframed local freight as a Cape Town origin-to-destination dispatch card with cargo, distance, load size, and estimated revenue visible before dispatch.
- Added a map-side fleet activity card with a direct path to Operations, so the map communicates the current company state even before the first truck is sent out.
- Updated the map legend, layer controls, and zoom controls to share the same card and button language.

## Operations and starter fleet pass

- Split Operations into Overview, Fleet, Drivers, Dispatch, Depots, and Workshop sections. Local freight, line-haul, and contracts remain sub-tabs inside Dispatch.
- Replaced the single crowded two-column page with section-specific cards and actions. Overview offers direct links to the garage, crew, and dispatch desk.
- Added original class-specific vector silhouettes for vans, bakkies, small/rigid trucks, tippers, and tractor-trailer combinations.
- Ordered the vehicle offer list as starter vans, bakkie, small dropside, medium rigid, refrigerated rigid, tipper, hazmat rigid, and prime mover with a trailer silhouette. No passenger cars are included.
- Added the CapeRunner Bakkie and TownLink 3T Dropside as new early-fleet vehicles with distinct cargo fit, capacity, energy use, and operating costs.
- Preserved old saves by mapping their previous vehicle-offer index back to the same named offer; new saves store the offer ID.
- Trailer artwork communicates the later vehicle family, while swappable trailers and trailer compatibility remain future gameplay work.

## Readability pass

- Increased the shared UI text scale by 30% across the map, header, Operations cards, dispatch details, and action labels. Marker-label collision measurements use the same larger size.
- Increased the header, company status cards, Operations section tabs, Dispatch sub-tabs, primary action buttons, and bottom navigation hit areas.
- Kept the original map and simulation behavior unchanged. The new spacing and text size still need device review, especially on narrow landscape screens and the six-section Operations row.

## Game-interface pass

- Expanded the selected-place information strip into a place card with a location marker, a large selected city/town/district/province name, a clear geographic context label, and a short next-step hint.
- Enlarged the map navigation dock and added original vector icons for country, province, city/town, and operations. Active navigation has a stronger raised treatment.
- Kept the map as the dominant screen and preserved its zoom, panning, routes, and place selection behavior.

## Company HUD and Operations identity pass

- Replaced the centered page heading with a company name and current map/Operations context in the top status bar.
- Added live truck-count and on-road indicators alongside the existing clock, speed control, cash balance, and day/night control.
- Added original vector icons to the six Operations sections to distinguish Overview, Fleet, Drivers, Dispatch, Depots, and Workshop.
- These are presentation changes only; they do not add reputation, company levels, objectives, or new simulation rules.

## Next visual review

Check the map and each Operations section on Android phones and tablets in landscape. Review the default day and night palettes, text clipping, finger target sizes, truck illustration clarity, panel spacing, and the freight card at narrow aspect ratios. The class-specific silhouettes are first-pass in-game vector art; they can later be replaced by original detailed vehicle illustrations. Keep schematic map corridors clearly identified as illustrative, and do not derive game distances or costs from them.
