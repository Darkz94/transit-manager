# Stage 5: Fleet depth and maintenance

**Status:** Vehicle condition, repair, cargo equipment, and three specialist driver endorsements are implemented; Android play review and balance tuning remain.
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

## Initial balance rules

Wear per trip is based on two-way kilometres, load share, and a baseline of 0.72 condition points per 100 km. The load factor ranges from 0.85 for a very light load to 1.30 for a full load. A single trip is capped at 45 condition points of wear. Operating cost rises by 0.5% for every condition point below 100%.

These values are first-pass game balance, not real fleet-maintenance estimates. They should be adjusted after playing a mix of local and long-haul jobs on Android.

## Android review

1. Dispatch and complete a local job, then confirm condition decreases and the selected vehicle's panel updates.
2. Repair the returned vehicle and confirm the displayed cash charge and 100% condition.
3. Try repair with insufficient cash and while a truck is in transit; confirm neither action changes the vehicle or cash.
4. Compare operating charges at high and low condition.
5. Save and resume with a worn vehicle; confirm condition persists.

## Next slice

The next fleet slice can add fuel and energy choices, inspection intervals, and additional vehicle roles. Keep breakdown events out until maintenance costs and certification rules have been reviewed on Android, so the system stays understandable rather than punitive.
