import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:foretack_web/app/web_layout.dart';

/// A snackbar margója egy [screenWidth] széles ablakban (ADR 0048
/// Addendum 1 G5, Addendum 4 K17).
///
/// A bal széle a 880 px-es oszlop bal betétéhez igazodik, a szélessége
/// 480 px; keskeny ablakban az oszlop jobb betétéig zsugorodik.
EdgeInsets webSnackBarMargin(double screenWidth) {
  final column = math.min(screenWidth, WebLayout.columnMaxWidth);
  final left = (screenWidth - column) / 2 + WebLayout.columnInset;
  final right = math.max(
    screenWidth - left - WebLayout.snackBarWidth,
    WebLayout.columnInset,
  );
  return EdgeInsets.fromLTRB(left, 0, right, WebLayout.snackBarBottomGap);
}

/// A [message] snackbarként, akció nélkül, 4 másodpercre (K17).
///
/// A [messenger]-t és a [screenWidth]-et a hívó a navigáció **előtt**
/// olvassa ki, mert a snackbar gyakran egy bezáruló képernyőről indul, és a
/// gyökér `ScaffoldMessenger` a következő képernyőn is mutatja.
void showWebSnackBar(
  ScaffoldMessengerState messenger, {
  required String message,
  required double screenWidth,
}) {
  final scheme = Theme.of(messenger.context).colorScheme;
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: webSnackBarMargin(screenWidth),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        backgroundColor: scheme.surfaceContainerHigh,
        elevation: 0,
        shape: RoundedRectangleBorder(side: BorderSide(color: scheme.outline)),
        content: SizedBox(
          height: 50,
          child: Row(
            children: [
              // A 11b státusznégyzete: semleges, mert a snackbar itt csak
              // nyugtáz.
              SizedBox.square(
                dimension: 8,
                child: ColoredBox(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: supportTextStyle.copyWith(
                    fontSize: 14,
                    color: scheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}
