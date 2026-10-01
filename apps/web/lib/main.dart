import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/foretack_web_app.dart';

void main() {
  // A licenc-collector lustán fut: csak a licenc-lap megnyitásakor olvassa
  // be az OFL-szövegeket (ADR 0041 D8), ahogy a phone-on.
  registerFontLicenses();
  runApp(const ProviderScope(child: ForetackWebApp()));
}
