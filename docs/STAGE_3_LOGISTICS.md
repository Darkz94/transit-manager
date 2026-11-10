# Stage 3: Core logistics MVP

**Status:** First playable local delivery loop implemented; Android review and balancing remain.

## Current playable loop

- Start a local company in Cape Town with prototype starting funds of R1,250,000.
- Open **OPERATIONS** from the map footer.
- Buy the next vehicle in the prototype catalogue and hire the next driver candidate.
- Choose a vehicle, driver, and local cargo job, then dispatch.
- The operating cost is paid when the truck leaves. The vehicle and driver become unavailable during the trip.
- Delivery revenue is paid when the truck returns to Cape Town.
- Available demand is limited by cargo and destination, then replenishes at the next in-game day boundary.
- Drivers receive a daily wage when the in-game day boundary passes.
- Cash, staff, fleet, demand, active trips, and selections are stored in local save schema 2. Schema 1 saves migrate forward and keep their map and clock state.

## Prototype content

The initial local market uses four destination anchors: Stellenbosch, Paarl, Worcester, and Hermanus. Four cargo categories are included: parcels, packaged goods, fresh produce, and building supplies. Vehicle roles have different capacities, costs, and cargo compatibility.

Distances, rates, costs, wages, and travel times are prototype game-balance values. They are not precise operational quotes. The map's illustrative corridor strokes are not used to calculate these jobs.

## Android review still needed

1. Confirm the operations screen fits the target landscape phone.
2. Buy vehicles and hire drivers; verify unavailable vehicle/driver feedback.
3. Dispatch matching and mismatched cargo, wait through a trip, and confirm return payment.
4. Pause and restart the app; verify cash, fleet, drivers, demand, and active trip state persist.
5. Review profit values and local route timings before adding the broader Stage 4 terminal network and long-haul contract board.
