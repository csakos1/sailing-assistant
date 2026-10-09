import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/application/management_problem.dart';
import 'package:phone/features/web_access/application/web_access_error.dart';
import 'package:phone/features/web_access/application/web_access_providers.dart';
import 'package:phone/features/web_access/data/web_account.dart';
import 'package:phone/features/web_access/presentation/crew_screen.dart';
import 'package:phone/features/web_access/presentation/management_feedback.dart';
import 'package:phone/features/web_access/presentation/recovery_codes_screen.dart';
import 'package:phone/features/web_access/presentation/web_access_prompts.dart';
import 'package:phone/features/web_access/presentation/web_sessions_screen.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_detail_row.dart';
import 'package:phone/features/web_access/presentation/widgets/web_link_row.dart';
import 'package:phone/features/web_access/presentation/widgets/web_load_problem.dart';
import 'package:phone/features/web_access/presentation/widgets/web_section_header.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:phone/providers/clock_provider.dart';
import 'package:race_archive_api/race_archive_api.dart';
import 'package:shared/shared.dart';

/// A helyreállító kódok száma egy készletben (D6), a „/ 10" kiírásához.
const int recoveryCodesPerSet = 10;

/// A „Fiók és biztonság" képernyő az `owner`-nek, a „Fiók" a legénységnek
/// (ADR 0051 Addendum 1 H9, Addendum 10 Z11; makett 18l, 18l-2, 18l-3).
///
/// Mindenki átírhatja a saját nevét (M1). Az `owner` itt állítja a webes
/// jelszót és generál új helyreállító kódokat (ujjlenyomattal), és látja a
/// telefon nevét (csak kiírás, Z1). Alul linkek a „Webes belépések"-re és
/// (az `owner`-nél) a „Legénység"-re.
class WebAccountScreen extends ConsumerWidget {
  const WebAccountScreen({super.key});

  /// A képernyő megnyitása; a visszatérés után a hívó frissíti a szalagot.
  static Future<void> open(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const WebAccountScreen()));

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final account = ref.watch(webAccountProvider).valueOrNull;
    final isOwner = account?.account.role == UserRole.owner;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isOwner ? l10n.webAccountTitleOwner : l10n.webAccountTitleCrew,
          style: screenTitleStyle,
        ),
      ),
      body: account == null
          ? const SizedBox.shrink()
          : ListView(
              children: [
                WebSectionHeader(label: l10n.webAccountNameSection),
                _NameSection(account: account),
                if (isOwner) ...[
                  const _SecuritySections(),
                  WebSectionHeader(label: l10n.webAccountPhoneSection),
                  const _PhoneSection(),
                ],
                const SizedBox(height: 20),
                _Links(isOwner: isOwner),
              ],
            ),
    );
  }
}

/// Egy mező címkéje a csoport-fejléc alatt (makett: „NEVED", „ÚJ
/// JELSZÓ").
class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 8),
      child: Text(text, style: sectionLabelStyle.copyWith(color: tones.low)),
    );
  }
}

/// A saját név átírása (Z11): a „Mentés" csak egy eltérő, érvényes névnél
/// jelenik meg, mert egy elhagyáskor csendben mentő mező meglepetés
/// lenne.
class _NameSection extends ConsumerStatefulWidget {
  const _NameSection({required this.account});

  final WebAccount account;

  @override
  ConsumerState<_NameSection> createState() => _NameSectionState();
}

class _NameSectionState extends ConsumerState<_NameSection> {
  late final TextEditingController _name = TextEditingController(
    text: widget.account.account.name,
  );
  bool _isSaving = false;

  // Ha a név kívülről változik (a `/me` frissítése), a mező is követi,
  // hacsak a felhasználó közben át nem írta: különben a régi név „Mentés"-e
  // jelenne meg.
  @override
  void didUpdateWidget(_NameSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldName = oldWidget.account.account.name;
    final newName = widget.account.account.name;
    if (newName != oldName && _name.text.trim() == oldName) {
      _name.text = newName;
    }
  }

  String? get _changedName {
    final name = normalizeDisplayName(_name.text);
    return name == null || name == widget.account.account.name ? null : name;
  }

  Future<void> _save() async {
    final name = _changedName;
    final renamer = ref.read(accountRenamerProvider);
    if (_isSaving || name == null || renamer == null) return;
    setState(() => _isSaving = true);
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final saved = AppLocalizations.of(context)!.webAccountNameSaved;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final error = await renamer(name);
      if (!mounted) return;
      if (error == null) {
        _name.text = name;
        FocusScope.of(context).unfocus();
        messenger.showSnackBar(webDoneSnackBar(context, saved));
      } else {
        _reportError(context, ref, error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    final isInvalid =
        _name.text.trim().isNotEmpty &&
        normalizeDisplayName(_name.text) == null;
    final canSave = _changedName != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _FieldLabel(l10n.webAccountNameLabel),
          TextField(
            controller: _name,
            enabled: !_isSaving,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            inputFormatters: [LengthLimitingTextInputFormatter(60)],
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => unawaited(_save()),
          ),
          if (isInvalid)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                l10n.webJoinNameInvalid,
                style: supportTextStyle.copyWith(color: scheme.error),
              ),
            ),
          if (canSave || _isSaving) ...[
            const SizedBox(height: 12),
            WebActionButton.primary(
              label: l10n.webAccountNameSave,
              isBusy: _isSaving,
              onPressed: () => unawaited(_save()),
            ),
          ],
        ],
      ),
    );
  }
}

