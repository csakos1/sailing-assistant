import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy kamera-nézet, amely a beolvasott QR-szöveget az [onCode]-nak adja,
/// amíg [isActive] igaz.
typedef QrCameraBuilder =
    Widget Function({
      required bool isActive,
      required ValueChanged<String> onCode,
    });

/// A beolvasó kamerája; tesztben egy gombos hamis nézetre cserélhető,
/// mert a widget-tesztben nincs kamera.
final qrCameraBuilderProvider = Provider<QrCameraBuilder>(
  (ref) =>
      ({required isActive, required onCode}) =>
          QrCameraView(isActive: isActive, onCode: onCode),
);

/// A teljes képernyős kamera a `mobile_scanner`-rel (ADR 0051 Addendum 8
/// V1, V5; makett 18b).
///
/// Csak QR-t keres. Inaktívan a kép megáll (`pause`), és a találatokat
/// eldobja: így egy folyamat vagy egy hibapanel alatt nem jön második
/// kód. A megtagadott engedély és a kamera hibája egy halk sor +
/// „Újra" a kép helyén (V2).
class QrCameraView extends StatefulWidget {
  /// Kamera, amely az [onCode]-nak ad, amíg [isActive].
  const QrCameraView({required this.isActive, required this.onCode, super.key});

  /// Fogad-e most kódot.
  final bool isActive;

  /// A beolvasott QR szövege.
  final ValueChanged<String> onCode;

  @override
  State<QrCameraView> createState() => _QrCameraViewState();
}

class _QrCameraViewState extends State<QrCameraView> {
  final MobileScannerController _controller = MobileScannerController(
    formats: const [BarcodeFormat.qrCode],
    // Az alapértelmezett (`normal`) sebesség: a `noDuplicates` az „Újra"
    // után ugyanazt a kódot nem adná újra (pl. egy hálózati hiba után); a
    // második kódot az `isActive` szűri.
  );

  @override
  void didUpdateWidget(QrCameraView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive == widget.isActive) return;
    _ignoreControllerState(
      widget.isActive ? _controller.start() : _controller.pause(),
    );
  }

  @override
  void dispose() {
    unawaited(_controller.dispose());
    super.dispose();
  }

  // Egy még induló vagy már lezárt kontroller állapot-hibája nem gond: a
  // kamera hibáját a `MobileScanner` hibanézete mutatja.
  void _ignoreControllerState(Future<void> operation) => unawaited(
    operation.onError<MobileScannerException>((_, _) {}),
  );

  void _onDetect(BarcodeCapture capture) {
    if (!widget.isActive) return;
    for (final barcode in capture.barcodes) {
      final text = barcode.rawValue;
      if (text != null && text.isNotEmpty) {
        widget.onCode(text);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      onDetect: _onDetect,
      errorBuilder: (context, error) => _CameraError(
        isPermissionDenied:
            error.errorCode == MobileScannerErrorCode.permissionDenied,
        onRetry: () => _ignoreControllerState(_controller.start()),
      ),
    );
  }
}

class _CameraError extends StatelessWidget {
  const _CameraError({required this.isPermissionDenied, required this.onRetry});

  final bool isPermissionDenied;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return ColoredBox(
      color: scheme.surface,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            spacing: 16,
            children: [
              Text(
                isPermissionDenied
                    ? l10n.webScanCameraDenied
                    : l10n.webScanCameraFailed,
                textAlign: TextAlign.center,
                style: supportTextStyle.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              OutlinedButton(
                onPressed: onRetry,
                child: Text(l10n.webScanRetry),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
