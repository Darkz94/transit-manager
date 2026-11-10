# Stage 2: Offline simulation foundation

**Status:** First implementation in progress. Clock and local persistence are connected to the map preview; Android resume/recovery review remains.  
**Target:** Android phones and tablets in landscape orientation.

## Implemented in this pass

- A simulation clock starts at Day 1, 06:00 and advances without any network connection.
- The map header has a large tap target that cycles between paused, normal speed, and 3× fast-forward.
- The current speed and game time are stored locally.
- The first launch creates a local company state. The save currently includes the company name and starting cash placeholder, map view, selected location, theme, clock time, and speed.
- The app autosaves every 30 real seconds and when Android pauses the app or the window closes. Clock and map controls save immediately.
- Saves use a schema version, a temporary write, and a previous-save backup. If the main save is invalid or incomplete, the backup is loaded when available.
- When the app returns, offline progress is applied at the saved speed, up to 12 game hours. A short message reports the applied time.

## Initial tuning defaults

These are implementation defaults for the prototype, not final balance decisions:

| Setting | Current default |
|---|---:|
| Normal game day length | 24 real minutes |
| Normal speed | 60 game seconds per real second |
| Fast-forward | 3× normal speed |
| Offline catch-up limit | 12 game hours |
| First session time | Day 1, 06:00 |
| Autosave interval | 30 real seconds |

The clock uses simulation time for future trips, deadlines, demand resets, wages, and costs. Those systems do not exist yet, so this pass only establishes the shared clock and save contract.

## Save format

Current schema version: `1`.

The save is JSON in Android's app-private `user://` data directory. It stores simulation time, speed, last save timestamp, company placeholders, and the map selection/theme. The temporary file is finalized only after the new JSON is written. The previous valid save is retained as a recovery copy.

When the schema changes, add an explicit migration before increasing the current schema version. Do not silently discard a save from a prior released version.

## Remaining Stage 2 work

1. Install and open the build on Android, check the clock hit target and state after app switching.
2. Check a fresh start, ordinary relaunch, a long offline gap, and backup recovery behavior on device.
3. Add a visible new-game/reset-save flow before the first real management loop is introduced.
4. Decide whether the release needs save export/import in addition to automatic local saves.
5. Connect the clock to trip progress and daily simulation events in Stage 3.

## Exit criteria

- [x] Clock has pause, normal, and fast-forward states.
- [x] Offline catch-up is bounded and reported.
- [x] Save data is versioned, written through a temporary file, and has a recovery copy.
- [x] Map view, theme, company placeholders, and clock state persist locally.
- [ ] On Android, a session can be saved, closed, reopened, and resumed with its state intact.
- [ ] Recovery behavior and bounded catch-up have been reviewed on Android with network disabled.
