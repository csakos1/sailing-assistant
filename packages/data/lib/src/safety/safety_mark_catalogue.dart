import 'package:domain/domain.dart';

/// Az állandó navigációs jelölők fordítási idejű katalógusa (ADR 0037
/// D7, ARCHITECTURE.md 8.10).
///
/// A v1 forrás egy `const` lista a binárisban: nincs Drift-tábla, nincs
/// migráció, nincs I/O. Az `async` szignatúra a `SafetyMarkRepository`
/// szerződéséből jön, hogy egy későbbi letölthető csomag vagy DB-tábla
/// drop-in cserélhető legyen mögé (OCP), az interfész módosítása nélkül.
///
/// **A tartalom nem becsült.** Hiányzó jelölő inkább maradjon ki, mint
/// hogy kitalált pozícióval kerüljön be: egy biztonsági képernyőn a
/// hamis adat ugyanolyan magabiztosan néz ki, mint a valódi (D17).
class SafetyMarkCatalogue implements SafetyMarkRepository {
  /// A beépített katalógust kiszolgáló repository.
  const SafetyMarkCatalogue();

  @override
  Future<List<SafetyMark>> loadSafetyMarks() async => _catalogue;
}

/// A katalógus tartalma: 7 kardinális + 4 fix építmény + 1 korlátozott
/// terület + 2 gázló-bója.
///
/// A lista `const`, tehát a hívó nem tudja módosítani — ez szándékos, a
/// katalógus read-only (D8).
const _catalogue = <SafetyMark>[
  // --- A tihanyi cső kardinálisai (7 db) ---
  //
  // FIGYELEM: a forrásadat "déli"/"északi" neve a SORT azonosítja, nem a
  // bója fajtáját, és a kettő IALA szerint FORDÍTOTT. A csatorna déli
  // szélén álló jelölőtől északra van a biztonságos víz, tehát az ott
  // álló bója ÉSZAKI kardinális (topjel két fölfelé néző kúp, a test
  // fekete felül / sárga alul) — és viszont (D6). A hozzárendelést a
  // vízen látott jelek igazolják, nem pusztán a levezetés.
  //
  // A címkék diagnosztikai azonosítók, nem UI-szövegek: a kardinálisok
  // felirat nélkül rajzolódnak, mert a jelük önmagában olvasható (D15).
  CardinalMark(
    position: Coordinate(latitude: 46.887482, longitude: 17.897225),
    label: 'Cso D1',
    direction: CardinalDirection.north,
  ),
  CardinalMark(
    position: Coordinate(latitude: 46.891949, longitude: 17.902593),
    label: 'Cso D2',
    direction: CardinalDirection.north,
  ),
  CardinalMark(
    position: Coordinate(latitude: 46.896596, longitude: 17.908348),
    label: 'Cso D3',
    direction: CardinalDirection.north,
  ),
  CardinalMark(
    position: Coordinate(latitude: 46.901143, longitude: 17.913861),
    label: 'Cso D4',
    direction: CardinalDirection.north,
  ),
  CardinalMark(
    position: Coordinate(latitude: 46.894380, longitude: 17.899812),
    label: 'Cso E1',
    direction: CardinalDirection.south,
  ),
  CardinalMark(
    position: Coordinate(latitude: 46.898222, longitude: 17.902622),
    label: 'Cso E2',
    direction: CardinalDirection.south,
  ),
  // Az "E3" szándékosan hiányzik: a rögzítéskor duplikátumként került be,
  // 2,7 méterre az E2-től. A forrás számozását megtartjuk, hogy a
  // katalógus visszakereshető maradjon az eredeti méréshez; a lyuk
  // átszámozása egy elgépelést később kinyomozhatatlanná tenne (D17).
  CardinalMark(
    position: Coordinate(latitude: 46.901921, longitude: 17.905522),
    label: 'Cso E4',
    direction: CardinalDirection.south,
  ),

  // --- Meteorológiai platformok (4 db) ---
  //
  // Fix vízi építmények: nincs biztonságos oldaluk, ki kell kerülni
  // őket. Ezek névvel rajzolódnak, mert a helynév érdemi adat (D15).
  //
  // A siófoki platform és a "VK" verseny-bója kb. 23 méterre van
  // egymástól: ugyanaz a fizikai objektum, két rekordban. Elfogadott.
  FixedStructure(
    position: Coordinate(latitude: 46.946500, longitude: 18.011817),
    label: 'Siófok',
  ),
  FixedStructure(
    position: Coordinate(latitude: 46.852850, longitude: 17.784200),
    label: 'Szemes',
  ),
  FixedStructure(
    position: Coordinate(latitude: 46.745750, longitude: 17.405033),
    label: 'Szigliget',
  ),
  FixedStructure(
    position: Coordinate(latitude: 46.725467, longitude: 17.271600),
    label: 'Keszthely',
  ),

  // --- Korlátozott terület (1 db) ---
  //
  // Védett ívóhely a tihanyi csőben. Pontként hamis lenne: 70x70 méteres
  // terület, ezért a pozíció a KÖZÉPPONT, az oldalhossz külön mező.
  RestrictedArea(
    position: Coordinate(latitude: 46.894667, longitude: 17.898883),
    label: 'Ívóhely',
    sideLength: Distance(meters: 70),
  ),

  // --- Gázló-bóják (2 db) ---
  //
  // A rendezőség ezt a két piros bóját csak a Kékszalagra teszi ki, de a
  // jelzett ~2,5 méteres gázló állandó, és 2,5 m a hajó 2,4 méteres
  // merülésénél gyakorlatilag nulla tartalék. A bója szezonális, a
  // veszély nem — ezért a katalógus mindig tartalmazza őket (D18).
  ShallowWaterMark(
    position: Coordinate(latitude: 46.739683, longitude: 17.340183),
    label: 'Győrök',
  ),
  ShallowWaterMark(
    position: Coordinate(latitude: 46.722517, longitude: 17.330067),
    label: 'Berény',
  ),
];