/// A jelszó- és a kódrész (csak `owner`): a betöltés vagy a hiba a
/// helyükön áll, a név és a linkek közben használhatók.
class _SecuritySections extends ConsumerWidget {
  const _SecuritySections();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final loaded = ref.watch(accountSecurityProvider);
    return switch (loaded) {
      AsyncValue(valueOrNull: Ok(:final value?)) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          WebSectionHeader(label: l10n.webAccountPasswordSection),
          _PasswordSection(security: value),
          WebSectionHeader(label: l10n.webAccountCodesSection),
          _CodesSection(security: value),
        ],
      ),
      // A legénységnek nincs tartaléka; ide csak az `owner` jut.
      AsyncValue(valueOrNull: Ok()) => const SizedBox.shrink(),
      AsyncValue(valueOrNull: Err(:final error)) => WebLoadProblem(
        problem: managementProblemOf(error) ?? const ActionFailed(),
        onRetry: () => ref.invalidate(accountSecurityProvider),
      ),
      // A betöltés hibája adatként jön; ez csak egy váratlan kivétel.
      AsyncError() => WebLoadProblem(
        problem: const ServerUnreachable(),
        onRetry: () => ref.invalidate(accountSecurityProvider),
      ),
      _ => const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator()),
      ),
    };
  }
}

/// A webes jelszó (makett 18l, H9): állapot-sor, mező a hossz-számlálóval,
/// „Jelszó mentése" ujjlenyomattal.
class _PasswordSection extends ConsumerStatefulWidget {
  const _PasswordSection({required this.security});

  final AccountSecurity security;

  @override
  ConsumerState<_PasswordSection> createState() => _PasswordSectionState();
}

class _PasswordSectionState extends ConsumerState<_PasswordSection> {
  final TextEditingController _password = TextEditingController();
  bool _isSaving = false;

  Future<void> _save() async {
    final password = _password.text;
    if (_isSaving || !isAcceptablePassword(password)) return;
    setState(() => _isSaving = true);
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final origin = ref.read(webAccountProvider).valueOrNull?.origin;
    if (origin == null) {
      setState(() => _isSaving = false);
      return;
    }
    try {
      final error = await ref
          .read(accountSecurityProvider.notifier)
          .setPassword(
            password,
            prompt: setPasswordPromptText(l10n, origin),
          );
      if (!mounted) return;
      if (error == null) {
        _password.clear();
        FocusScope.of(context).unfocus();
        messenger.showSnackBar(
          webDoneSnackBar(context, l10n.webAccountPasswordSaved),
        );
      } else {
        _reportError(context, ref, error);
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final now = ref.watch(clockProvider)();
    final setAt = widget.security.passwordSetAt;
    // A szabály kódpontban számol (J4), nem UTF-16 egységben.
    final length = _password.text.runes.length;
    final isTooLong = length > maximumPasswordLength;
    final quiet = supportTextStyle.copyWith(color: scheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            setAt == null
                ? l10n.webAccountPasswordNone
                : l10n.webAccountPasswordSetAt(
                    formatWebMoment(l10n, setAt, now),
                  ),
            style: quiet,
          ),
          _FieldLabel(l10n.webAccountPasswordLabel),
          TextField(
            controller: _password,
            enabled: !_isSaving,
            obscureText: true,
            autocorrect: false,
            enableSuggestions: false,
            autofillHints: const [AutofillHints.newPassword],
            textInputAction: TextInputAction.done,
            onChanged: (_) => setState(() {}),
            onSubmitted: (_) => unawaited(_save()),
          ),
          const SizedBox(height: 10),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Text(
                  isTooLong
                      ? l10n.webAccountPasswordTooLong
                      : l10n.webAccountPasswordRule,
                  style: isTooLong
                      ? supportTextStyle.copyWith(color: scheme.error)
                      : quiet,
                ),
              ),
              // A számláló a minimumig segít; fölötte már nincs mit
              // számolni.
              if (length < minimumPasswordLength)
                Text(
                  l10n.webAccountPasswordCount(length),
                  style: numeralCaptionStyle.copyWith(
                    fontSize: 12,
                    color: tones.low,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          WebActionButton.primary(
            label: l10n.webAccountPasswordSave,
            isBusy: _isSaving,
            onPressed: isAcceptablePassword(_password.text)
                ? () => unawaited(_save())
                : null,
          ),
        ],
      ),
    );
  }
}

/// A helyreállító kódok (makett 18l, 18l-3): a felhasználatlanok száma, a
/// készlet ideje (Z12), és az „Újragenerálás" megerősítéssel és
/// ujjlenyomattal; az új kódok a 18g képernyőn jelennek meg egyszer.
class _CodesSection extends ConsumerStatefulWidget {
  const _CodesSection({required this.security});

