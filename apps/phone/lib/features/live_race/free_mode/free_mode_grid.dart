import 'package:domain/domain.dart';
import 'package:flutter/material.dart';
// A `foretack_ui` és a `live_formatters` is ad `formatDistance`-t.
import 'package:foretack_ui/foretack_ui.dart' hide formatDistance;
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/target_speed.dart';
import 'package:phone/features/live_race/widgets/data_rail.dart';
import 'package:phone/features/live_race/widgets/main_column_cell.dart';
import 'package:phone/features/live_race/widgets/rail_cell.dart';
import 'package:phone/features/live_race/widgets/side_arrow.dart';
import 'package:phone/features/live_race/widgets/twa_value.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A szabad mód (34a, B kiosztás) rácsa: fő oszlop STW/SOG · CÉL-SEB. ·
/// VMG, a sínen TWA és TWS (`phone-ui-v1.md` §6).
///
/// Az 1c váza (ADR 0042): a fő oszlop flexe 1.6 / 1.15 / 1, a számméretek
/// 76 / 48 / 38, a sín 132 dp. Egy sebesség-cella: STW, ha nincs, SOG — a
/// felirat vált, kettő egyszerre soha. Magyarázó felirat nincs.
///
/// Egy hiányzó érték a hiányjelet kapja `outline` színnel (34a-4); a
/// [hasValues] hamis volta (keresés, leállítva) minden értéket hiányzónak
/// tekint (34a-1). „Dumb" widget: a nyers értékeket kapja.
class FreeModeGrid extends StatelessWidget {
  /// A rács a mért értékekkel.
  const FreeModeGrid({
    required this.hasValues,
    required this.speedThroughWater,
    required this.speedOverGround,
    required this.targetSpeedPercent,
    required this.vmgKnots,
    required this.targetVmgKnots,
    required this.vmgSteerCorrection,
    required this.trueWindAngle,
    required this.trueWindSpeed,
    super.key,
  });

  /// Mutat-e értékeket; keresés és leállítás alatt hamis.
  final bool hasValues;

  /// A víz szerinti sebesség (STW), vagy `null`.
  final Speed? speedThroughWater;

  /// A föld szerinti sebesség (SOG), az STW hiányában ez látszik.
  final Speed? speedOverGround;

  /// Az engine target-%-a, vagy `null` (nincs polár, no-go, nincs
  /// sebesség).
  final double? targetSpeedPercent;

  /// Az élő VMG csomóban, vagy `null`.
  final double? vmgKnots;

  /// A polár cél-VMG csomóban, vagy `null` (ilyenkor a kísérő sor elmarad).
  final double? targetVmgKnots;

  /// A VMG-optimum felé kormányzás iránya a cél mellett (ADR 0042 D3).
  final Angle? vmgSteerCorrection;

  /// A vízhez mért, előjeles TWA, vagy `null`.
  final Angle? trueWindAngle;

  /// A vízhez mért TWS, vagy `null`.
  final Speed? trueWindSpeed;

  @override
  Widget build(BuildContext context) {
    // Az `AppLocalizations` a `MaterialApp` alatt, a `TextTones` a
    // foretackTheme-ben mindig jelen van.
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tones = theme.extension<TextTones>()!;
    final isSpeedOverGround =
        hasValues && speedThroughWater == null && speedOverGround != null;
    final speed = isSpeedOverGround ? speedOverGround : speedThroughWater;
    final vmgTarget = hasValues ? formatVmgTarget(targetVmgKnots) : null;
    final steerSide = arrowSideFromSign(vmgSteerCorrection?.degrees);

    Text value(String text, TextStyle style) => Text(
      text,
      maxLines: 1,
      style: style.copyWith(
        color: text == missingValue ? scheme.outline : scheme.onSurface,
      ),
    );

    String shown(String text) => hasValues ? text : missingValue;

    final twa = trueWindAngle;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 160,
                child: MainColumnCell(
                  label: isSpeedOverGround ? l10n.liveSog : l10n.liveStw,
                  padding: const EdgeInsets.fromLTRB(20, 16, 14, 14),
                  child: value(
                    shown(formatSpeedLive(speed)),
                    numeralHeroStyle,
                  ),
                ),
              ),
              _hairline(scheme),
              Expanded(
                flex: 115,
                child: MainColumnCell(
                  label: l10n.liveTargetSpeed,
                  child: value(
                    shown(formatTargetSpeedPercent(targetSpeedPercent)),
                    numeralLargeStyle,
                  ),
                ),
              ),
              _hairline(scheme),
              Expanded(
                flex: 100,
                child: MainColumnCell(
                  label: l10n.liveVmg,
                  support: vmgTarget == null
                      ? null
                      : Row(
                          children: [
                            Text(
                              l10n.liveVmgTarget(vmgTarget),
                              style: supportTextStyle.copyWith(
                                color: tones.low,
                              ),
                            ),
                            if (steerSide != ArrowSide.none) ...[
                              const SizedBox(width: 6),
                              SideArrow(
                                side: steerSide,
                                glyph: ArrowGlyph.line,
                                size: 13,
                              ),
                            ],
                          ],
                        ),
                  child: value(
                    shown(formatVmgLive(vmgKnots)),
                    numeralMediumStyle,
                  ),
                ),
              ),
            ],
          ),
        ),
        DataRail(
          cells: [
            RailCell.child(
              label: l10n.liveTwa,
              valueChild: hasValues && twa != null
                  ? TwaValue(twa, style: numeralSmallStyle)
                  : value(missingValue, numeralSmallStyle),
            ),
            RailCell.child(
              label: l10n.liveTws,
              valueChild: value(
                shown(formatSpeedLive(trueWindSpeed)),
                numeralSmallStyle,
              ),
              hasDivider: false,
            ),
          ],
        ),
      ],
    );
  }

  // A cellák közötti 1 dp-s elválasztó (ADR 0042 D1).
  Widget _hairline(ColorScheme scheme) => SizedBox(
    height: 1,
    child: ColoredBox(color: scheme.outlineVariant),
  );
}
