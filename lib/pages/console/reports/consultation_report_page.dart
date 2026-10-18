import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../theme/status_colors.dart';
import '../../../widgets/status_chip.dart';
import '../shell/console_shell.dart';
import '../verification/claim_cards.dart';
import '../verification/document_dialog.dart';
import 'report_providers.dart';
import 'report_text_dialog.dart';
import 'view_status_chip.dart';

/// O6-2 Consultation Report Page (SA report figures 2-91 and 2-92): O6 steps
/// 2.1 to 4.
class ConsultationReportPage extends ConsumerStatefulWidget {
  const ConsultationReportPage({super.key, required this.reportId});

  final int reportId;

  @override
  ConsumerState<ConsultationReportPage> createState() => _ConsultationReportPageState();
}

class _ConsultationReportPageState extends ConsumerState<ConsultationReportPage> {
  /// The report after "View" (QO6.3 gives Viewed).
  Map<String, Object?>? _viewed;

  /// The file name of a report that is a file, or null for a text report.
  static String? fileName(Map<String, Object?> r) {
    final String? uri = r['report_file_uri'] as String?;
    return uri?.substring(uri.lastIndexOf('/') + 1);
  }

  /// O6 steps 3 to 4: QO6.3, then the report text (4.1, O6-3) or the report
  /// file (4.2, Alternate Case 1 [File]).
  Future<void> clickView() async {
    try {
      final Map<String, Object?> r = await ref.read(reportApiProvider).viewReport(widget.reportId);
      if (!mounted) return;
      setState(() => _viewed = r);
      ref.invalidate(reportListProvider);
      final String? file = fileName(r);
      if (file == null) {
        await showReportTextDialog(context, r);
      } else {
        await showDocumentDialog(context, <String, Object?>{'file_name': file, 'file_size': 'Report file'},
            () => ref.read(reportApiProvider).openReportFile(widget.reportId));
      }
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(consoleSnackBar(e.message));
    }
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<Map<String, Object?>> page = ref.watch(reportProvider(widget.reportId));
    final Map<String, Object?>? r = _viewed ?? page.value;
    return ConsolePage(
      title: r == null ? 'Consultation Report' : 'Consultation Report · ${r['claim_no']}',
      subtitle: r == null ? '' : '${r['user_name']} · signed ${r['signed_date']} · version ${r['version_no']}',
      onBack: () => context.go('/reports'),
      body: r != null
          ? _body(r)
          : page.hasError
              ? Center(child: Text(page.error is ApiException ? (page.error! as ApiException).message : 'Error'))
              : const Center(child: CircularProgressIndicator()),
    );
  }

  Widget _body(Map<String, Object?> r) {
    final ColorScheme colors = Theme.of(context).colorScheme;
    final StatusColors s = StatusColors.of(context);
    final bool signed = r['signature_status'] == 'Signature signed';
    final bool viewed = r['view_status'] == 'Viewed';
    final List<(String, String)> fields = <(String, String)>[
      ('User', '${r['user_name']}'),
      ('Age', '${r['user_age']}'),
      ('Consultation date and time', '${r['consultation_datetime']}'),
      ('Report submitted', '${r['submitted_date']}'),
      ('Consultant', '${r['consultant_name']}'),
    ];
    final Widget left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ConsoleCard(title: 'Patient details', children: <Widget>[
        LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
          final double width = box.maxWidth >= 480 ? (box.maxWidth - 32) / 3 : box.maxWidth;
          return Wrap(spacing: 16, runSpacing: 16, children: <Widget>[
            for (final (String label, String value) in fields) SizedBox(width: width, child: LabelValue(label, value)),
          ]);
        }),
      ]),
      ConsoleCard(title: 'Report', children: <Widget>[
        Row(spacing: 12, children: <Widget>[
          Icon(fileName(r) == null ? Icons.notes : Icons.description, color: colors.primary),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: <Widget>[
              Text(fileName(r) == null ? 'Report text' : 'Report file', style: Theme.of(context).textTheme.bodyLarge),
              Text(fileName(r) ?? 'Written report', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          TextButton.icon(onPressed: clickView, icon: const Icon(Icons.visibility), label: const Text('View')),
        ]),
      ]),
    ]);
    final Widget right = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      ConsoleCard(title: 'Signature status', children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: StatusPill(
            icon: signed ? Icons.check_circle : Icons.schedule,
            label: '${r['signature_status']}',
            background: signed ? s.successContainer : s.warningContainer,
            foreground: signed ? s.success : s.warning,
          ),
        ),
        if (signed) Text('Signed by ${r['consultant_name']} on ${r['signed_date']}'),
      ]),
      ConsoleCard(title: 'View status', children: <Widget>[
        Align(alignment: Alignment.centerLeft, child: ViewStatusChip('${r['view_status']}')),
        Text(viewed ? 'Viewed on ${r['viewed_at']}' : 'You have not opened this report yet'),
      ]),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: colors.surfaceContainerLow, borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, spacing: 12, children: <Widget>[
          const Text('After reading the report, book the treatment on the Treatment page.'),
          FilledButton.tonalIcon(
            onPressed: () => context.go('/treatment'),
            icon: const Icon(Icons.healing),
            label: const Text('Go to Treatment'),
          ),
        ]),
      ),
    ]);
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
}
