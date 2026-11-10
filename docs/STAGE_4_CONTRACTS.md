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
- Buy remote terminals in Gqeberha, Bloemfontein, Johannesburg, and Durban. Ownership unlocks daily line-haul demand from Cape Town to that city.
- Dispatch local freight loads on unlocked line hauls. Vehicle and driver stay occupied for a round trip, the load demand is consumed, and the vehicle returns to Cape Town.
- Line-haul and contract distance, costs, and travel time are now derived from a shortest-path graph built from the N1–N4 prototype corridor points. Active trucks animate outbound and back along the saved path on the country overview.
- Contract board, terminal ownership, line-haul demand, and active trip routes are included in local save schema 5. Existing schema 1–4 saves migrate forward; active older trips are assigned a prototype corridor path when possible.
- Fixed local delivery cost accounting so the estimated trip cost is charged once.

## Prototype limits and review

Travel speeds, deadline windows, freight values, terminal prices, and expenses are illustrative balance values rather than commercial quotes. The graph is based on the project's schematic corridor strokes, not detailed road centerlines; its route measurements are provisional. All current routes start at Cape Town and return there; there is no intermediate stop, custom bid amount, or line-haul backhaul yet.

On Android, check contract switching and acceptance, the held bond, vehicle eligibility, dispatch, deadline feedback, return payment, and save/resume. Review how the panel reads on the target landscape screen before expanding the contract network.
