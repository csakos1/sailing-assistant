import 'package:flutter/material.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phone/app/app.dart';

void main() {
  // A háttér-izolátum (TaskHandler) és a UI közti kommunikációs portot
  // a runApp előtt kell inicializálni (ADR 0016).
  FlutterForegroundTask.initCommunicationPort();
  runApp(const ProviderScope(child: ForetackApp()));
}
