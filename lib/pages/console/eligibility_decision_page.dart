import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/eligibility.dart';
import '../../models/register_record.dart';
import '../../providers/claim_providers.dart';
import '../../providers/officer_providers.dart';
import '../../providers/rail_counts_provider.dart';
import '../../providers/staff_provider.dart';
import '../../providers/use_case_providers.dart';
import '../../use-cases/uc_02_verify_section_33_eligibility.dart';
import '../../widgets/console/console_card.dart';
import '../../widgets/console/console_scaffolds.dart';
import '../../widgets/console/decision_card.dart';
import '../../widgets/console/document_row.dart';
import '../../widgets/shared/async_value_view.dart';
import '../../widgets/shared/claim_status_badge.dart';
import '../../widgets/shared/detail_row.dart';
import '../../widgets/shared/empty_state.dart';
import '../../widgets/shared/formats.dart';
import '../../widgets/shared/notice_banner.dart';

/// D2 · Officer — eligibility decision (UC-02 → UC-03).
///
/// The left column carries the evidence. The right column carries the
/// decision. BR-06 demands a written reason when the officer disagrees with
/// the automatic result.
class EligibilityDecisionPage extends ConsumerStatefulWidget {
  const EligibilityDecisionPage({super.key, required this.claimNumber});

  final String claimNumber;

  @override
  ConsumerState<EligibilityDecisionPage> createState() =>
      _EligibilityDecisionPageState();
}

