// A böngészős letöltés indítása (ADR 0050 Addendum 3 G2). A böngészős
// változat csak a webes buildbe kerül; a VM-en futó tesztekben üres.
export 'file_download_stub.dart'
    if (dart.library.js_interop) 'file_download_browser.dart';
