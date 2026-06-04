# Sample NMEA 0183 logs

Hand-checked NMEA 0183 fixtures for home replay (`tools/nmea_replay`) and
decoder unit tests — no boat required.

## Format

Each line is `HH:MM:SS.mmm $SENTENCE*XX`: a local-time prefix (as written by
Serial WiFi Terminal's *log-to-file*) followed by a checksummed sentence,
CRLF-terminated. `parseLoggedLine` (`tools/nmea_replay/lib/src/logged_line.dart`)
strips the prefix and schedules playback from the timestamp deltas; the replay
server then emits the bare sentence the way the Vulcan does.

## Files

| File | Contents |
|------|----------|
| `home_test_sample.nmea` | ~28 s Balaton upwind leg, starboard tack, gentle right-shifting wind (TWD 035° → 037°). 72 sentences: RMC, GGA, GLL, VTG, HDG, MWV (apparent + true), MWD, VHW. All checksums valid. |
| `moving_mark_rounding.nmea` | Synthetic ~107 s moving leg for on-device mark-rounding verification. The boat starts ~150 m south of mark M1, sails north past it (closest ≈ 8 m), then bears away toward mark M2. Same sentence set as above. All checksums valid. |

### Generating `moving_mark_rounding.nmea`

This fixture is synthetic (no boat capture available) and reproducible. It is
written by a throwaway generator; the scenario is fixed by these parameters:

- **M1** = `47.5850, 18.8550` — first mark.
- **M2** = `47.5869, 18.8578` — second mark (~300 m NE of M1).
- Boat speed ~5.0 kn, 1 Hz fixes, true wind ~035° → 037° (gentle right shift).

The boat's distance to M1 runs 150 m → 8 m → 123 m, so the `MarkRoundingDetector`
(50 m threshold + 5 m hysteresis) fires once, ~63 s in, stepping the active mark
to M2 (distance to M2 then decreasing). The run is short, so the wind-shift trend
confidence stays low and predicted TWA may read as unavailable — expected; this
fixture verifies the *rounding step*, not prediction accuracy.

To verify on-device: create a race in the app with M1 and M2 at the coordinates
above, press Start, then replay this fixture (below). Watch the active-mark name
and bearing/distance switch from M1 to M2 mid-replay.

## Replay

```bash
# Static upwind leg (loops for long sessions):
dart run tools/nmea_replay/bin/nmea_replay.dart \
  tools/sample_logs/home_test_sample.nmea --loop

# Moving mark-rounding leg (single pass — do NOT loop, it would re-approach M1):
dart run tools/nmea_replay/bin/nmea_replay.dart \
  tools/sample_logs/moving_mark_rounding.nmea
```

Then point the phone at the dev machine — the host is a build-time constant,
see [`ARCHITECTURE.md`](../../ARCHITECTURE.md) §15.6.