class _EligibilityDecisionPageState
    extends ConsumerState<EligibilityDecisionPage> {
  final TextEditingController _reason = TextEditingController();
  EligibilityResult? _choice;
  bool _busy = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Claim?> claim = ref.watch(
      claimProvider(widget.claimNumber),
    );
    final AsyncValue<List<VerificationRow>> rows = ref.watch(
      verificationRowsProvider,
    );

    return ConsoleScreen(
      title: widget.claimNumber,
      subtitle: 'Verification · Section 33 decision',
      body: AsyncValueView<Claim?>(
        value: claim,
        onRetry: () => ref.invalidate(claimProvider(widget.claimNumber)),
        builder: (Claim? found) {
          if (found == null) {
            return EmptyState(
              icon: Icons.search_off,
              title: 'No claim carries the number ${widget.claimNumber}',
            );
          }

          VerificationRow? row;
          for (final VerificationRow candidate in rows.value ?? const []) {
            if (candidate.claim.claimNumber == widget.claimNumber) {
              row = candidate;
            }
          }

          final RegisterRecord record =
              row?.record ?? const RegisterRecord(available: true);
          final EligibilityResult automatic =
              row?.automatic ?? EligibilityResult.needsReview;
          _choice ??= automatic;

          return DetailBody(
            breadcrumb: <String>['Verification', found.claimNumber],
            onBack: () => context.go('/officer/verification'),
            context_: <Widget>[
              _claimSummary(found, row),
              _documents(found),
              const NoticeBanner(
                text:
                    'The claimant sees every state change in the '
                    'application. Nothing here is relayed by telephone.',
                icon: Icons.notifications_active_outlined,
              ),
            ],
            action: <Widget>[
              _eligibility(found, record, automatic),
              const NoticeBanner(
                text:
                    'A verified result is stored on the claim and used again '
                    'for its whole life. It is not checked again later '
                    '(BR-05).',
                icon: Icons.lock_outline,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _claimSummary(Claim claim, VerificationRow? row) {
    return ConsoleCard(
      title: 'Claim summary',
      trailing: ClaimStatusBadge(label: claim.status.label),
      children: <Widget>[
        FactGrid(
          cells: <FactCell>[
            FactCell(
              label: 'National ID',
              value: row?.person?.maskedNationalId ?? '—',
            ),
            FactCell(label: 'Employer on claim', value: claim.injury.employer),
            FactCell(
              label: 'Date of injury',
              value: claim.injury.date == null
                  ? '—'
                  : '${Formats.shortDate(claim.injury.date!)} · '
                        '${claim.injury.time ?? ''}',
            ),
            FactCell(label: 'Place', value: claim.injury.place),
            FactCell(label: 'Cause', value: claim.injury.cause),
            FactCell(label: 'Part of body', value: claim.injury.bodyPart),
          ],
        ),
      ],
    );
  }

  Widget _documents(Claim claim) {
    return ConsoleCard(
      title: 'Documents lodged with the claim',
      children: <Widget>[
        for (int i = 0; i < claim.documents.length; i++)
          DocumentRow(
            document: claim.documents[i],
            isLast: i == claim.documents.length - 1,
            onView: () => _sayLater(context),
          ),
      ],
    );
  }

  Widget _eligibility(
    Claim claim,
    RegisterRecord record,
    EligibilityResult automatic,
  ) {
    final ThemeData theme = Theme.of(context);

    return ConsoleCard(
      title: 'Section 33 eligibility',
      trailing: ClaimStatusBadge(
        label: automatic.label,
        tone: switch (automatic) {
          EligibilityResult.covered => BadgeTone.good,
          EligibilityResult.needsReview => BadgeTone.action,
          EligibilityResult.notCovered => BadgeTone.bad,
        },
      ),
      showDivider: false,
      children: <Widget>[
        Text(
          record.available
              ? 'Automatic result from the SSO insured register'
              : 'The register did not answer. The check is queued again.',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 14),
        DetailRow(
          icon: Icons.history,
          label: 'Contribution period',
          detail: record.coverSummary,
        ),
        DetailRow(
          icon: Icons.business_outlined,
          label: 'Employer in register',
          detail: record.employerInRegister.isEmpty
              ? 'Not found'
              : '${record.employerInRegister} · '
                    '${record.employerInRegister == claim.injury.employer ? 'matches the claim' : 'differs from the claim'}',
        ),
        DetailRow(
          icon: Icons.schedule,
          label: 'Register queried',
          detail: record.queriedAt == null
              ? 'Not yet'
              : '${Formats.dateAndTime(record.queriedAt!)} · response '
                    '${(record.responseTime.inMilliseconds / 1000).toStringAsFixed(1)} s',
          dense: true,
        ),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 14),
          child: Divider(height: 1),
        ),
        DecisionCard<EligibilityResult>(
          heading: 'Officer decision',
          busy: _busy,
          selected: _choice ?? automatic,
          onChanged: (EligibilityResult value) =>
              setState(() => _choice = value),
          options: const <DecisionOption<EligibilityResult>>[
            DecisionOption<EligibilityResult>(
              value: EligibilityResult.covered,
              label: 'Confirm — covered under Section 33',
              detail: 'Releases the claim to scheduling (UC-04)',
            ),
            DecisionOption<EligibilityResult>(
              value: EligibilityResult.notCovered,
              label: 'Not covered',
              detail: 'Rejects the claim and notifies the claimant (UC-03)',
            ),
            DecisionOption<EligibilityResult>(
              value: EligibilityResult.needsReview,
              label: 'Needs review',
              detail: 'Request further evidence and hold the claim',
            ),
          ],
          reasonController: _reason,
          reasonLabel: 'Override reason',
          reasonHelper:
              'Required only if you disagree with the automatic result '
              '(BR-06)',
          primaryLabel: 'Confirm result',
          onPrimary: () => _confirm(claim, record, automatic),
          dangerLabel: 'Reject claim',
          onDanger: () => _confirm(
            claim,
            record,
            automatic,
            force: EligibilityResult.notCovered,
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    Claim claim,
    RegisterRecord record,
    EligibilityResult automatic, {
    EligibilityResult? force,
  }) async {
    setState(() => _busy = true);
    try {
      final VerificationResult result = await ref
          .read(verifyEligibilityProvider)
          .confirm(
            claim: claim,
            result: force ?? _choice ?? automatic,
            automaticResult: automatic,
            officerName: ref.read(currentStaffProvider).name,
            record: record,
            overrideReason: _reason.text.trim().isEmpty
                ? null
                : _reason.text.trim(),
          );

      if (!mounted) {
        return;
      }
      _refresh();

      switch (result) {
        case EligibilityVerified(claim: final Claim verified):
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Claim ${verified.claimNumber} is '
                '${verified.status.label.toLowerCase()}.',
              ),
            ),
          );
          context.go('/officer/verification');
        case OverrideNeedsReason():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('An override must carry a written reason (BR-06).'),
            ),
          );
        case RegisterUnavailable():
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'The register did not answer. The check stays queued.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() => _busy = false);
      }
    }
  }

  void _refresh() {
    ref.invalidate(verificationRowsProvider);
    ref.invalidate(verificationWorklistProvider);
    ref.invalidate(verificationCountsProvider);
    ref.invalidate(schedulingWorklistProvider);
    ref.invalidate(railCountsProvider);
    ref.invalidate(claimProvider(widget.claimNumber));
  }

  static void _sayLater(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A document viewer arrives later.')),
    );
  }
}
