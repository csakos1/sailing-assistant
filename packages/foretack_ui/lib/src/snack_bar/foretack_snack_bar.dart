import 'package:flutter/material.dart';
import 'package:foretack_ui/src/snack_bar/foretack_snack_bar_action.dart';
import 'package:foretack_ui/src/theme/foretack_typography.dart';
import 'package:foretack_ui/src/theme/text_tones.dart';

/// A snackbar alapértelmezett ideje.
const Duration foretackSnackBarDuration = Duration(seconds: 4);

/// A snackbar legkisebb magassága (makett 35e).
const double foretackSnackBarMinHeight = 52;

/// A Foretack snackbarja (ADR 0056 D5, makett 35e / 11b).
///
/// Lebegő, szögletes sáv `surfaceContainerHigh` háttérrel és `outline`
/// kerettel, árnyék nélkül, 20 dp-s oldalsó betéttel. Balra egy 8 dp-s
/// státusznégyzet ([markColor], alapból `onSurfaceVariant`), mellette a
/// [message], alatta opcionálisan egy halk mono [detail] sor. Ha van
/// [action], jobbra egy mono verzál cella áll saját hairline-nal, és alul
/// egy 2 dp-s sáv mutatja, mennyi idő van még a koppintásra; akció
/// nélkül a sáv elmarad (felhasználói döntés, 2026-10-11).
///
/// Az akciót nem a `SnackBar.action` hordozza, mert az M3 gombja nem
/// rajzolható a makett cellájára; így a snackbar akcióval is a
/// [duration] után zárul (a `persist` csak a `SnackBar.action`-t nézi).
SnackBar foretackSnackBar(
  BuildContext context, {
  required String message,
  String? detail,
  Color? markColor,
  ForetackSnackBarAction? action,
  Duration duration = foretackSnackBarDuration,
}) {
  final scheme = Theme.of(context).colorScheme;
  return SnackBar(
    behavior: SnackBarBehavior.floating,
    margin: const EdgeInsets.fromLTRB(20, 0, 20, 12),
    // Az 1 dp a keret helye: a keret a tartalom fölé rajzolódik, így a
    // visszaszámláló és az akció hairline-ja nem bújik alá.
    padding: const EdgeInsets.all(1),
    // Az M3 alapja (`inverseSurface`) világos: a sötét témában a világos
    // szöveg eltűnne rajta.
    backgroundColor: scheme.surfaceContainerHigh,
    elevation: 0,
    shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
    duration: duration,
    content: _SnackBarBody(
      message: message,
      detail: detail,
      markColor: markColor ?? scheme.onSurfaceVariant,
      action: action,
      duration: duration,
    ),
  );
}

class _SnackBarBody extends StatelessWidget {
  const _SnackBarBody({
    required this.message,
    required this.detail,
    required this.markColor,
    required this.action,
    required this.duration,
  });

  final String message;
  final String? detail;
  final Color markColor;
  final ForetackSnackBarAction? action;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = this.detail;
    final action = this.action;
    final body = ConstrainedBox(
      constraints: const BoxConstraints(minHeight: foretackSnackBarMinHeight),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                child: Row(
                  spacing: 12,
                  children: [
                    SizedBox.square(
                      dimension: 8,
                      child: ColoredBox(color: markColor),
                    ),
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        spacing: 2,
                        children: [
                          Text(
                            message,
                            style: supportTextStyle.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: scheme.onSurface,
                            ),
                          ),
                          if (detail != null)
                            Text(
                              detail,
                              style: numeralCaptionStyle.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (action != null) _ActionCell(action: action),
          ],
        ),
      ),
    );
    if (action == null) return body;
    return Stack(
      children: [
        body,
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: _Countdown(duration: duration),
        ),
      ],
    );
  }
}

class _ActionCell extends StatefulWidget {
  const _ActionCell({required this.action});

  final ForetackSnackBarAction action;

  @override
  State<_ActionCell> createState() => _ActionCellState();
}

class _ActionCellState extends State<_ActionCell> {
  // A bezáró animáció alatt a cella még koppintható; egy második koppintás
  // nem futtathatja újra az akciót (pl. egy dupla visszavonás).
  bool _isTriggered = false;

  void _trigger() {
    if (_isTriggered) return;
    _isTriggered = true;
    // A koppintás az akció; a snackbar ezzel bezárul.
    ScaffoldMessenger.of(
      context,
    ).hideCurrentSnackBar(reason: SnackBarClosedReason.action);
    widget.action.onPressed();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(left: BorderSide(color: scheme.outline)),
      ),
      child: InkWell(
        onTap: _trigger,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Center(
            child: Text(
              widget.action.label.toUpperCase(),
              style: statusLabelStyle.copyWith(
                letterSpacing: 1.1,
                color: scheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// A visszaszámláló sáv: `outlineVariant` alapon a `TextTones.low` kitöltés
// a teljes szélességről nullára fogy a snackbar ideje alatt. Az első
// képkockával indul, a messenger időzítője csak a 250 ms-os belépés után:
// a sáv így kb. negyed másodperccel a bezárás előtt ér nullára.
class _Countdown extends StatelessWidget {
  const _Countdown({required this.duration});

  final Duration duration;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // A `foretackTheme` mindig regisztrálja a `TextTones`-t.
    final tones = theme.extension<TextTones>()!;
    return ColoredBox(
      color: theme.colorScheme.outlineVariant,
      child: SizedBox(
        height: 2,
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 1, end: 0),
          duration: duration,
          builder: (context, share, _) => Align(
            alignment: Alignment.centerLeft,
            child: FractionallySizedBox(
              widthFactor: share,
              child: ColoredBox(color: tones.low),
            ),
          ),
        ),
      ),
    );
  }
}
