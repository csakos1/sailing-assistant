import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:nmea_replay/src/logged_line.dart';

/// A `nmea_replay` CLI belépési pontja: egy felvett NMEA 0183 logot TCP
/// socketen visszajátszik, a B&G Vulcan WiFi-kimenetét utánozva — így egy
/// teljes verseny adatai a hajó nélkül, otthonról tesztelhetők.
Future<void> main(List<String> arguments) async {
  final parser = ArgParser()
    ..addOption(
      'port',
      abbr: 'p',
      defaultsTo: '10110',
      help: 'TCP port to listen on (the Vulcan uses 10110).',
    )
    ..addFlag(
      'loop',
      abbr: 'l',
      help: 'Restart the log from the top after the last sentence.',
    )
    ..addFlag(
      'help',
      abbr: 'h',
      negatable: false,
      help: 'Print this usage information.',
    );

  final ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (error) {
    stderr
      ..writeln(error.message)
      ..writeln(_usage(parser));
    exitCode = 64; // EX_USAGE
    return;
  }

  if (results.flag('help') || results.rest.isEmpty) {
    stdout.writeln(_usage(parser));
    return;
  }

  final port = int.tryParse(results.option('port') ?? '');
  if (port == null) {
    stderr.writeln('Invalid port: ${results.option('port')}');
    exitCode = 64;
    return;
  }

  final logPath = results.rest.first;
  final file = File(logPath);
  if (!file.existsSync()) {
    stderr.writeln('Log file not found: $logPath');
    exitCode = 66; // EX_NOINPUT
    return;
  }

  final lines = file
      .readAsLinesSync()
      .map(parseLoggedLine)
      .whereType<LoggedLine>()
      .toList();
  if (lines.isEmpty) {
    stderr.writeln('No replayable NMEA sentences in: $logPath');
    exitCode = 65; // EX_DATAERR
    return;
  }

  final loop = results.flag('loop');
  final server = await ServerSocket.bind(InternetAddress.anyIPv4, port);
  stdout.writeln(
    'NMEA replay on ${server.address.address}:$port — '
    '${lines.length} sentences${loop ? ', looping' : ''}',
  );

  await for (final client in server) {
    stdout.writeln('Client connected: ${client.remoteAddress.address}');
    // Tűzd-és-felejtsd: minden kliens a saját ütemén kapja a teljes streamet,
    // így egy reconnect nem blokkolja egy futó replay alatt az új kapcsolatot.
    unawaited(_serve(client, lines, loop: loop));
  }
}

/// Egy klienst kiszolgál: a [lines] mondatait a felvett faliidő-különbségek
/// szerint, valós időben küldi ki, opcionálisan [loop]-olva.
Future<void> _serve(
  Socket client,
  List<LoggedLine> lines, {
  required bool loop,
}) async {
  try {
    do {
      Duration? previous;
      for (final line in lines) {
        if (previous != null) {
          // Valós idejű ütemezés a prefix-időbélyegek különbségéből; a nem
          // pozitív tartam (midnight-rollover / sorrend-csúszás) azonnal fut.
          await Future<void>.delayed(line.timeOfDay - previous);
        }
        // A Vulcan prefix nélkül, CRLF-fel küld — a kliens LineSplittere jó rá.
        client.add(utf8.encode('${line.sentence}\r\n'));
        previous = line.timeOfDay;
      }
    } while (loop);
    await client.flush();
  } on SocketException {
    // A kliens lecsatlakozott visszajátszás közben — fejlesztés közben normális.
  } finally {
    await client.close();
  }
}

/// A CLI használati súgója.
String _usage(ArgParser parser) =>
    'Usage: nmea_replay <log-file> [options]\n\n'
    'Replays a recorded NMEA 0183 log over TCP, mimicking the B&G Vulcan\n'
    'WiFi output so the app behaves as if it were on the boat.\n\n'
    '${parser.usage}';
