import 'dart:async';

import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/start_time/start_time_calendar.dart';
import 'package:phone/format/scheduled_start_format.dart';
import 'package:phone/l10n/app_localizations.dart';

/// A rajtidő-választó eredménye: a választott helyi idő, vagy `null`, ha a
/// felhasználó a „Nincs rajtidő" gombbal kiürítette a mezőt.
///
/// A lap bezárása (háttér, vissza) maga `null` eredményt ad a
/// [showStartTimeSheet]-ből, ezért a kiürítés külön rekordban jön.
typedef StartTimeChoice = ({DateTime? localStart});

/// A naptár-cella magassága (33c).
const double _dayCellHeight = 40;

/// A cellák és a gombok közti köz (33c).
const double _gridGap = 4;

/// Az oldalsó margó (33c).
const double _sideMargin = 20;

/// Az alsó gombok magassága (33c).
const double _buttonHeight = 52;

/// A léptetők szélessége, a nyíl-cellák és a szám magassága (33c).
const double _stepperWidth = 84;
const double _stepperArrowHeight = 32;
const double _stepperValueHeight = 52;

/// Hosszú nyomásnál az első ismétlések köze, és a gyorsítás utáni köz.
const Duration _repeatInterval = Duration(milliseconds: 150);
const Duration _fastRepeatInterval = Duration(milliseconds: 50);

/// Ennyi ismétlés után vált a léptető a gyors ütemre.
const int _repeatsBeforeFast = 8;

/// Megnyitja a rajtidő-választót (33c) modális alsó lapon.
///
/// Az [initial] a kezdőérték, a [today] a naptár „ma" jelölője; mindkettő
/// helyi idő. A visszatérés `null`, ha a lapot választás nélkül zárták.
Future<StartTimeChoice?> showStartTimeSheet(
  BuildContext context, {
  required DateTime initial,
  required DateTime today,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<StartTimeChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surfaceContainer,
    // A design-rendszer minden felülete r0 (ADR 0044 D47); a felső vonal
    // választja el a lapot a mögötte tompított űrlaptól.
    shape: Border(top: BorderSide(color: scheme.outline)),
    builder: (_) => StartTimeSheet(initial: initial, today: today),
  );
}

/// A rajtidő-választó (33c): naptár hétfővel kezdve és 24 órás óra / perc
/// léptetők.
///
/// A dátumot és az időt **együtt** adja (ADR 0055 D1): csak dátum nem
/// választható. A múltbeli napok halkítva, de választhatók (ADR 0055 D9:
/// egy utólag rögzített verseny rajtideje is menthető).
class StartTimeSheet extends StatefulWidget {
  /// Egy választó az [initial] értékkel és a [today] jelölővel.
  const StartTimeSheet({required this.initial, required this.today, super.key});

  /// A kezdőérték (helyi idő).
  final DateTime initial;

  /// A mai nap (helyi idő) a keretes jelöléshez.
  final DateTime today;

  @override
  State<StartTimeSheet> createState() => _StartTimeSheetState();
}

