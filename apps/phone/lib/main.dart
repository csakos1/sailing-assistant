import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/app.dart';
import 'package:phone/app/font_licenses.dart';

void main() {
  // A háttér-izolátum (TaskHandler) és a UI közti kommunikációs portot
  // a runApp előtt kell inicializálni (ADR 0016).
  FlutterForegroundTask.initCommunicationPort();
  // A licenc-collector lustán fut: csak a licenc-lap megnyitásakor
  // olvassa be az OFL-szövegeket (ADR 0041 D8).
  registerFontLicenses();
  runApp(const ProviderScope(child: ForetackApp()));
}
