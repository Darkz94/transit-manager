# Stage 5: Fleet depth and maintenance

**Status:** Vehicle wear/service, energy costs, mileage inspections, cargo equipment, three specialist driver endorsements, and rare recoverable trip incidents are implemented; Android play review and balance tuning remain.
**Target:** Android phones and tablets in landscape orientation.

## Included in this pass

- New vehicles start at 100% condition. Older local saves safely default their vehicles to 100% when loaded.
- Every completed local delivery, line haul, and contract reduces vehicle condition based on round-trip distance and a simple cargo-load factor.
- Lower condition increases the estimated direct operating cost shown through the dispatched trip's cash charge. The effect is deterministic and visible through condition, not a hidden random penalty.
- The Operations fleet panel shows selected-vehicle condition and offers a repair action.
- Repair is available only while the selected vehicle is back and available. It restores condition to 100%, costs R850 per missing percentage point, and checks available cash before charging.
- Repair cost, trip wear, condition, and the repair action are saved as part of the existing local operations data. Older saves migrate implicitly through defaults; no fleet reset is required.
- Vehicles now carry equipment tags. Fresh produce requires refrigeration, building supplies require a flatbed, and industrial machinery requires a machinery platform. The Operations job and contract summaries show the equipment requirement, and dispatch explains why a selected truck is unsuitable.
- Added the Longhaul Prime Mover as the specialist machinery truck, with higher capacity, running cost, and purchase price. Industrial machinery jobs use a higher cargo wear factor.
- Legacy fleets infer suitable equipment from the saved cargo capabilities so existing saves remain usable.
- Added controlled-chemical freight, which requires both a hazmat-equipped SafeRoute DG Rigid and a driver with a hazmat endorsement. Other vehicles or general drivers are rejected at dispatch with a clear explanation.
- Added Thandi Ndlovu (hazmat), Zanele Pieters (cold-chain), and Sipho Maseko (heavy-haul) as specialist driver candidates. Fresh produce needs cold-chain credentials; industrial machinery needs heavy-haul credentials. Driver credentials appear in Operations and are saved locally. Existing drivers default to general credentials when older saves are loaded.
- Added bulk aggregates and the CapeBulk Tipper 10T. Bulk aggregates require tipper equipment; the tipper can also carry building supplies.
- Vehicle running costs now include energy consumption. Diesel, petrol, and electricity have separate illustrative game prices; route cost summaries include energy plus the vehicle's baseline operating cost.
- Added the E-Courier Urban Van as a lower-capacity electric option with a different purchase price and running-cost profile.
- Added the CapeRunner Bakkie and TownLink 3T Dropside as early-fleet steps between vans and medium rigid trucks. Their capacities, cargo eligibility, energy use, and running costs are separate game values.
- Reordered new-company vehicle offers to move from vans through a bakkie and small truck before medium and specialist trucks. Existing saves keep their previous next vehicle through a stable offer-ID migration.
- Added distinct first-pass vector visuals for vans, bakkies, rigid trucks, tippers, and the later prime-mover/trailer combination. The current trailer image is illustrative; trailer ownership, swapping, and compatibility are not implemented yet.
- Split the Operations screen into Overview, Fleet, Drivers, Dispatch, Depots, and Workshop sections. Local, line-haul, and contract work remain inside Dispatch.
- Vehicles track odometer distance. An inspection becomes due every 5,000 km; dispatch is blocked until the available vehicle is serviced. Service repairs condition and, when due, includes the inspection fee. The odometer and next inspection threshold are saved locally.
- Two permanent workshop improvements reduce condition-repair costs across the fleet: Workshop Efficiency costs R200,000 for a 20% saving; Workshop Expansion costs R450,000 more for a total 35% saving. Inspection fees are unchanged. Workshop level persists in local saves, including migration from the original single-upgrade save field.
- The selected vehicle's fleet card now shows its odometer against the next inspection threshold, along with the inspection-due warning.
- Trips can encounter a mild slow-traffic delay or minor tyre repair. The base chance is 2.5% per trip, rising with route length and low vehicle condition to a maximum of 6.5%.
- Slow traffic adds 0.5 game hours to the return ETA without an extra charge. A minor tyre repair adds 0.75 game hours, costs R1,800, and adds one condition point of wear. Neither event immobilizes the truck or loses cargo.
- Incident outcome and effect are saved on the trip at dispatch. If the repair cost would exceed available cash beyond the planned trip expense, the event becomes a no-cost traffic delay when the ETA allows it; otherwise the incident is skipped. A contract incident is only applied when its delay still leaves the truck on or before its deadline, so a random incident cannot create a bond loss.
- Dispatch messages and the active trip summary show incident delays and costs; the return message repeats the outcome. Older saves and trips without incident fields continue to load with no incident effects.

## Initial balance rules

Wear per trip is based on two-way kilometres, load share, and a baseline of 0.72 condition points per 100 km. The load factor ranges from 0.85 for a very light load to 1.30 for a full load. Cargo type adds its own wear factor. A single trip is capped at 45 condition points of wear. Operating cost rises by 0.5% for every condition point below 100%.

Current energy-price defaults are R24 per litre of diesel, R26 per litre of petrol, and R3.20 per kWh. These are in-game balancing placeholders, not current South African retail prices. Inspection interval and fee defaults are 5,000 km and R12,000.

These values are first-pass game balance, not real fleet-maintenance estimates. They should be adjusted after playing a mix of local and long-haul jobs on Android.

## Android review

1. Dispatch and complete local jobs until inspection is due; confirm the odometer and due warning update.
2. Try dispatching an overdue truck; confirm it is blocked until service.
3. Service the truck and confirm the inspection fee, repair cost, and next inspection distance.
4. Compare expected trip costs across diesel, petrol, and electric vehicles and at high and low condition.
5. Save and resume with a worn vehicle and an inspection due; confirm condition, energy type, odometer, and inspection threshold persist.

## Next slice

Review service costs, mileage inspections, both workshop improvements, and the new incident frequency/effects on Android. Tune from play before adding more incident types or breakdowns; keep the system recoverable and avoid disabling trucks or losing cargo.
