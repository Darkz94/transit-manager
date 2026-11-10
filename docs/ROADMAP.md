# Transit Manager Development Roadmap

**Research snapshot:** 10 November 2026  
**Project:** Transit Manager  
**Repository:** [Darkz94/transit-manager](https://github.com/Darkz94/transit-manager)  
**Purpose:** Build an original, offline-first transport-company management game informed by the feature set of Truck Manager - 2027.

## Project direction

Transit Manager should let the player grow a small road carrier into a national logistics company operating across South Africa. Its core loop is to inspect demand, buy and configure vehicles, hire the right drivers, send cargo along profitable routes, maintain the fleet, win long-haul contracts, reinvest earnings, and expand the network from local districts to national routes.

Truck Manager - 2027 is a useful reference for the depth and breadth of this management loop. Transit Manager should implement comparable categories of play while using original names, art, interface, map, numbers, text, and progression. We should not copy its artwork, source code, branded vehicle designs, exact data tables, or screen layouts.

The main design difference is offline play. All simulation and saves should work on the device without a login, server, advertisements, or network connection. Time should advance through a controllable in-game clock, with a clear pause and speed control. Returning after a long absence should not create unlimited or punitive catch-up.

### South Africa map goal

The finished game map should cover all of South Africa, including all nine provinces, major cities, towns, and meaningful suburban delivery districts. Use a national overview for long-distance planning, then let the player zoom into provincial and metropolitan areas to see terminals, local roads, and suburb-level demand. Long-haul contracts between distant parts of the country are a core feature of the game, not a late optional extra. The map can be rolled out region by region during development, but the data model and national overview must support the full country from the first map prototype.

Represent suburbs as playable metro districts or delivery zones rather than plotting every street address as a separate node. That keeps local route planning readable while still allowing familiar places to appear in the game. Use original map illustration and interface art; establish a suitable offline geographic data source and attribution plan before building the production map.

## Research findings

The current Truck Manager store description and support material document the following systems:

- **Fleet and vehicle variety:** vehicle classes include panel and box vans, rigid trucks, tractors, and semi-trailer combinations. The store describes nine vehicle types and customizable 3D trucks. Vehicle role, payload, cargo certification, fuel or battery performance, wear, and purchase cost create fleet trade-offs.
- **Cargo specialization:** six documented cargo families are dry, refrigerated, granular, construction, machinery, and hazmat. Cargo differs by demand, pricing, distance suitability, and vehicle or trailer requirements. Heavy loads take longer to handle and increase wear, fuel use, and emissions.
- **Route operations:** local hauls serve nearby cities and return to their origin; line hauls connect owned terminals and require dispatch decisions at the destination; long hauls depend on awarded contracts and can span much greater distances. The support guide describes local, line, and contract-based long-haul operations as distinct systems.
- **Demand and network planning:** cargo demand is limited and replenishes on a daily cycle. Terminal locations, route distance, available demand, and network connectivity affect which operations are possible. Running out of demand means a truck needs to wait or use another destination.
- **Contracts:** players bid for long-haul work, assign eligible vehicles, and balance capacity, deadlines, and contract value. Official roadmap material also lists backhauling and trailer swapping as planned work; treat these as future reference features, not confirmed requirements for the first build.
- **Drivers and management staff:** specialized driver types support different cargo. Four executive departments are described: CFO (finance), COO (dispatch and logistics), CMO (marketing and contracts), and CTO (maintenance and technical efficiency). Managers have personalities and perks; department experience is earned through related actions.
- **Company growth:** buy terminals, connect cities, expand into new regions, increase reputation, and develop the company. Marketing, reliability, and environmental performance affect reputation. Terminal and fleet expansion give long-term goals.
- **Maintenance and compliance:** vehicle wear and periodic inspections create ongoing operational costs and risk. Maintaining vehicles supports reliability and reputation; overdue inspections can lead to penalties.
- **Economy and progression:** revenue must be weighed against driver wages, vehicle costs, maintenance, fuel or electricity, terminal costs, and expansion. R&D projects improve fleet, batteries, aerodynamics, telematics, and charging. The reference game also has an online stock-market and IPO system.
- **Events and social systems:** official roadmap announcements have included daily missions, an event center, convoy clubs, alliances, and seasonal features. These depend on live-service or multiplayer infrastructure, so they are not part of the offline MVP. We can later design self-contained local events and simulated competitors.

### Research boundaries

Public store descriptions and official support articles confirm system categories and selected rules. They do not expose the full internal balancing model, complete vehicle database, or every current screen. Exact prices, timers, capacities, and progression curves should be designed for Transit Manager and tuned through play, not copied from screenshots or guessed from promotional copy.

The official store listing says Truck Manager requires an internet connection. It also describes company growth, fleet management, route planning, economics, customization, achievements, and staff. The official help center provides more precise rules for haul types, cargo, management staff, maintenance, and stock-market features. The May 2026 roadmap is a dated statement of plans; its proposed features may since have changed.

## Recommended product decisions

These decisions make the first build small enough to finish while preserving a path to deeper management:

1. **Camera and layout:** landscape-first. Use a readable South Africa road map as the main view, with compact company, fleet, cargo, and finance panels. Support touch and mouse from the start; keep the layout adaptable for tablets and desktop. The map should support national, provincial, metro, and suburb-district zoom levels.
2. **Geography:** South Africa is the complete-map goal, with all nine provinces, major cities, towns, and metro suburb districts represented. Start implementation with a detailed Western Cape slice, but show the full national map and plan national long-haul corridors from the beginning. Use original illustrated map art and a verified offline data source.
3. **Simulation clock:** use an in-game clock with pause, normal speed, and fast-forward. Save elapsed simulation state locally. Provide a setting for offline catch-up, with a conservative cap and clear summary.
4. **Offline persistence:** use versioned local saves, automatic save after important actions, a manual save/export option if the selected engine supports it well, and recovery from interrupted writes.
5. **Original content:** create fictional manufacturers, vehicle models, staff, cargo labels, map art, icons, text, pricing, and balancing. Use Truck Manager only as a feature reference.
6. **First playable scope:** a South Africa overview map with one detailed Western Cape operating area, six initial destinations, one home terminal, three vehicle classes, four cargo types, local and line-haul dispatch, basic drivers, finite daily demand, revenue and costs, vehicle wear, a save/load cycle, and an early long-haul contract prototype. This proves the national map and contract design before the full location catalogue is built.
7. **Platform and engine:** use Godot 4.7.2 stable with GDScript. Target Android landscape first, with desktop builds available for development and later support. Godot 4.8 is still beta in the current release snapshot, so the project starts on the stable 4.7 line. Use a 1280 x 720 landscape design canvas, 2D canvas-item scaling, and an expanding aspect ratio for varied phone and tablet screens.

## Development stages

Stages are sequenced by dependency. A stage is complete when its exit criteria are met and the resulting build remains playable.

| Stage | Goal | Main deliverables | Exit criteria | Status |
|---|---|---|---|
| 0. Foundation and design | Set the product and technical foundations. | Godot 4.7.2 project shell, Android landscape target, screen map, geographic hierarchy, simulation entities, save plan, Stage 1 backlog. | Project shell is configured for 2D landscape play; product and data foundations are documented. |
| 1. Landscape shell and South Africa map prototype | Make the national view and geographic hierarchy tangible before building simulation depth. | Landscape HUD, South Africa overview, province and metro view switching, clickable place and demo-terminal selection, responsive narrow-landscape layout, documented offline map data. | Player can inspect a national map, zoom into a detailed Western Cape slice, view place and demo-terminal details, and use the map on target landscape sizes; geographic layers support all provinces. | In progress: map views, selection details, and three illustrative terminals are committed; Godot visual review and final tuning remain. |
| 2. Offline simulation foundation | Build reliable time and save systems. | Simulation clock, pause/speed controls, versioned local save, autosave, new-game flow, recovery behavior. | A session can be saved, closed, reopened, and resumed with vehicles and finances intact and no network access. |
| 3. Core logistics MVP | Deliver the first complete management loop. | Vehicle purchase, drivers, cargo demand, local routes, dispatch, trip progress, delivery payment, daily demand reset. | Player can buy a vehicle, assign a driver and cargo, deliver, earn a profit or loss, and understand why. |
| 4. Network logistics and first long-haul contracts | Turn isolated trips into a network and prove the contract loop early. | Terminal purchase and upgrades, South Africa road graph, terminal-to-terminal line hauls, route demand, return-leg dispatch, contract board, bidding, deadlines, eligible vehicle assignment, first long-distance contract. | A player can run local and line-haul routes, bid for a long-haul contract, assign suitable vehicles, complete it on time, and see the financial result. |
| 5. Fleet depth and operations | Add specialization and operating pressure. | More vehicle classes, trailer/certification compatibility, additional cargo families, fuel/electricity, wear, repair, inspections, breakdown or incident events. | Fleet composition matters; maintenance and cargo selection change the economics without making routine play tedious. |
| 6. Company progression | Add strategic growth systems. | Reputation, marketing, company levels, department managers and perks, staff hiring/training, R&D tree, achievements. | Multiple viable development paths exist, and progress is earned through clear actions rather than waiting alone. |
| 7. South Africa expansion and advanced long-haul operations | Fill out the national network and make long-distance planning a major progression path. | Roll out all nine provinces; add major cities, towns, and metropolitan suburb districts; add interprovincial corridors, contract tiers, multi-vehicle capacity planning, contract reputation, and backhaul planning. | The national map supports long-haul operations across the country, while metro zoom levels support local deliveries and the full location catalogue remains data-driven. |
| 8. Economy and advanced management | Add late-game financial strategy. | Loans, budgets, advanced market conditions, company valuation, local simulated competitors, optional offline share market. | Advanced systems are understandable, optional, and do not block the core transport loop. |
| 9. Content, usability, and release readiness | Turn the prototype into a complete offline game. | Tutorial, scenarios, local events, accessibility, controller/keyboard support, balancing, performance and save migration. | A new player can complete the tutorial, grow through the main progression, and continue after an app restart with no connection. |

### Scope notes

- The MVP does not need 3D truck driving. The player manages logistics from a landscape map; vehicles can be clear original map icons with status, direction, and progress.
- A real-world stock market, online leaderboards, player alliances, account sync, and server events are excluded from the offline version. If desired, later stages can use simulated companies, local rankings, and authored events.
- Long-haul contracts are part of the core game. Introduce a simple contract flow by Stage 4, then deepen contract tiers and backhaul planning as the South Africa network expands. Trailer swapping can follow once tractor and trailer compatibility is established.
- Keep all simulation rules data-driven so new cities, vehicles, cargo, routes, and upgrades can be added without rewriting the core engine.

## Stage 0 handoff

Stage 0 foundation decisions and the project shell are in place. Remaining product choices that can be made during implementation are recorded below:

- [x] Engine: Godot 4.7.2 stable with GDScript.
- [x] Primary target: Android landscape; desktop builds support development and may be considered for release.
- [x] Full-map goal: South Africa, with nine provinces and city, town, and metro-district layers.
- [x] Visual direction: 2D landscape, map-first interface.
- [ ] Choose simulation time scale and offline catch-up cap during the offline simulation stage.
- [ ] Decide whether save export/import is needed before release.
- [ ] Set starting funds, currency display, and opening fleet during economy balancing.

Stage 0 outputs:

1. Godot project shell and landscape entry scene.
2. Screen map and geographic hierarchy in [docs/STAGE_0_FOUNDATION.md](STAGE_0_FOUNDATION.md).
3. Initial data schema for places, roads, terminals, vehicles, drivers, cargo, contracts, trips, deliveries, and saves.

Stage 1 progress: the national, Western Cape, and Cape Town map views now load offline geography, selectable place details, and three clearly labeled demo terminal pins. See [docs/STAGE_1_MAP.md](STAGE_1_MAP.md) and [data/SOURCES.md](../data/SOURCES.md) for scope and limitations.

Next implementation work:

1. Finish Stage 1: review the map in Godot at target Android landscape and desktop sizes, tune labels and touch targets, and record the visual review.
2. Stage 2: implement and save the local simulation clock.
3. Stage 4: prototype the long-haul contract flow between distant destinations.

## Initial simulation entities

Start with these records and keep the game logic independent from the screen code:

- **Company:** name, cash, reputation, level, research, settings, owned terminals.
- **Place hierarchy:** province, metro or municipality, city/town, and suburb district with stable ids, display names, coordinates, demand profiles, and unlock state.
- **Road segment:** start and end place, distance, travel-time modifier, road quality, road class, and whether it belongs to a long-haul corridor.
- **Terminal:** city, level, capacity, daily costs, upgrade state.
- **Vehicle:** class, capacity, compatible cargo, energy type, condition, location, assigned driver, trip state.
- **Driver:** skills, permitted cargo, wage, fatigue or availability, experience.
- **Cargo:** type, weight class, demand, base price, handling time, vehicle requirements.
- **Route or trip:** origin, destination, vehicle, cargo, dispatch time, arrival time, status, expected revenue and costs.
- **Ledger entry:** timestamp, category, amount, related entity, description.
- **Save metadata:** schema version, game time, last real-world save time, random seed, content version.

## Core balancing model to prototype

Use transparent calculations first; tune the numbers after the loop works:

**Trip contribution = delivery revenue - driver cost - energy cost - wear cost - terminal or handling fees**

A route should show expected revenue, travel time, likely direct costs, cargo demand remaining, and projected contribution before dispatch. This addresses a common planning friction visible in player feedback: not being able to see route demand clearly before committing vehicles.

Daily demand can be generated from a stable seed and city profile, then replenished at the in-game day boundary. Avoid opaque random swings in the MVP. Add weather, fuel-price variation, and incidents only after base route economics are legible.

## Source register

1. Google Play listing, Truck Manager - 2027. Store feature description, online requirement, platform listing, and player feedback.  
   https://play.google.com/store/apps/details?id=com.trophygames.truckmanager
2. Truck Manager Help Center, “What are the differences between each haul type?” Local, line, and long-haul rules.  
   https://truckmanager.zendesk.com/hc/en-us/articles/21585472049426-What-are-the-differences-between-each-haul-type
3. Truck Manager Help Center, “Cargo Type Overview.” Six cargo families and vehicle requirements.  
   https://truckmanager.zendesk.com/hc/en-us/articles/29863461923218-Cargo-Type-Overview
4. Truck Manager Help Center, “What is the difference between light and heavy cargo?” Handling, earnings, and wear trade-offs.  
   https://truckmanager.zendesk.com/hc/en-us/articles/21585488770962-What-is-the-difference-between-light-and-heavy-cargo
5. Truck Manager Help Center, “What vehicle types are there?” Vehicle-class roles.  
   https://truckmanager.zendesk.com/hc/en-us/articles/21584708393874-What-vehicle-types-are-there
6. Truck Manager Help Center, “Staff Management: Personalities & Perks.” Executive departments and manager traits.  
   https://truckmanager.zendesk.com/hc/en-us/articles/33405139787282-Staff-Management-Personalities-Perks
7. Truck Manager Help Center, “How do I earn Staff XP?” Department XP sources.  
   https://truckmanager.zendesk.com/hc/en-us/articles/33500816130322-How-do-I-earn-Staff-XP
8. Truck Manager Help Center, “R&D HAS LANDED! 19/06/2025.” Research department categories.  
   https://truckmanager.zendesk.com/hc/en-us/articles/27431482865938-R-D-HAS-LANDED-19-06-2025
9. Truck Manager Help Center, “Why should I maintain my vehicles?” Reliability, reputation, and risk.  
   https://truckmanager.zendesk.com/hc/en-us/articles/21609999070994-Why-should-I-maintain-my-vehicles
10. Truck Manager Help Center, “How do I expand into another country? How do I buy another terminal?” Network expansion constraints.  
    https://truckmanager.zendesk.com/hc/en-us/articles/21712302067858-How-do-I-expand-into-another-country-How-do-I-buy-another-terminal
11. Truck Manager Help Center, “How can I improve my company reputation?” Marketing, maintenance, and ESG effects.  
    https://truckmanager.zendesk.com/hc/en-us/articles/21585546088210-How-can-I-improve-my-company-reputation
12. Truck Manager Help Center, “The Stock Exchanges” and “Portfolio and Investing.” Online stock-market reference systems.  
    https://truckmanager.zendesk.com/hc/en-us/articles/33764668138514-The-Stock-Exchanges  
    https://truckmanager.zendesk.com/hc/en-us/articles/33764627568530-Portfolio-and-Investing
13. Truck Manager Help Center, “Roadmap Update! 08/05/2026.” Dated planned features including alliances, events, backhauling, and trailer swapping.  
    https://truckmanager.zendesk.com/hc/en-us/articles/35419360696338-Roadmap-Update-08-05-2026
