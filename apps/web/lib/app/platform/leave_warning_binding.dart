// A fül bezárására figyelmeztető `beforeunload` kötése (ADR 0048
// Addendum 4 K24). A böngészős változat csak a webes buildbe kerül; a
// VM-en futó tesztekben a kötés üres.
export 'leave_warning_binding_stub.dart'
    if (dart.library.js_interop) 'leave_warning_binding_browser.dart';
