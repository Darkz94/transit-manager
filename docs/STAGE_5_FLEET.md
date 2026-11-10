# Stage 5: Fleet depth and maintenance

**Status:** First vehicle-condition loop implemented; Android play review and balance tuning remain.
**Target:** Android phones and tablets in landscape orientation.

## Included in this pass

- New vehicles start at 100% condition. Older local saves safely default their vehicles to 100% when loaded.
- Every completed local delivery, line haul, and contract reduces vehicle condition based on round-trip distance and a simple cargo-load factor.
- Lower condition increases the estimated direct operating cost shown through the dispatched trip's cash charge. The effect is deterministic and visible through condition, not a hidden random penalty.
- The Operations fleet panel shows selected-vehicle condition and offers a repair action.
- Repair is available only while the selected vehicle is back and available. It restores condition to 100%, costs R850 per missing percentage point, and checks available cash before charging.
- Repair cost, trip wear, condition, and the repair action are saved as part of the existing local operations data. Older saves migrate implicitly through defaults; no fleet reset is required.

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

After the wear and repair numbers feel right, add meaningful cargo and vehicle specialization: cargo equipment requirements, capacity trade-offs, and additional vehicle roles. Only then add inspection schedules or incident risk, so maintenance stays understandable rather than punitive.
