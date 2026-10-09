import 'package:flutter/material.dart';

/// A webes hozzáférés képernyőinek alsó gombsávja: felül hairline, a
/// gombok egyenlő szélességben, 20 px-es margón belül, köztük 10 px
/// (makett 18e, 18e-2, 18f, 18g).
class WebBottomBar extends StatelessWidget {
  /// Sáv a [children] gombokkal, egyenlő szélességben.
  const WebBottomBar({required this.children, super.key});

  /// A gombok, balról jobbra.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      // Alul a makett 20 px-e, vagy a rendszer-sáv, ha az nagyobb.
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Row(
          spacing: 10,
          children: [for (final child in children) Expanded(child: child)],
        ),
      ),
    );
  }
}
