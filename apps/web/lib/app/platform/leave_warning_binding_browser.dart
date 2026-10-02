import 'dart:js_interop';

import 'package:flutter/foundation.dart';
import 'package:foretack_web/app/leave_warning_registry.dart';
import 'package:web/web.dart' as web;

/// A böngésző `beforeunload` eseményét a [registry]-hez köti (K24); a
/// visszaadott függvény leválasztja.
///
/// Ha bármelyik feltétel igaz, a böngésző a saját kérdését mutatja. A
/// szövege nem állítható.
VoidCallback bindLeaveWarning(LeaveWarningRegistry registry) {
  final listener = ((web.BeforeUnloadEvent event) {
    if (!registry.shouldWarn) return;
    // A régebbi böngészők a nem üres `returnValue`-ból döntenek; a
    // szöveget egyik sem mutatja meg.
    event
      ..preventDefault()
      ..returnValue = 'unsaved';
  }).toJS;
  web.window.addEventListener('beforeunload', listener);
  return () => web.window.removeEventListener('beforeunload', listener);
}