  final AccountSecurity security;

  @override
  ConsumerState<_CodesSection> createState() => _CodesSectionState();
}

class _CodesSectionState extends ConsumerState<_CodesSection> {
  bool _isBusy = false;

  Future<void> _regenerate() async {
    if (_isBusy) return;
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final isConfirmed = await showForetackDialog<bool>(
      context: context,
      title: l10n.webAccountCodesConfirmTitle,
      message: l10n.webAccountCodesConfirmMessage,
      actions: [
        ForetackDialogAction(label: l10n.webCrewCancel, value: false),
        ForetackDialogAction(
          label: l10n.webAccountCodesRegenerate,
          value: true,
          isDestructive: true,
        ),
      ],
    );
    if (isConfirmed != true || !mounted) return;
    setState(() => _isBusy = true);
    final navigator = Navigator.of(context);
    final origin = ref.read(webAccountProvider).valueOrNull?.origin;
    if (origin == null) {
      setState(() => _isBusy = false);
      return;
    }
    try {
      final result = await ref
          .read(accountSecurityProvider.notifier)
          .regenerateRecoveryCodes(
            prompt: regenerateCodesPromptText(l10n, origin),
          );
      if (!mounted) return;
      switch (result) {
        case Ok(value: final codes):
          // A kódok csak itt látszanak; a 18g „Elmentettem"-je ide hoz
          // vissza.
          await navigator.push(
            MaterialPageRoute<void>(
              builder: (_) => RecoveryCodesScreen(codes: codes),
            ),
          );
        case Err(:final error):
          _reportError(context, ref, error);
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final now = ref.watch(clockProvider)();
    final generatedAt = widget.security.recoveryCodesGeneratedAt;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 6),
          Row(
            spacing: 10,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 4,
                  children: [
                    Text(
                      l10n.webAccountCodesUnused,
                      style: supportTextStyle.copyWith(
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                    // Egy régebbi szerver nem adja meg (Z12): a sor elmarad.
                    if (generatedAt != null)
                      Text(
                        l10n.webAccountCodesGenerated(
                          formatWebMoment(l10n, generatedAt, now),
                        ),
                        style: numeralCaptionStyle.copyWith(
                          fontSize: 12,
                          color: tones.low,
                        ),
                      ),
                  ],
                ),
              ),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${widget.security.recoveryCodesLeft} ',
                      style: numeralSmallStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: scheme.onSurface,
                      ),
                    ),
                    TextSpan(
                      text: l10n.webAccountCodesTotal(recoveryCodesPerSet),
                      style: numeralMicroStyle.copyWith(
                        fontWeight: FontWeight.w700,
                        color: tones.low,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          WebActionButton.secondary(
            label: l10n.webAccountCodesRegenerate,
            isBusy: _isBusy,
            onPressed: () => unawaited(_regenerate()),
          ),
        ],
      ),
    );
  }
}

/// A telefon neve és típusa, csak kiírás (Z1): a név a regisztrációkor a
/// telefon modellje lett, és nincs végpont az átírására.
class _PhoneSection extends ConsumerWidget {
  const _PhoneSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final identity = ref.watch(deviceIdentityProvider).valueOrNull;
    if (identity == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          WebDetailRow(
            label: l10n.webAccountPhoneName,
            value: identity.deviceName,
          ),
          WebDetailRow(label: l10n.webAccountPhoneModel, value: identity.model),
        ],
      ),
    );
  }
}

/// A továbbvivő linkek a képernyő alján (makett 18l, 18l-2).
class _Links extends ConsumerWidget {
  const _Links({required this.isOwner});

  final bool isOwner;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A figyelés a listát is életben tartja: a 18i-ről visszatérve a szám
    // már a friss.
    final sessions = switch (ref.watch(webSessionsProvider).valueOrNull) {
      Ok(:final value) => value.length,
      _ => null,
    };
    final requests = ref.watch(
      webAccessStatusProvider.select(
        (status) => status.banner?.pendingJoinRequests ?? 0,
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: scheme.outlineVariant)),
      ),
      child: Column(
        children: [
          WebLinkRow(
            label: l10n.webAccountSessionsLink,
            value: sessions == null ? null : '$sessions',
            onTap: () => unawaited(WebSessionsScreen.open(context)),
          ),
          if (isOwner)
            WebLinkRow(
              label: l10n.webAccountCrewLink,
              value: requests > 0
                  ? l10n.webAccountCrewRequests(requests)
                  : null,
              onTap: () => unawaited(CrewScreen.open(context)),
            ),
        ],
      ),
    );
  }
}

// Egy gomb hibája snackbarral (Z3); a visszavont telefon a főképernyőn is
// jelzést kap (Z4).
void _reportError(BuildContext context, WidgetRef ref, WebAccessError error) {
  if (managementProblemOf(error) is PhoneRevoked) {
    ref.read(webAccessStatusProvider.notifier).markRevoked();
  }
  showManagementError(context, error);
}
