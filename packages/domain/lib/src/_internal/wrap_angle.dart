/// Egy szoget [-180, 180)-ra normalizal. Library-internal helper (nem
/// barrel-exportalt), az `angle_unwrap`/`linear_regression` mintajara kulon
/// unit-tesztelheto.
double wrapTo180(double degrees) {
  final wrapped = degrees % 360;
  return wrapped >= 180 ? wrapped - 360 : wrapped;
}
