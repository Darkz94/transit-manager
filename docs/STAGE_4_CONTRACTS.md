# Stage 4: First long-haul contracts

**Status:** Contract prototype implemented; Android play review and the wider network simulation remain.

## Included in this preview

- A daily contract board with Cape Town departures to Gqeberha, Bloemfontein, Johannesburg, and Durban.
- Four example loads across packaged goods, building supplies, and fresh produce.
- Contract value, one-way distance, delivery deadline, and vehicle eligibility shown on the board.
- Acceptance places a R25,000 performance bond on hold. Dispatch also charges estimated round-trip operating costs upfront.
- Contract loads require a compatible rigid or refrigerated vehicle with enough capacity; the van is too small for these prototype loads.
- Contract trips occupy the assigned vehicle and driver until the simulated round trip returns to Cape Town.
- On-time completion returns the bond and pays the contract value. A late return forfeits the bond and pays 75% of the contract value.
- Contract results now use the truck's simulated return time, so reopening the game after a deadline does not turn an on-time return into a late one. An accepted but undispatched contract automatically expires after its deadline; the already-held bond is forfeited once, without a second deduction.
- The contract board shows the estimated return time, deadline, and time buffer together, then switches to the active truck's saved return time after dispatch. The trip's paid operating cost is saved and shown while the contract is in transit.
- Buy remote terminals in Gqeberha, Bloemfontein, Johannesburg, and Durban. Ownership unlocks daily line-haul demand from Cape Town to that city.
- Dispatch local freight loads on unlocked line hauls. Vehicle and driver stay occupied for a round trip, the load demand is consumed, and the vehicle returns to Cape Town.
- Line-haul and contract distance, costs, and travel time are now derived from a shortest-path graph built from the N1–N4 prototype corridor points. Active trucks animate outbound and back along the saved path on the country overview.
- A separate offline OSM candidate now retains explicit goods/HGV/access and truck-limit tags. Preprocessing QA can compare road access for game vehicle/cargo profiles, but the graph is not connected to contract routing or economics. Conditional rules, numeric truck limits, turn restrictions, and real terminal access still need modeling before road-graph adoption.
- Contract board, terminal ownership, line-haul demand, and active trip routes are included in local save schema 5. Existing schema 1–4 saves migrate forward; active older trips are assigned a prototype corridor path when possible.
- Fixed local delivery cost accounting so the estimated trip cost is charged once.
- Corrected province bounds to ignore distant island polygons, removed national highway strokes and decorative spokes from city drill-down, adjusted city framing for landscape viewports, and separated Android touch handling so theme taps are processed once.

## Prototype limits and review

Travel speeds, deadline windows, freight values, terminal prices, and expenses are illustrative balance values rather than commercial quotes. The graph is based on the project's schematic corridor strokes, not detailed road centerlines; its route measurements are provisional. All current routes start at Cape Town and return there; there is no intermediate stop, custom bid amount, or line-haul backhaul yet.

On Android, check contract switching and acceptance, the held bond, vehicle eligibility, dispatch, return ETA/deadline buffer, return payment, and save/resume. Verify that a truck which returns before its deadline remains on time after a later relaunch, and that an expired undispatched contract releases its selection without charging the bond twice. Review how the panel reads on the target landscape screen before expanding the contract network.
