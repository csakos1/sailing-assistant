import 'package:flutter/material.dart';

/// A webes hozzáférés képernyőinek alsó gombsávja: felül hairline, a
/// gombok teljes szélességben (makett 18f, 18g).
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
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: Row(
            spacing: 8,
            children: [for (final child in children) Expanded(child: child)],
          ),
        ),
      ),
    );
  }
}
