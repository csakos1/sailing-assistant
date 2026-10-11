import 'package:flutter/material.dart';
// A `foretack_ui` és a `live_formatters` is ad `formatDistance`-t.
import 'package:foretack_ui/foretack_ui.dart' hide formatDistance;
import 'package:phone/app/true_time.dart';
import 'package:phone/features/live_race/free_mode/free_mode_link.dart';
import 'package:phone/features/live_race/live_formatters.dart';
import 'package:phone/features/live_race/widgets/stale_chip.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A szabad mód (34a) egysoros felső csíkja (`phone-ui-v1.md` §6).
///
/// Balról: a kapcsolat-pont, a kapcsolat szövege, ha kell az ELAVULT chip,
/// a GPS-idő (megszakadt kapcsolatnál helyette az adat kora), a ⋮ menü a
/// „Leállítás"-sal, és jobb szélen a térkép-gomb. A térkép-gomb a jobb
/// szélen van, így a ⋮ megjelenése vagy eltűnése sem mozdítja (a kéz vakon
/// is ott keresi, felhasználói kérés).
///
/// „Dumb" widget: a kész állapotot kapja, a műveleteket visszahívja.
class FreeModeStrip extends StatelessWidget {
  /// A csík a [link] állapottal, a [trueTime] GPS-idővel és az
  /// [isStale] jelzővel; az [onStop] `null`, ha nincs mit leállítani (ilyenkor
  /// a ⋮ menü sem látszik).
  const FreeModeStrip({
    required this.link,
    required this.trueTime,
    required this.isStale,
    required this.onOpenMap,
    this.onStop,
    super.key,
  });

  /// A csík magassága (1 dp hairline-nal együtt).
  static const double height = 48;

  /// A szabad mód kapcsolat-állapota.
  final FreeModeLink link;

  /// A GPS-idő olvasata (true-time, ADR 0012).
  final TrueTimeReading trueTime;

  /// Igaz, ha kapcsolódva vagyunk, de az adat túl régi (ADR 0042 D12).
  final bool isStale;

  /// A biztonsági térkép megnyitása.
  final VoidCallback onOpenMap;

  /// A „Leállítás" menüpont, vagy `null`.
  final VoidCallback? onStop;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // A foretackTheme mindkét extensiont regisztrálja; az `AppLocalizations`
    // a `MaterialApp` alatt mindig jelen van.
    final tones = theme.extension<TextTones>()!;
    final warningColors = theme.extension<WarningColors>()!;
    final l10n = AppLocalizations.of(context)!;
    final onStop = this.onStop;
    return Container(
      height: height,
      padding: const EdgeInsets.fromLTRB(20, 0, 2, 0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Row(
        children: [
          _LinkDot(link: link, scheme: scheme, tones: tones),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _label(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          if (isStale) ...[
            StaleChip(label: l10n.liveStale, color: warningColors.warning),
            const SizedBox(width: 10),
          ],
          _clock(l10n, scheme, tones, warningColors),
          if (onStop != null) _StripMenu(onStop: onStop),
          SizedBox.square(
            dimension: height,
            child: IconButton(
              onPressed: onOpenMap,
              padding: EdgeInsets.zero,
              iconSize: 22,
              icon: Icon(Icons.map_outlined, color: scheme.onSurfaceVariant),
              tooltip: l10n.safetyMapOpen,
            ),
          ),
        ],
      ),
    );
  }

  String _label(AppLocalizations l10n) => switch (link) {
    FreeModeSearching() => l10n.instrumentsSearching,
    FreeModeLive() => l10n.statusConnected,
    FreeModeLost() => l10n.statusDisconnected,
    FreeModeStopped() => l10n.instrumentsStopped,
  };

  // A GPS-idő; megszakadt kapcsolatnál a helyén az adat kora (34a-3),
  // keresés és leállítás alatt a hiányjel halványan (34a-1).
  Widget _clock(
    AppLocalizations l10n,
    ColorScheme scheme,
    TextTones tones,
    WarningColors warningColors,
  ) {
    final missing = Text(
      missingTime,
      style: instrumentClockStyle.copyWith(color: scheme.outline),
    );
    switch (link) {
      case FreeModeSearching() || FreeModeStopped():
        return missing;
      case FreeModeLost(:final dataAge):
        if (dataAge == null) return missing;
        final age = formatDataAge(dataAge);
        return Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              l10n.instrumentsDataLabel,
              style: statusLabelStyle.copyWith(
                fontSize: 10,
                color: tones.low,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              age.isHours
                  ? l10n.instrumentsDataAgeHours(age.value)
                  : l10n.instrumentsDataAgeMinutes(age.value),
              style: instrumentClockStyle.copyWith(
                color: warningColors.warning,
              ),
            ),
          ],
        );
      case FreeModeLive():
        // A nem szinkronizált idő `~` előtagot és tompított színt kap
        // (ADR 0012 D6), mint az 1c státuszsorán.
        final isUnsynced = trueTime.source == TrueTimeSource.wallClockUnsynced;
        final text = formatInstrumentTime(trueTime.utc);
        return Text(
          isUnsynced ? '~$text' : text,
          style: instrumentClockStyle.copyWith(
            color: isUnsynced ? tones.low : scheme.onSurfaceVariant,
          ),
        );
    }
  }
}

