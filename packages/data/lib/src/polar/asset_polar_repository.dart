import 'package:data/src/polar/foretack_polar_parser.dart';
import 'package:domain/domain.dart';
import 'package:flutter/services.dart';
import 'package:shared/shared.dart';

/// A bundled `foretack.pol` assetet betöltő [PolarRepository] (ADR 0028
/// Addendum 2 B1/B2).
///
/// A `rootBundle`-ből olvassa az asset szövegét, majd a
/// [parseForetackPolar] pure parserrel [Polar]-rá alakítja. Az
/// eredményt (a hiba-[Result]-ot is) **memoizálja**: a [loadPolar]
/// ismételt hívása nem olvas/parse-ol újra. A bundled asset a futás
/// alatt nem változik, így a cache mindig érvényes.
///
/// **DI a teszthez.** A betöltő és az asset-út injektálható, így a
/// unit-teszt fake loaderrel fut `rootBundle` nélkül. A hiányzó asset
/// (a `rootBundle` `FlutterError`-t dob) a [PolarAssetMissing] ágra
/// fordul.
class AssetPolarRepository implements PolarRepository {
  /// Repository a megadott (vagy alapértelmezett) asset-úttal és
  /// betöltővel. Alapból a `rootBundle`-ből a bundled `foretack.pol`-t
  /// olvassa; teszthez a [loadString] és az [assetPath] felülírható.
  AssetPolarRepository({
    String assetPath = _defaultAssetPath,
    Future<String> Function(String)? loadString,
  }) : _assetPath = assetPath,
       _loadString = loadString ?? rootBundle.loadString;

  static const String _defaultAssetPath = 'assets/polars/foretack.pol';

  final String _assetPath;
  final Future<String> Function(String) _loadString;

  /// A memoizált eredmény: az első [loadPolar] tölti ki, a továbbiak ezt
  /// adják vissza (egyszeri olvasás + parse).
  Future<Result<Polar, PolarLoadError>>? _cached;

  @override
  Future<Result<Polar, PolarLoadError>> loadPolar() =>
      _cached ??= _loadAndParse();

  Future<Result<Polar, PolarLoadError>> _loadAndParse() async {
    final String content;
    try {
      content = await _loadString(_assetPath);
    } on Object {
      // A rootBundle hiányzó assetnél FlutterError-t (Error-leszármazott,
      // nem Exception) dob, ezért on Object: minden betöltési hibát az
      // assetMissing ágra terelünk — bundled assetnél a hiány az egyetlen
      // reális betöltési hiba.
      return const Err(PolarAssetMissing());
    }
    return parseForetackPolar(content);
  }
}
