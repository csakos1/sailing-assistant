import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';

/// A belépő képernyő halk, aláhúzott linkje (17a, 17c, 17e): „Belépés
/// jelszóval vagy helyreállító kóddal", „Vissza a QR-kódhoz".
///
/// `TextButton`, hogy billentyűzettel is elérhető legyen; hoverre és
/// fókuszra világosabb, háttér-kiemelés nélkül.
///
/// A `TextTones` biztonságos: a `foretackTheme` regisztrálja.
class SignInLink extends StatelessWidget {
  /// Link a [label] felirattal.
  const SignInLink({required this.label, required this.onPressed, super.key});

  /// A felirat.
  final String label;

  /// A kattintás.
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final low = Theme.of(context).extension<TextTones>()!.low;
    return TextButton(
      onPressed: onPressed,
      style: ButtonStyle(
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) =>
              states.contains(WidgetState.hovered) ||
                  states.contains(WidgetState.focused)
              ? scheme.onSurfaceVariant
              : low,
        ),
        overlayColor: const WidgetStatePropertyAll(Colors.transparent),
        textStyle: WidgetStatePropertyAll(
          supportTextStyle.copyWith(
            fontWeight: FontWeight.w400,
            decoration: TextDecoration.underline,
            decorationColor: scheme.outline,
          ),
        ),
      ),
      child: Text(label),
    );
  }
}
