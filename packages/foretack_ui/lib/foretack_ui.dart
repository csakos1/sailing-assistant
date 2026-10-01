/// A Foretack közös design-rendszere (ADR 0041, ADR 0047 Addendum 4 E9).
///
/// Téma, színtokenek, tipográfia, valamint a bundle-ölt fontok
/// licenc-regisztrációja. A phone és a web ezen az egy belépési ponton át
/// használja, a `src/` alá közvetlenül nem importál.
library;

export 'package:foretack_ui/src/theme/confidence_colors.dart';
export 'package:foretack_ui/src/theme/font_licenses.dart';
export 'package:foretack_ui/src/theme/foretack_typography.dart';
export 'package:foretack_ui/src/theme/marine_colors.dart';
export 'package:foretack_ui/src/theme/text_tones.dart';
export 'package:foretack_ui/src/theme/theme.dart';
export 'package:foretack_ui/src/theme/warning_colors.dart';
