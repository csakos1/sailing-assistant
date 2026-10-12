import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/race_setup/widgets/form_card.dart';

/// A „+ Rajthely hozzáadása" sor magassága (33b).
const double _titleHeight = 48;

/// Az alsó két út cellájának magassága (33b).
const double _pathHeight = 44;

/// A szaggatott vonal szakasza és rése.
const double _dashLength = 4;
const double _dashGap = 3;

/// Az üres rajthely helye (33b): egy átlátszó kártya a „+ Rajthely
/// hozzáadása" sorral, alatta szaggatott vonallal két egyenlő út:
/// „Korábbi bóják" (a 35c lap) és „Koordináta" (üres mezők).
///
/// A szaggatás jelzi, hogy ez még nem tartalom, csak hely: a kitöltött
/// rajthely ugyanazt a kártyát kapja, mint a bóják (33a).
class StartPointEmptyCard extends StatelessWidget {
  /// Az üres hely a két úttal.
  const StartPointEmptyCard({
    required this.title,
    required this.libraryLabel,
    required this.coordinatesLabel,
    required this.onPickFromLibrary,
    required this.onEnterCoordinates,
    super.key,
  });

  /// A felső sor felirata („Rajthely hozzáadása").
  final String title;

  /// A könyvtár-út felirata („Korábbi bóják").
  final String libraryLabel;

  /// A koordináta-út felirata („Koordináta").
  final String coordinatesLabel;

  /// A 35c lap megnyitása.
  final VoidCallback onPickFromLibrary;

  /// Üres név- és koordináta-mezők megjelenítése.
  final VoidCallback onEnterCoordinates;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return FormCard(
      isTransparent: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: _titleHeight,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                spacing: 12,
                children: [
                  Icon(Icons.add, size: 18, color: scheme.onSurfaceVariant),
                  Expanded(
                    child: Text(
                      title,
                      style: supportTextStyle.copyWith(
                        fontSize: 15,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          CustomPaint(
            painter: _DashedLinePainter(
              color: scheme.outline,
              axis: Axis.horizontal,
            ),
            child: const SizedBox(height: 1, width: double.infinity),
          ),
          SizedBox(
            height: _pathHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: _PathCell(
                    icon: Icons.history,
                    label: libraryLabel,
                    onTap: onPickFromLibrary,
                  ),
                ),
                CustomPaint(
                  painter: _DashedLinePainter(
                    color: scheme.outline,
                    axis: Axis.vertical,
                  ),
                  child: const SizedBox(width: 1),
                ),
                Expanded(
                  child: _PathCell(
                    icon: Icons.edit_location_alt_outlined,
                    label: coordinatesLabel,
                    onTap: onEnterCoordinates,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Az egyik út cellája: ikon + felirat, középre zárva.
class _PathCell extends StatelessWidget {
  const _PathCell({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        spacing: 8,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: supportTextStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Egy 1 dp-s szaggatott vonal a vászon közepén, a megadott tengelyen.
class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color, required this.axis});

  final Color color;
  final Axis axis;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1;
    final length = axis == Axis.horizontal ? size.width : size.height;
    for (var start = 0.0; start < length; start += _dashLength + _dashGap) {
      final end = (start + _dashLength).clamp(0, length).toDouble();
      final (from, to) = axis == Axis.horizontal
          ? (Offset(start, 0.5), Offset(end, 0.5))
          : (Offset(0.5, start), Offset(0.5, end));
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedLinePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.axis != axis;
}
