import 'package:domain/domain.dart';

/// A [Polar] érték-objektum kézi JSON oda-vissza kódolása.
///
/// A háttér-izolátum nem éri el a `rootBundle`-t, ezért a polárt a
/// fő-izolátum tölti be, és az `init` üzenetben JSON-ként adja át (ADR
/// 0028 Addendum 3, A1-út). A séma a `race_codec.dart` mintáját követi:
/// kézi Map-építés; a tengelyek szám-tömbök, a rács sor-tömbök tömbje,
/// ahol az üres vödör (no-go alatti cella) `null`.
Map<String, dynamic> polarToJson(Polar polar) => <String, dynamic>{
  'twaAxis': polar.twaAxis,
  'twsAxis': polar.twsAxis,
  'grid': polar.grid,
};

/// JSON-ból visszaépíti a [Polar]-t.
///
/// A ctornak friss, növelhető listákat ad, mert a `Polar` mezői
/// `List.unmodifiable`-ek — a ctor teszi nem módosíthatóvá őket.
Polar polarFromJson(Map<String, dynamic> json) {
  final twaAxis = (json['twaAxis'] as List<dynamic>)
      .map((value) => (value as num).toDouble())
      .toList();
  final twsAxis = (json['twsAxis'] as List<dynamic>)
      .map((value) => (value as num).toDouble())
      .toList();
  final grid = (json['grid'] as List<dynamic>)
      .map(
        (row) => (row as List<dynamic>)
            .map((value) => (value as num?)?.toDouble())
            .toList(),
      )
      .toList();
  return Polar(twaAxis: twaAxis, twsAxis: twsAxis, grid: grid);
}
