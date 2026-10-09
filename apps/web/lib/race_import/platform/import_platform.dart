// A fájlválasztó és a feltöltő platform-implementációja (ADR 0048
// Addendum 4 K18). A böngészős változat csak a webes buildbe kerül: a
// `package:web` a `dart:js_interop`-ra épül, ami a VM-en nem fordul. A
// VM-en futó tesztek a csonkot látják, és a providereket felülírják.
export 'import_platform_stub.dart'
    if (dart.library.js_interop) 'import_platform_browser.dart';
