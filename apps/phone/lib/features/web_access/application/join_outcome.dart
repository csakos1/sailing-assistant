import 'package:flutter/foundation.dart';
import 'package:phone/features/web_access/data/web_account.dart';

/// Egy függő csatlakozási kérelem lekérdezésének eredménye (ADR 0051
/// Addendum 9 X3).
@immutable
sealed class JoinOutcome {
  const JoinOutcome();
}

/// A tulajdonos még nem döntött.
final class JoinStillPending extends JoinOutcome {
  const JoinStillPending();
}

/// Jóváhagyva: a fiók már a tárban van.
final class JoinApproved extends JoinOutcome {
  /// Jóváhagyás az [account] új fiókkal.
  const JoinApproved(this.account);

  /// A mentett fiók.
  final WebAccount account;
}

/// Elutasítva vagy lejárt: a kérelem és a kulcsok már törlődtek.
final class JoinNotApproved extends JoinOutcome {
  const JoinNotApproved();
}

/// A szerver nem érhető el vagy hibázott; semmi nem változott, a
/// következő lekérdezés újra próbálja (H11: csendben).
final class JoinCheckFailed extends JoinOutcome {
  const JoinCheckFailed();
}
