/// A Foretack közös design-rendszere és widgetjei (ADR 0041, ADR 0047
/// Addendum 4 E9, Addendum 5 F3).
///
/// Téma, színtokenek, tipográfia, a bundle-ölt fontok licenc-regisztrációja,
/// a napló és a részletező közös widgetjei, valamint a saját l10n
/// (`ForetackUiLocalizations`). A phone és a web ezen az egy belépési
/// ponton át használja, a `src/` alá közvetlenül nem importál.
library;

export 'package:foretack_ui/src/dialog/foretack_dialog.dart';
export 'package:foretack_ui/src/dialog/foretack_dialog_action.dart';
export 'package:foretack_ui/src/dialog/foretack_dialog_action_bar.dart';
export 'package:foretack_ui/src/dialog/foretack_dialog_action_cell.dart';
export 'package:foretack_ui/src/dialog/foretack_dialog_detail_cell.dart';
export 'package:foretack_ui/src/dialog/foretack_dialog_frame.dart';
export 'package:foretack_ui/src/format/compass_point_labels.dart';
export 'package:foretack_ui/src/format/track_stats_formatters.dart';
export 'package:foretack_ui/src/l10n/foretack_ui_localizations.dart';
export 'package:foretack_ui/src/map/map_attribution.dart';
export 'package:foretack_ui/src/map/mark_pin.dart';
export 'package:foretack_ui/src/map/track_map.dart';
export 'package:foretack_ui/src/map/track_point.dart';
export 'package:foretack_ui/src/map/track_speed_legend.dart';
export 'package:foretack_ui/src/race/detail_mark_row.dart';
export 'package:foretack_ui/src/race/detail_status_strip.dart';
export 'package:foretack_ui/src/race/status_badge.dart';
export 'package:foretack_ui/src/race/track_stats_row.dart';
export 'package:foretack_ui/src/race_log/race_log_formatters.dart';
export 'package:foretack_ui/src/race_log/race_log_month_header.dart';
export 'package:foretack_ui/src/race_log/race_log_row.dart';
export 'package:foretack_ui/src/race_log/race_log_stats_strip.dart';
export 'package:foretack_ui/src/race_log/race_log_year_selector.dart';
export 'package:foretack_ui/src/theme/confidence_colors.dart';
export 'package:foretack_ui/src/theme/font_licenses.dart';
export 'package:foretack_ui/src/theme/foretack_typography.dart';
export 'package:foretack_ui/src/theme/marine_colors.dart';
export 'package:foretack_ui/src/theme/medal_colors.dart';
export 'package:foretack_ui/src/theme/text_tones.dart';
export 'package:foretack_ui/src/theme/theme.dart';
export 'package:foretack_ui/src/theme/warning_colors.dart';