/// A kapcsolat-pont: 8 dp-s négyzet. Élő kapcsolatnál teli `primary`,
/// keresésnél szaggatott `primary` keret, egyébként `TextTones.low` keret.
/// Sosem zöld: a zöld a terméken a starboardé (ADR 0042 D10).
class _LinkDot extends StatelessWidget {
  const _LinkDot({
    required this.link,
    required this.scheme,
    required this.tones,
  });

  final FreeModeLink link;
  final ColorScheme scheme;
  final TextTones tones;

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: 8,
    child: CustomPaint(
      painter: _LinkDotPainter(
        color: switch (link) {
          FreeModeLive() || FreeModeSearching() => scheme.primary,
          FreeModeLost() || FreeModeStopped() => tones.low,
        },
        isFilled: link is FreeModeLive,
        isDashed: link is FreeModeSearching,
      ),
    ),
  );
}

class _LinkDotPainter extends CustomPainter {
  const _LinkDotPainter({
    required this.color,
    required this.isFilled,
    required this.isDashed,
  });

  // A keret vastagsága a makett szerint (34a-1, 34a-3).
  static const double _strokeWidth = 1.5;

  final Color color;
  final bool isFilled;
  final bool isDashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    if (isFilled) {
      canvas.drawRect(Offset.zero & size, paint);
      return;
    }
    paint
      ..style = PaintingStyle.stroke
      ..strokeWidth = _strokeWidth;
    final rect = (Offset.zero & size).deflate(_strokeWidth / 2);
    if (!isDashed) {
      canvas.drawRect(rect, paint);
      return;
    }
    // Szaggatott keret: oldalanként egy-egy rövid szakasz a két sarokból,
    // így a 8 dp-s négyzeten is szaggatottnak olvasható.
    final dash = rect.width / 3;
    final corners = [
      rect.topLeft,
      rect.topRight,
      rect.bottomRight,
      rect.bottomLeft,
    ];
    for (var index = 0; index < corners.length; index++) {
      final from = corners[index];
      final to = corners[(index + 1) % corners.length];
      final direction = (to - from) / (to - from).distance;
      canvas
        ..drawLine(from, from + direction * dash, paint)
        ..drawLine(to - direction * dash, to, paint);
    }
  }

  @override
  bool shouldRepaint(_LinkDotPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.isFilled != isFilled ||
      oldDelegate.isDashed != isDashed;
}

enum _StripAction { stop }

/// A csík ⋮ menüje; ma egyetlen sora a „Leállítás" (ADR 0056 D3).
class _StripMenu extends StatelessWidget {
  const _StripMenu({required this.onStop});

  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    // Az `AppLocalizations` a `MaterialApp` alatt mindig jelen van.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return PopupMenuButton<_StripAction>(
      tooltip: l10n.instrumentsMenuTooltip,
      icon: Icon(Icons.more_vert, color: scheme.onSurfaceVariant),
      position: PopupMenuPosition.under,
      color: scheme.surfaceContainerHigh,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
      menuPadding: const EdgeInsets.symmetric(vertical: 6),
      onSelected: (_) => onStop(),
      itemBuilder: (context) => [
        PopupMenuItem<_StripAction>(
          value: _StripAction.stop,
          child: Text(
            l10n.liveStop,
            style: supportTextStyle.copyWith(
              fontSize: 15,
              color: scheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
