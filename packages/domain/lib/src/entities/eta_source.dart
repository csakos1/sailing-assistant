/// ETA számítás forrása.
///
/// v1-ben csak [sog] vagy [unknown] érték keletkezik. A [polar] érték
/// v2-re van fenntartva, amikor a polár-alapú számítás (manuális
/// import + adatvezérelt learning) bekerül a domainba.
enum EtaSource {
  /// Polár-alapú számítás. v2-ben aktiválódik.
  polar,

  /// SOG-alapú számítás. v1 default-forrása, amikor érvényes SOG van.
  sog,

  /// Nem sikerült ETA-t számolni — SOG hiányzik vagy drift-szint
  /// alatti.
  unknown,
}
