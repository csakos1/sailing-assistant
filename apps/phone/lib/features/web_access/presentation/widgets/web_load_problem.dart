import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/l10n/app_localizations.dart';

/// Egy kezelőképernyő betöltési hibája a képernyő (vagy egy szakasz)
/// helyén, „Újra" gombbal (ADR 0051 Addendum 10 Z3).
///
/// A visszavont telefonnak nincs „Újra": a főképernyő úgyis a visszavont
/// sort mutatja (Z4), és egy újrapróba ugyanide jutna.
class WebLoadProblem extends StatelessWidget {
  /// Hibasor a [problem]-mel; az [onRetry] újratölt.
  const WebLoadProblem({
    required this.problem,
    required this.onRetry,
    super.key,
  });

  /// A hiba leképezése.
  final ManagementProblem problem;

  /// Az újratöltés.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            managementProblemText(l10n, problem),
            style: supportTextStyle.copyWith(color: scheme.onSurfaceVariant),
          ),
          if (problem is! PhoneRevoked) ...[
            const SizedBox(height: 16),
            WebActionButton.secondary(
              label: l10n.webScanRetry,
              isCompact: true,
              onPressed: onRetry,
            ),
          ],
        ],
      ),
    );
  }
}
