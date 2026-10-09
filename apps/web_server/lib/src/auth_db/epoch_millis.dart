/// A [time] UTC epoch-milliszekundumban, ahogy az `auth.sqlite` tárolja.
int toEpochMillis(DateTime time) => time.millisecondsSinceEpoch;

/// Az [millis] epoch-milliszekundum UTC időpontként.
DateTime fromEpochMillis(int millis) =>
    DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true);

/// Mint a [fromEpochMillis], de a `null`-t megtartja.
DateTime? fromOptionalEpochMillis(int? millis) =>
    millis == null ? null : fromEpochMillis(millis);
