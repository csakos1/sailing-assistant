/// Egy csatlakozási kérelem belső állapota (ADR 0051 Addendum 5 M6).
///
/// A `name` kerül a `join_requests.state` oszlopba. A telefon ennél
/// kevesebbet lát (`JoinRequestState`): az elutasított és a lejárt kérelem
/// neki egyformán `notApproved` (M1).
enum JoinRequestPhase {
  /// Az `owner` még nem döntött.
  pending,

  /// Jóváhagyva; a fiók és az eszköz a sorban.
  approved,

  /// Elutasítva.
  rejected,
}
