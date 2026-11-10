# Stage 0 Foundation

**Project:** Transit Manager  
**Status:** Foundation decisions recorded  
**Date:** 10 November 2026

## Product definition

Transit Manager is an offline-first transport-company management game. The player starts with a small operation and grows it into a national freight network across South Africa. The game is managed from a landscape map; driving is simulated rather than directly controlled.

The target map includes all nine provinces, major cities and towns, and metro suburb districts. The national map supports route and long-haul planning. Provincial and metro zoom levels support local demand, terminals, and suburb-to-suburb delivery choices.

## Technical decisions

- **Engine:** Godot 4.7.2 stable.
- **Language:** GDScript.
- **Game target for this phase:** Android phones and tablets in landscape orientation.
- **PC game builds:** Out of scope for this phase. A computer may still be used as a development tool, but the build and visual review target is Android.
- **Design viewport:** 1280 x 720, with 2D canvas-item scaling and an expanding aspect ratio.
- **Orientation:** Android landscape is explicitly set in the project configuration.
- **Rendering:** Godot Compatibility renderer for broad 2D device support.
- **Connectivity:** Core play must not require network access, accounts, ads, or remote services.
- **Save location:** Local device storage using versioned save data and atomic writes.
- **World time:** In-game clock with pause, normal speed, and fast-forward. Offline catch-up will be bounded and summarized to the player.

Godot 4.7.2 is the current stable release at the time of this foundation decision. Godot 4.8 is still in beta, so the project begins on the stable 4.7 line. Godot's official documentation recommends a 1280 x 720 base size, canvas-item stretch, and an expanding aspect ratio for mobile landscape games.

## Core gameplay loop

1. Review available cargo demand, route conditions, and contract opportunities.
2. Buy or upgrade vehicles and terminals.
3. Assign drivers, vehicles, trailers, and cargo that match the job.
4. Dispatch local, line-haul, or long-haul work.
5. Track travel time, delivery deadlines, demand use, operating costs, and vehicle wear.
6. Receive payment, maintain the fleet, and reinvest in the company.
7. Expand into new towns, metro districts, provinces, and national corridors.

The early playable build must demonstrate all three operating scales over time: local delivery, terminal-to-terminal line haul, and long-haul contracts.

## Map and location model

Use a hierarchy so the national network can grow without turning every street into an individual game object:

- **Country:** South Africa.
- **Province:** one of the nine provinces.
- **Metro or municipality:** a regional grouping of places and demand.
- **City or town:** a major network node and possible terminal location.
- **Suburb district:** a local delivery zone within a metro or large town.
- **Road segment:** a connection between place nodes with distance, road class, travel-time modifier, and operating risk.
- **Long-haul corridor:** a named route grouping between distant markets; its actual path comes from connected road segments.

The national overview should show provincial boundaries, major road corridors, and primary cities. Zooming in should reveal towns, terminals, and metro districts. Suburbs should be represented as playable delivery zones rather than individual street addresses.

The first detailed build slice is the Western Cape. The map architecture and screen should still represent the whole country from the beginning. Before loading production location data, select an offline data source and record its attribution requirements. Draw Transit Manager's own map presentation.

## Initial data entities

| Entity | Initial fields |
|---|---|
| Company | id, name, cash, reputation, level, settings, owned terminal ids |
| Province | id, name, map bounds, unlock state |
| Metro or municipality | id, province id, name, demand profile |
| Place | id, parent id, type (city, town, suburb district), name, coordinates, unlock state |
| Road segment | id, origin id, destination id, distance, road class, travel modifier, risk |
| Terminal | id, place id, level, capacity, daily cost, upgrade state |
| Vehicle | id, class, payload, cargo compatibility, energy type, condition, location, driver id, trip id |
| Driver | id, skills, licences, wage, experience, availability |
| Cargo | id, type, weight class, demand, base price, handling time, equipment needs |
| Contract | id, origin, destination, cargo, required capacity, deadline, payment, reputation requirement, status |
| Trip | id, route, vehicle assignment, depart time, arrival time, cargo quantity, costs, status |
| Ledger entry | id, simulation time, category, amount, related entity, description |
| Save metadata | schema version, simulation time, last save time, random seed, content version |

Use stable ids rather than display names as references. Keep the simulation model separate from scene nodes and interface code so the full location database can expand without changing the core rules.

## Main screen map

- **National map:** default overview with company status, cash, current simulation date and time, map controls, and major route corridors.
- **Place panel:** city, town, terminal, or suburb-district details; available demand; connections; upgrades; and local opportunities.
- **Fleet panel:** vehicle status, location, route assignment, condition, and maintenance actions.
- **Contracts panel:** available bids, active contracts, deadlines, capacity, and progress.
- **Company panel:** staff, finance, research, reputation, and progression.
- **Dispatch panel:** select cargo, vehicle, driver, destination, and departure; show estimated revenue, costs, travel time, and deadline fit before confirmation.

The first runnable shell presents the project identity and primary navigation structure. Stage 1 replaces its map placeholder with the national map overview and a detailed Western Cape slice.

## Offline simulation and saves

- Simulation actions use game time, not a server clock.
- Pause and speed controls affect all trips, demand refreshes, costs, and deadlines consistently.
- Save after important decisions and at safe simulation checkpoints.
- Include a save schema version so future updates can migrate old saves.
- Write to a temporary file and replace the prior save only after a complete write.
- On startup, recover from a missing or interrupted latest save using the last valid save.
- Apply an explicit cap to offline progress and show a short earnings, costs, arrivals, and incidents summary.
- Keep random outcomes reproducible from a saved seed where deterministic replay or save recovery matters.

## Project architecture

- **Core simulation:** clock, rules, events, and state transitions.
- **World data:** provinces, places, roads, corridors, and demand profiles.
- **Operations:** fleet, drivers, cargo, trips, and contracts.
- **Company systems:** finance, reputation, staff, research, and progression.
- **Persistence:** versioned local saves and migrations.
- **Presentation:** map, panels, input, animation, and accessibility.

Keep all tuning values and place/cargo/vehicle definitions in data resources, not hard-coded in UI scenes.

## Stage 0 completion and Stage 1 handoff

Stage 0 establishes the product boundaries, technical choice, geographic hierarchy, first data model, and a runnable landscape entry scene. Stage 1 begins the first visible map implementation:

1. Draw a readable national overview of South Africa.
2. Add province selection and map zoom.
3. Add a detailed Western Cape layer with initial places and road connections.
4. Add place and terminal information panels.
5. Show route distance and estimated travel time between connected places.

Long-haul contracts remain a core product requirement. Stage 1 does not yet need a complete economy, but its road and place model must support contracts between distant parts of the country.

## Technical references

- Godot Engine download archive: https://godotengine.org/download/archive/
- Godot Engine documentation, exporting for Android: https://docs.godotengine.org/en/stable/tutorials/export/exporting_for_android.html
- Godot Engine documentation, multiple resolutions and mobile landscape recommendations: https://docs.godotengine.org/en/4.6/tutorials/rendering/multiple_resolutions.html
