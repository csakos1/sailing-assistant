import 'package:flutter/material.dart';
import 'package:foretack_ui/foretack_ui.dart';
import 'package:phone/features/web_access/presentation/web_time_format.dart';
import 'package:phone/features/web_access/presentation/widgets/web_action_button.dart';
import 'package:phone/features/web_access/presentation/widgets/web_bottom_bar.dart';
import 'package:phone/l10n/app_localizations.dart';
import 'package:race_archive_api/race_archive_api.dart';

/// A jóváhagyó lap választása: új tag (`memberId == null`), vagy egy
/// meglévő tag új telefonja.
typedef CrewApprovalChoice = ({String? memberId});

/// A jóváhagyó alsó lap megnyitása a [request] kérelemhez (ADR 0051
/// Addendum 10 Z11, makett 18k-2); a [crewMembers] a választható meglévő
/// tagok (Z2: az `owner` nem). `null`, ha a lapot elvetették.
///
/// A lap csak választ: a jóváhagyás ujjlenyomata már a „Legénység"
/// képernyőn fut, hogy egy hiba snackbarja ne a lap mögé kerüljön.
Future<CrewApprovalChoice?> showCrewApprovalSheet(
  BuildContext context, {
  required PendingJoinRequest request,
  required List<MemberInfo> crewMembers,
}) {
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<CrewApprovalChoice>(
    context: context,
    isScrollControlled: true,
    backgroundColor: scheme.surfaceContainerHigh,
    shape: Border(top: BorderSide(color: scheme.outline)),
    builder: (_) =>
        _CrewApprovalSheet(request: request, crewMembers: crewMembers),
  );
}

class _CrewApprovalSheet extends StatefulWidget {
  const _CrewApprovalSheet({required this.request, required this.crewMembers});

  final PendingJoinRequest request;
  final List<MemberInfo> crewMembers;

  @override
  State<_CrewApprovalSheet> createState() => _CrewApprovalSheetState();
}

class _CrewApprovalSheetState extends State<_CrewApprovalSheet> {
  // `null`: új tag (az alapértelmezés, Z11).
  String? _memberId;

  @override
  Widget build(BuildContext context) {
    // A `MaterialApp` regisztrálja a delegátorokat, ezért nem `null`.
    final l10n = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final request = widget.request;
    final subtitle = [
      request.deviceName,
      ?placeOf(city: request.city, country: request.country),
    ].join(' · ');
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outline)),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: 6,
              children: [
                Text(
                  l10n.webCrewApprovalTitle(request.name),
                  style: screenTitleStyle.copyWith(color: scheme.onSurface),
                ),
                Text(
                  subtitle,
                  style: numeralCaptionStyle.copyWith(
                    fontSize: 12,
                    color: tones.low,
                  ),
                ),
              ],
            ),
          ),
        ),
        Flexible(
          child: ListView(
            shrinkWrap: true,
            children: [
              _ChoiceRow(
                label: l10n.webCrewNewMember,
                isSelected: _memberId == null,
                onTap: () => setState(() => _memberId = null),
              ),
              for (final member in widget.crewMembers)
                _ChoiceRow(
                  key: ValueKey(member.account.userId),
                  label: l10n.webCrewMemberPhone(member.account.name),
                  detail: l10n.webCrewDeviceCount(member.devices.length),
                  isSelected: _memberId == member.account.userId,
                  onTap: () =>
                      setState(() => _memberId = member.account.userId),
                ),
            ],
          ),
        ),
        WebBottomBar(
          children: [
            WebActionButton.secondary(
              label: l10n.webCrewCancel,
              onPressed: () => Navigator.of(context).pop(),
            ),
            WebActionButton.primary(
              label: l10n.webCrewApprove,
              onPressed: () => Navigator.of(context).pop((memberId: _memberId)),
            ),
          ],
        ),
      ],
    );
  }
}

/// Egy választható sor: szögletes jelölő, felirat, halk eszközszám
/// (makett 18k-2).
class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.detail,
    super.key,
  });

  /// A sor magassága a makett szerint.
  static const double height = 57;

  final String label;
  final String? detail;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // A foretackTheme regisztrálja a TextTones-t → a fában mindig jelen van.
    final tones = Theme.of(context).extension<TextTones>()!;
    final shownDetail = detail;
    final markColor = isSelected ? scheme.primary : tones.low;
    return Semantics(
      selected: isSelected,
      inMutuallyExclusiveGroup: true,
      child: InkWell(
        onTap: onTap,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: scheme.outlineVariant)),
          ),
          child: SizedBox(
            height: height,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                spacing: 14,
                children: [
                  DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(color: markColor, width: 2),
                    ),
                    child: SizedBox.square(
                      dimension: 18,
                      child: isSelected
                          ? Center(
                              child: SizedBox.square(
                                dimension: 8,
                                child: ColoredBox(color: markColor),
                              ),
                            )
                          : null,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: supportTextStyle.copyWith(
                        fontSize: 15,
                        color: scheme.onSurface,
                      ),
                    ),
                  ),
                  if (shownDetail != null)
                    Text(
                      shownDetail,
                      style: numeralCaptionStyle.copyWith(
                        fontSize: 12,
                        color: tones.low,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
