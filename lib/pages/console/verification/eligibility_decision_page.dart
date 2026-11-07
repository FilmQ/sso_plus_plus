import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/verification_api.dart';
import '../../../l10n/tr.dart';
import '../../../session/session_providers.dart';
import '../scheduling/scheduling_providers.dart';
import '../shell/console_shell.dart';
import 'claim_cards.dart';
import 'confirm_result_dialog.dart';
import 'decision_form.dart';
import 'document_dialog.dart';
import 'eligibility_panel.dart';
import 'verification_providers.dart';

/// O1-2 Eligibility Decision Page (SA report figures 2-56 to 2-69): O1 step 4
/// to 6, O2 and O3.
class EligibilityDecisionPage extends ConsumerStatefulWidget {
  const EligibilityDecisionPage({super.key, required this.claimId});

  final int claimId;

  @override
  ConsumerState<EligibilityDecisionPage> createState() => _EligibilityDecisionPageState();
}

class _EligibilityDecisionPageState extends ConsumerState<EligibilityDecisionPage> {
  final Decision _decision = Decision();
  Map<String, Object?> _errors = const <String, Object?>{};
  Map<String, Object?>? _saved; // claim_status, decided_at, reason
  bool _busy = false;

  VerificationApi get _api => ref.read(verificationApiProvider);

  @override
  void dispose() {
    _decision.dispose();
    super.dispose();
  }

  /// O1 step 5: "View" opens the file (O1-3).
  void clickView(Map<String, Object?> document) =>
      showDocumentDialog(context, document, () => _api.openFile(widget.claimId, '${document['file_name']}'));

  /// O2 and O3 steps 3 to 6: the confirmation card, then QO2.1 and QN.1, or
  /// QO3.1, QO3.2 and QN.2.
  Future<void> confirmResult(Map<String, Object?> summary) async {
    final bool covered = _decision.result == 'Covered';
    final String? reason = covered ? null : _reason(_decision.reasonCode);
    final String name = '${summary['user_name']}';
    final bool? ok = await showConfirmResultDialog(context,
        claim: '${summary['claim_no']} · $name', covered: covered, reason: reason);
    if (ok != true || !mounted) return; // Alternate Case 1 [Cancel]
    setState(() => _busy = true);
    try {
      String? text(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
      final Map<String, Object?> r = covered
          ? await _api.confirmResult(widget.claimId, overrideReason: text(_decision.overrideReason))
          : await _api.rejectApplication(widget.claimId,
              reasonCode: _decision.reasonCode!,
              officerMessage: text(_decision.message),
              overrideReason: text(_decision.overrideReason));
      setState(() => _saved = <String, Object?>{...r, 'reason_code': covered ? null : _decision.reasonCode});
      ref.invalidate(verificationListProvider);
      ref.invalidate(claimsToScheduleProvider); // O2: the claim moves to scheduling
      _snack(
          covered
              ? 'Result saved. {name} has been notified.'
              : 'Claim rejected. {name} has been sent the reason and your message.',
          <String, Object?>{'name': name});
    } on ApiException catch (e) {
      setState(() => _errors = (e.body['fields'] as Map<String, Object?>?) ?? const <String, Object?>{});
      if (_errors.isEmpty) _snack(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _snack(String text, [Map<String, Object?> args = const <String, Object?>{}]) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(consoleSnackBar(context.tr(text, args)));
  }

  /// The label of a rejection reason code (QO1.6) in the language of the app, or null.
  String? _reason(Object? code) => (ref.read(rejectionReasonsProvider).value ?? const <Map<String, Object?>>[])
      .where((Map<String, Object?> r) => r['reason_code'] == code)
      .map((Map<String, Object?> r) => DecisionForm.reasonLabel(context, r))
      .firstOrNull;

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<String, Object?>> detail = ref.watch(claimDetailProvider(widget.claimId));
    final Map<String, Object?>? summary = detail.value?['summary'] as Map<String, Object?>?;
    return ConsolePage(
      title: summary == null ? 'Claim' : '${summary['claim_no']} · ${summary['user_name']}',
      subtitle: summary == null
          ? 'Verification'
          : context.tr('Verification · submitted {date}', <String, Object?>{'date': summary['submitted_date']}),
      onBack: () => context.go('/verification'),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (Object e, _) => Center(child: Text(context.tr(e is ApiException ? e.message : 'The claim cannot be shown now.'))),
        data: (Map<String, Object?> d) => _body(d),
      ),
    );
  }

  Widget _body(Map<String, Object?> d) {
    final Map<String, Object?> summary = d['summary']! as Map<String, Object?>;
    final List<Map<String, Object?>> documents = (d['documents']! as List<Object?>).cast<Map<String, Object?>>();
    // QO1.3 has no status: take it from the QO1.1 row of the claim.
    final List<Object?> pending =
        (ref.watch(verificationListProvider).value?['claims'] as List<Object?>?) ?? const <Object?>[];
    final Object? listed = pending
        .cast<Map<String, Object?>>()
        .where((Map<String, Object?> c) => c['claim_id'] == widget.claimId)
        .map((Map<String, Object?> c) => c['verification_status'])
        .firstOrNull;
    final Widget left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ClaimSummaryCard(summary: summary, status: (_saved?['claim_status'] ?? listed) as String?),
      DocumentsCard(documents: documents, onView: clickView),
      const UserIsToldNote(),
    ]);
    final Widget right = EligibilityPanel(
        eligibility: d['eligibility'] as Map<String, Object?>?, decision: _decisionPart(summary));
    return LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
      final bool wide = box.maxWidth >= 1000;
      return ListView(padding: const EdgeInsets.all(24), children: <Widget>[
        if (wide)
          Row(crossAxisAlignment: CrossAxisAlignment.start, spacing: 24, children: <Widget>[
            Expanded(flex: 7, child: left),
            Expanded(flex: 4, child: right),
          ])
        else
          Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[left, right]),
      ]);
    });
  }

  Widget _decisionPart(Map<String, Object?> summary) {
    final Map<String, Object?>? saved = _saved;
    if (saved != null) {
      final bool covered = saved['claim_status'] == 'Covered';
      return Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 12, children: <Widget>[
        DecisionResult(
          covered: covered,
          by: ref.read(sessionProvider).value?.displayName ?? '',
          at: '${saved['decided_at']}',
          reason: _reason(saved['reason_code']),
        ),
        if (covered)
          FilledButton.tonalIcon(
            onPressed: () => context.go('/scheduling'),
            icon: const Icon(Icons.calendar_month),
            label: Text(context.tr('Go to Scheduling')),
          ),
      ]);
    }
    return DecisionForm(
      decision: _decision,
      reasons: ref.watch(rejectionReasonsProvider).value ?? const <Map<String, Object?>>[],
      errors: _errors,
      busy: _busy,
      onChanged: () => setState(() => _errors = const <String, Object?>{}),
      onConfirmResult: () => confirmResult(summary),
    );
  }
}
