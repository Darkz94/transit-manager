# Transit Manager Development Roadmap

**Research snapshot:** 10 November 2026  
**Project:** Transit Manager  
**Repository:** [Darkz94/transit-manager](https://github.com/Darkz94/transit-manager)  
**Purpose:** Build an original, offline-first transport-company management game informed by the feature set of Truck Manager - 2027.

## Project direction

Transit Manager should let the player grow a small road carrier into a large logistics company. Its core loop is to inspect demand, buy and configure vehicles, hire the right drivers, send cargo along profitable routes, maintain the fleet, reinvest earnings, and expand the network.

Truck Manager - 2027 is a useful reference for the depth and breadth of this management loop. Transit Manager should implement comparable categories of play while using original names, art, interface, map, numbers, text, and progression. We should not copy its artwork, source code, branded vehicle designs, exact data tables, or screen layouts.

The main design difference is offline play. All simulation and saves should work on the device without a login, server, advertisements, or network connection. Time should advance through a controllable in-game clock, with a clear pause and speed control. Returning after a long absence should not create unlimited or punitive catch-up.

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

1. **Camera and layout:** landscape-first. Use a readable regional road map as the main view, with compact company, fleet, cargo, and finance panels. Support touch and mouse from the start; keep the layout adaptable for tablets and desktop.
2. **Opening geography:** begin with one compact, fictional region inspired by the Western Cape road network. Use fictional city names and original map art. This gives the game a distinct identity and keeps the first road graph manageable. Expand to additional regions later.
3. **Simulation clock:** use an in-game clock with pause, normal speed, and fast-forward. Save elapsed simulation state locally. Provide a setting for offline catch-up, with a conservative cap and clear summary.
4. **Offline persistence:** use versioned local saves, automatic save after important actions, a manual save/export option if the selected engine supports it well, and recovery from interrupted writes.
5. **Original content:** create fictional manufacturers, vehicle models, staff, cargo labels, map art, icons, text, pricing, and balancing. Use Truck Manager only as a feature reference.
6. **First playable scope:** one region, six cities, one home terminal, three vehicle classes, four cargo types, local and line-haul dispatch, basic drivers, finite daily demand, revenue and costs, vehicle wear, and a save/load cycle.
7. **Platform and engine:** decide during Stage 0 after checking the repository and target devices. Godot is a reasonable candidate for a native landscape game with offline saves; avoid locking implementation until the first prototype and device targets are agreed.

## Development stages

Stages are sequenced by dependency. A stage is complete when its exit criteria are met and the resulting build remains playable.

| Stage | Goal | Main deliverables | Exit criteria |
|---|---|---|---|
| 0. Foundation and design | Agree the product boundaries and technical direction. | Repository conventions, concise game design brief, screen map, data model, engine decision, issue list. | Core loop and MVP scope are documented; project opens and runs on the chosen target. |
| 1. Landscape shell and map prototype | Make the main management view tangible before building simulation depth. | Main menu, landscape HUD, original regional map, clickable city and terminal panels, responsive scaling. | Player can inspect the map and open each core panel; placeholder visuals have a consistent style. |
| 2. Offline simulation foundation | Build reliable time and save systems. | Simulation clock, pause/speed controls, versioned local save, autosave, new-game flow, recovery behavior. | A session can be saved, closed, reopened, and resumed with vehicles and finances intact and no network access. |
| 3. Core logistics MVP | Deliver the first complete management loop. | Vehicle purchase, drivers, cargo demand, local routes, dispatch, trip progress, delivery payment, daily demand reset. | Player can buy a vehicle, assign a driver and cargo, deliver, earn a profit or loss, and understand why. |
| 4. Terminals and line hauls | Turn isolated trips into a network puzzle. | Terminal purchase and upgrades, road graph, terminal-to-terminal routes, route demand, return-leg dispatch, route overview. | The map only permits valid connections; route choices visibly affect travel time, demand, and profit. |
| 5. Fleet depth and operations | Add specialization and operating pressure. | More vehicle classes, trailer/certification compatibility, additional cargo families, fuel/electricity, wear, repair, inspections, breakdown or incident events. | Fleet composition matters; maintenance and cargo selection change the economics without making routine play tedious. |
| 6. Company progression | Add strategic growth systems. | Reputation, marketing, company levels, department managers and perks, staff hiring/training, R&D tree, achievements. | Multiple viable development paths exist, and progress is earned through clear actions rather than waiting alone. |
| 7. Contracts and regional expansion | Add longer commitments and scale. | Contract board, bidding, deadlines, multi-vehicle assignment, additional regions, long-haul routes, optional backhaul planning. | The player can plan capacity against deadlines and expand without breaking save performance. |
| 8. Economy and advanced management | Add late-game financial strategy. | Loans, budgets, advanced market conditions, company valuation, local simulated competitors, optional offline share market. | Advanced systems are understandable, optional, and do not block the core transport loop. |
| 9. Content, usability, and release readiness | Turn the prototype into a complete offline game. | Tutorial, scenarios, local events, accessibility, controller/keyboard support, balancing, performance and save migration. | A new player can complete the tutorial, grow through the main progression, and continue after an app restart with no connection. |

### Scope notes

- The MVP does not need 3D truck driving. The player manages logistics from a landscape map; vehicles can be clear original map icons with status, direction, and progress.
- A real-world stock market, online leaderboards, player alliances, account sync, and server events are excluded from the offline version. If desired, later stages can use simulated companies, local rankings, and authored events.
- Long-haul contracts, trailer swapping, and backhauling are valuable depth but should wait until local and line-haul economics work.
- Keep all simulation rules data-driven so new cities, vehicles, cargo, routes, and upgrades can be added without rewriting the core engine.

## Stage 0 starting checklist

The research and roadmap are now the first design artifact. Before implementation, confirm or revise these choices:

- [ ] Engine and target platforms
- [ ] Whether the initial region should be a fictional Western Cape-inspired map
- [ ] 2D map icons versus a 2.5D presentation
- [ ] Simulation time scale and offline catch-up cap
- [ ] Whether save export/import is required in the first release
- [ ] Initial economy: currency name, starting funds, and opening fleet size

Then create the Stage 0 implementation issues:

1. Choose engine and create the runnable project shell.
2. Define the landscape screen map and navigation.
3. Define the data schema for city, road, terminal, vehicle, driver, cargo, route, delivery, and save.
4. Create an original six-city map prototype.
5. Implement the local simulation clock and save/load spike before adding content.

## Initial simulation entities

Start with these records and keep the game logic independent from the screen code:

- **Company:** name, cash, reputation, level, research, settings, owned terminals.
- **City:** id, display name, region, coordinates, demand profile, unlock state.
- **Road edge:** start city, end city, distance, travel-time modifier, road quality.
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
