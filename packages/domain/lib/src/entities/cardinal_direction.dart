/// Kardinális bója fajtája — azt kódolja, merre van a **biztonságos
/// víz** a jelölőhöz képest (IALA, ADR 0037 D5).
///
/// Az értékek sorrendje iránytű szerinti (É–K–D–NY), nem ábécé: a
/// kardinálisokat a szakirodalom és a térképjelkulcs is így sorolja.
///
/// A biztonságos szektort számoló függvény szándékosan **nincs** a
/// domainben. A v1 megjelenítés csak jelet rendel az egyes értékekhez;
/// a szektor-geometriának a korridor- és riasztási réteg lesz az első
/// fogyasztója (roadmap S3). Fogyasztó nélküli geometria drift-veszélyes
/// halott kód lenne.
enum CardinalDirection {
  /// Északi kardinális: a biztonságos víz a jelölőtől **északra** van.
  /// Topjel két fölfelé néző kúp; a test fekete felül, sárga alul.
  north,

  /// Keleti kardinális: a biztonságos víz a jelölőtől **keletre** van.
  /// Topjel két talpával összefordított kúp; a test fekete–sárga–fekete.
  east,

  /// Déli kardinális: a biztonságos víz a jelölőtől **délre** van.
  /// Topjel két lefelé néző kúp; a test sárga felül, fekete alul.
  south,

  /// Nyugati kardinális: a biztonságos víz a jelölőtől **nyugatra** van.
  /// Topjel két csúcsával összefordított kúp; a test sárga–fekete–sárga.
  west,
}
