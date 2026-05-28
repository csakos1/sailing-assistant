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

## Replay

```bash
dart run tools/nmea_replay/bin/nmea_replay.dart \
  tools/sample_logs/home_test_sample.nmea --loop
```

Then point the phone at the dev machine — the host is a build-time constant,
see [`ARCHITECTURE.md`](../../ARCHITECTURE.md) §15.6.