import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Egyetlen idő-seam az application-réteghez (ADR 0009 D1).
///
/// A repo (createdAt) és a telemetria-logger (timestamp) ezt fogyasztja; a
/// Fázis 5 mark-rounding monitor is. Tesztben fake órára override-olható, így a
/// side-effect nem szóródik szét a providerekben (a domain-purity application-
/// rétegbeli megfelelője). A `DateTime.now` named ctor tear-offja `DateTime
/// Function()`.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
