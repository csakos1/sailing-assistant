/// Egy művelet futtatása egyetlen adatbázis-tranzakcióban (ADR 0048 D6 +
/// Addendum 3 I7).
///
/// A szolgáltatások ezen keresztül kérnek tranzakciót, nem a `WebDatabase`
/// közvetlenül: a szerveren a `WebDatabase.transaction` tear-offja áll
/// mögötte. A Drift a tranzakciót zónában viszi, így a repository-k hívásai
/// a művelet belsejében automatikusan a tranzakció részei.
typedef TransactionRunner = Future<T> Function<T>(Future<T> Function() action);