class _StartTimeSheetState extends State<StartTimeSheet> {
  late DateTime _visibleMonth;
  late DateTime _selectedDay;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    _visibleMonth = DateTime(initial.year, initial.month);
    _selectedDay = DateTime(initial.year, initial.month, initial.day);
    _hour = initial.hour;
    _minute = initial.minute;
  }

  DateTime get _selected => DateTime(
    _selectedDay.year,
    _selectedDay.month,
    _selectedDay.day,
    _hour,
    _minute,
  );

  void _stepMonth(int delta) =>
      setState(() => _visibleMonth = shiftMonth(_visibleMonth, delta));

  void _stepHour(int delta) =>
      setState(() => _hour = wrapStep(_hour, delta, 24));

  void _stepMinute(int delta) =>
      setState(() => _minute = wrapStep(_minute, delta, 60));

  void _selectDay(int day) => setState(
    () => _selectedDay = DateTime(_visibleMonth.year, _visibleMonth.month, day),
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              title: l10n.startTimeSheetTitle,
              value: formatScheduledStart(l10n, _selected),
            ),
            _MonthRow(
              label: _monthLabel(l10n, _visibleMonth),
              previousTooltip: l10n.startTimeSheetPreviousMonth,
              nextTooltip: l10n.startTimeSheetNextMonth,
              onStep: _stepMonth,
            ),
            _CalendarGrid(
              month: _visibleMonth,
              weekdays: l10n.startTimeSheetWeekdays.split('|'),
              selectedDay: _selectedDay,
              today: widget.today,
              onSelected: _selectDay,
            ),
            const SizedBox(height: 14),
            DecoratedBox(
              decoration: BoxDecoration(
                border: Border(top: BorderSide(color: scheme.outlineVariant)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  _sideMargin,
                  18,
                  _sideMargin,
                  16,
                ),
                child: _TimeRow(
                  title: l10n.startTimeSheetTime,
                  subtitle: l10n.startTimeSheetClock24,
                  hour: _hour,
                  minute: _minute,
                  onHourStep: _stepHour,
                  onMinuteStep: _stepMinute,
                  labels: (
                    hourUp: l10n.startTimeSheetHourUp,
                    hourDown: l10n.startTimeSheetHourDown,
                    minuteUp: l10n.startTimeSheetMinuteUp,
                    minuteDown: l10n.startTimeSheetMinuteDown,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                _sideMargin,
                0,
                _sideMargin,
                16,
              ),
              child: _ActionButtons(
                clearLabel: l10n.startTimeSheetClear,
                doneLabel: l10n.startTimeSheetDone,
                onClear: () => Navigator.of(
                  context,
                ).pop<StartTimeChoice>((localStart: null)),
                onDone: () => Navigator.of(
                  context,
                ).pop<StartTimeChoice>((localStart: _selected)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A hónap-sor felirata: „2026. OKTÓBER".
String _monthLabel(AppLocalizations l10n, DateTime month) {
  final name = l10n.startTimeSheetMonths.split('|')[month.month - 1];
  return l10n.startTimeSheetMonth(month.year, name).toUpperCase();
}

/// A lap fejléce: a cím és az aktuális érték (33c).
class _Header extends StatelessWidget {
  const _Header({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(_sideMargin, 20, _sideMargin, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(title, style: screenTitleStyle),
            Text(
              value,
              style: numeralMicroStyle.copyWith(
                fontWeight: FontWeight.w500,
                color: scheme.onSecondaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A hónap-sor: felirat balra, két keretes léptető jobbra (33c).
class _MonthRow extends StatelessWidget {
  const _MonthRow({
    required this.label,
    required this.previousTooltip,
    required this.nextTooltip,
    required this.onStep,
  });

  final String label;
  final String previousTooltip;
  final String nextTooltip;
  final ValueChanged<int> onStep;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideMargin, 14, _sideMargin, 8),
      child: Row(
        spacing: 6,
        children: [
          Expanded(
            child: Text(
              label,
              style: numeralCaptionStyle.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.32,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
          _OutlinedIconCell(
            icon: Icons.chevron_left,
            tooltip: previousTooltip,
            onTap: () => onStep(-1),
          ),
          _OutlinedIconCell(
            icon: Icons.chevron_right,
            tooltip: nextTooltip,
            onTap: () => onStep(1),
          ),
        ],
      ),
    );
  }
}

/// Egy 40 × 36 dp-s keretes ikon-cella a hónap-sorban.
class _OutlinedIconCell extends StatelessWidget {
  const _OutlinedIconCell({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 36,
          decoration: BoxDecoration(border: Border.all(color: scheme.outline)),
          child: Icon(icon, size: 20, color: scheme.onSurface),
        ),
      ),
    );
  }
}

/// A naptár-rács: hét oszlop hétfővel kezdve, 40 dp-s cellák (33c).
class _CalendarGrid extends StatelessWidget {
  const _CalendarGrid({
    required this.month,
    required this.weekdays,
    required this.selectedDay,
    required this.today,
    required this.onSelected,
  });

  final DateTime month;
  final List<String> weekdays;
  final DateTime selectedDay;
  final DateTime today;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final days = monthGridDays(month.year, month.month);
    final rows = <List<int?>>[
      for (var start = 0; start < days.length; start += 7)
        [
          for (var column = 0; column < 7; column++)
            start + column < days.length ? days[start + column] : null,
        ],
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(_sideMargin, 4, _sideMargin, 0),
      child: Column(
        spacing: _gridGap,
        children: [
          Row(
            spacing: _gridGap,
            children: [
              for (final weekday in weekdays)
                Expanded(
                  child: SizedBox(
                    height: 26,
                    child: Center(
                      child: Text(
                        weekday,
                        style: railLabelStyle.copyWith(
                          fontSize: 10.5,
                          letterSpacing: 0.63,
                          color: tones.low,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          for (final row in rows)
            Row(
              spacing: _gridGap,
              children: [
                for (final day in row)
                  Expanded(
                    child: day == null
                        ? const SizedBox(height: _dayCellHeight)
                        : _DayCell(
                            date: DateTime(month.year, month.month, day),
                            isSelected: isSameLocalDay(
                              DateTime(month.year, month.month, day),
                              selectedDay,
                            ),
                            today: today,
                            onTap: () => onSelected(day),
                          ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Egy nap a naptárban: kiválasztva `primary`, ma keretes, múltban halk.
class _DayCell extends StatelessWidget {
  const _DayCell({
    required this.date,
    required this.isSelected,
    required this.today,
    required this.onTap,
  });

  final DateTime date;
  final bool isSelected;
  final DateTime today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final isToday = isSameLocalDay(date, today);
    final color = isSelected
        ? scheme.onPrimary
        : isBeforeLocalDay(date, today)
        ? tones.low
        : scheme.onSurface;

    return Material(
      color: isSelected ? scheme.primary : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: _dayCellHeight,
          alignment: Alignment.center,
          decoration: isToday && !isSelected
              ? BoxDecoration(border: Border.all(color: scheme.outline))
              : null,
          child: Text(
            '${date.day}',
            style: numeralMicroStyle.copyWith(
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ),
    );
  }
}

/// A léptetők akadálymentes feliratai.
typedef _StepperLabels = ({
  String hourUp,
  String hourDown,
  String minuteUp,
  String minuteDown,
});

/// Az „IDŐPONT · 24 órás" sor a két léptetővel (33c).
class _TimeRow extends StatelessWidget {
  const _TimeRow({
    required this.title,
    required this.subtitle,
    required this.hour,
    required this.minute,
    required this.onHourStep,
    required this.onMinuteStep,
    required this.labels,
  });

  final String title;
  final String subtitle;
  final int hour;
  final int minute;
  final ValueChanged<int> onHourStep;
  final ValueChanged<int> onMinuteStep;
  final _StepperLabels labels;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;

    return Row(
      spacing: 14,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: 5,
            children: [
              Text(
                title,
                style: numeralCaptionStyle.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.26,
                  color: scheme.onSurfaceVariant,
                ),
              ),
              Text(
                subtitle,
                style: supportTextStyle.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: tones.low,
                ),
              ),
            ],
          ),
        ),
        _Stepper(
          value: hour,
          onStep: onHourStep,
          upLabel: labels.hourUp,
          downLabel: labels.hourDown,
        ),
        Text(
          ':',
          style: instrumentClockStyle.copyWith(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: tones.low,
          ),
        ),
        _Stepper(
          value: minute,
          onStep: onMinuteStep,
          upLabel: labels.minuteUp,
          downLabel: labels.minuteDown,
        ),
      ],
    );
  }
}

/// Egy kétjegyű léptető: fel-nyíl, érték, le-nyíl (33c).
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.value,
    required this.onStep,
    required this.upLabel,
    required this.downLabel,
  });

  final int value;
  final ValueChanged<int> onStep;
  final String upLabel;
  final String downLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final line = BorderSide(color: scheme.outlineVariant);

    return Container(
      width: _stepperWidth,
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        border: Border.all(color: scheme.outline),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _RepeatingStepButton(
            icon: Icons.keyboard_arrow_up,
            semanticLabel: upLabel,
            border: Border(bottom: line),
            onStep: () => onStep(1),
          ),
          SizedBox(
            height: _stepperValueHeight,
            child: Center(
              child: Text(
                value.toString().padLeft(2, '0'),
                style: instrumentClockStyle.copyWith(
                  fontSize: 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.6,
                  color: scheme.onSurface,
                ),
              ),
            ),
          ),
          _RepeatingStepButton(
            icon: Icons.keyboard_arrow_down,
            semanticLabel: downLabel,
            border: Border(top: line),
            onStep: () => onStep(-1),
          ),
        ],
      ),
    );
  }
}

/// Egy nyíl-cella, ami koppintásra egyet lép, hosszú nyomásra ismétel.
///
/// Az ismétlés az első [_repeatsBeforeFast] lépés után gyorsul, hogy a
/// percet ne kelljen ötvenszer megérinteni (33c, javaslat).
class _RepeatingStepButton extends StatefulWidget {
  const _RepeatingStepButton({
    required this.icon,
    required this.semanticLabel,
    required this.border,
    required this.onStep,
  });

  final IconData icon;
  final String semanticLabel;
  final Border border;
  final VoidCallback onStep;

  @override
  State<_RepeatingStepButton> createState() => _RepeatingStepButtonState();
}

class _RepeatingStepButtonState extends State<_RepeatingStepButton> {
  Timer? _timer;
  int _repeats = 0;

  void _startRepeat() {
    _repeats = 0;
    widget.onStep();
    _schedule(_repeatInterval);
  }

  void _schedule(Duration interval) {
    _timer?.cancel();
    _timer = Timer.periodic(interval, (_) {
      widget.onStep();
      _repeats++;
      if (_repeats == _repeatsBeforeFast) _schedule(_fastRepeatInterval);
    });
  }

  void _stopRepeat() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _stopRepeat();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Semantics(
      button: true,
      label: widget.semanticLabel,
      onTap: widget.onStep,
      child: GestureDetector(
        // A koppintást a fenti Semantics hirdeti, egyszer.
        excludeFromSemantics: true,
        behavior: HitTestBehavior.opaque,
        onTap: widget.onStep,
        onLongPressStart: (_) => _startRepeat(),
        onLongPressEnd: (_) => _stopRepeat(),
        onLongPressCancel: _stopRepeat,
        child: Container(
          height: _stepperArrowHeight,
          decoration: BoxDecoration(border: widget.border),
          child: Center(
            child: Icon(widget.icon, size: 20, color: scheme.onSurfaceVariant),
          ),
        ),
      ),
    );
  }
}

/// A két alsó gomb: „Nincs rajtidő" (keretes) és „Kész" (`primary`).
class _ActionButtons extends StatelessWidget {
  const _ActionButtons({
    required this.clearLabel,
    required this.doneLabel,
    required this.onClear,
    required this.onDone,
  });

  final String clearLabel;
  final String doneLabel;
  final VoidCallback onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = supportTextStyle.copyWith(fontSize: 14);

    return Row(
      spacing: 10,
      children: [
        Expanded(
          child: SizedBox(
            height: _buttonHeight,
            child: OutlinedButton(
              onPressed: onClear,
              style: OutlinedButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                side: BorderSide(color: scheme.outline),
                foregroundColor: scheme.onSurface,
                textStyle: labelStyle.copyWith(fontWeight: FontWeight.w600),
              ),
              child: Text(clearLabel),
            ),
          ),
        ),
        Expanded(
          child: SizedBox(
            height: _buttonHeight,
            child: FilledButton(
              onPressed: onDone,
              style: FilledButton.styleFrom(
                shape: const RoundedRectangleBorder(),
                textStyle: labelStyle.copyWith(fontWeight: FontWeight.w700),
              ),
              child: Text(doneLabel),
            ),
          ),
        ),
      ],
    );
  }
}
