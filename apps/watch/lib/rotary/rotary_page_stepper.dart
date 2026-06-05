/// Tiszta perem-delta → lapváltás akkumulátor (ADR 0015 Addendum).
///
/// A perem `AXIS_SCROLL`-deltái lebegőpontos értékek (egy bezel-detent ~±1.0).
/// Az akkumulátor összegzi a deltákat; amikor a felhalmozott érték eléri a
/// [threshold]-ot, egy előjeles lap-lépést ad vissza, majd a küszöböt levonja —
/// így a maradék átmegy a következő eseménybe (folytonos görgetés sima marad),
/// ellentétes forgatás pedig visszafogja a számlálót (jitter-immunitás).
class RotaryPageStepper {
  /// Létrehozza a steppert; a [threshold] a lap-lépéshez szükséges felhalmozott
  /// delta (alapból 1.0 ≈ egy bezel-detent).
  RotaryPageStepper({this.threshold = 1})
    : assert(threshold > 0, 'A küszöbnek pozitívnak kell lennie.');

  /// A lap-lépéshez szükséges felhalmozott delta-küszöb.
  final double threshold;

  double _accumulated = 0;

  /// Hozzáadja a [delta]-t az akkumulátorhoz, és visszaadja a megteendő
  /// lap-lépéseket: `0` ha a küszöb alatt van, különben előjeles lépésszám
  /// (jellemzően `±1`, nagy ugrásnál több).
  int addDelta(double delta) {
    _accumulated += delta;
    var steps = 0;
    while (_accumulated >= threshold) {
      steps++;
      _accumulated -= threshold;
    }
    while (_accumulated <= -threshold) {
      steps--;
      _accumulated += threshold;
    }
    return steps;
  }
}
