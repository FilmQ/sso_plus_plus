import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../../../api/consultant_api.dart';
import '../../../widgets/error_banner.dart';
import '../../user/injury_form/injury_form_data.dart';
import '../../user/injury_form/upload_section.dart';
import '../scheduling/claim_chips.dart';
import '../shell/console_shell.dart';
import '../treatment/report_card.dart';
import '../verification/claim_cards.dart';
import '../verification/document_dialog.dart';
import 'consultant_providers.dart';
import 'report_draft_card.dart';
import 'report_status_cards.dart';
import 'signature_dialog.dart';

/// C2.1-1 Report page (SA report figures 2-100 to 2-113): C2.1 Amend the
/// draft, C2.2 Sign the signature and C2.3 File the report.
class CreateReportPage extends ConsumerStatefulWidget {
  const CreateReportPage({super.key});

  @override
  ConsumerState<CreateReportPage> createState() => _CreateReportPageState();
}

class _CreateReportPageState extends ConsumerState<CreateReportPage> {
  final TextEditingController _text = TextEditingController();
  int? appointmentId;
  Map<String, Object?>? _page; // QC2.3
  bool editing = false;
  PickedFile? _picked;
  bool _fileRemoved = false;
  Signature? _signature;
  bool _filed = false;
  String? _banner;
  String? _textError;
  bool _busy = false;

  ConsultantApi get _api => ref.read(consultantApiProvider);

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  /// C2.1 steps 2.1 to 2.2 (QC2.2, QC2.3): open the report page of [id].
  Future<void> selectConsultation(int id) async {
    setState(() => (appointmentId = id, _page = null, editing = false, _picked = null, _fileRemoved = false,
        _signature = null, _filed = false, _banner = null, _textError = null));
    try {
      final Map<String, Object?> page = await _api.openReport(id);
      if (mounted && appointmentId == id) setState(() => _page = page);
    } on ApiException catch (e) {
      if (mounted) setState(() => _banner = e.message);
    }
  }

  String? get _savedFile {
    final String? uri = _page?['report_file_uri'] as String?;
    return uri?.substring(uri.lastIndexOf('/') + 1);
  }

  /// C2.1 steps 3 to 8: "Amend the draft" opens the editor; "Finish the
  /// draft" saves the text or the chosen file (QC2.4 or QC2.5).
  Future<void> clickAmend() async {
    if (!editing) {
      setState(() => (editing = true, _text.text = (_page?['report_content'] as String?) ?? '', _textError = null));
      return;
    }
    final PickedFile? file = _picked;
    if (file == null && !_fileRemoved && _savedFile != null) {
      setState(() => editing = false); // the saved file stays as it is
      return;
    }
    await _run(() async {
      final Map<String, Object?> page = await _api.saveDraft(appointmentId!,
          content: file == null ? _text.text : null, file: file == null ? null : (name: file.name, bytes: file.bytes));
      setState(() => (_page = page, editing = false, _picked = null, _fileRemoved = false, _signature = null));
      _snack(file == null ? 'Draft saved.' : 'Draft saved. The report file is attached.');
    });
  }

  /// C2.1 Alternate Case 1 [Attach file]: the file explorer.
  Future<void> clickAttach() async {
    final PickedFile? f = await ref.read(fileChooserProvider)();
    if (f != null && mounted) setState(() => (_picked = f, _textError = null));
  }

  /// C2.2 steps 3 to 6: the signature card, then QC2.6.
  Future<void> clickSign() async {
    final Signature? drawn = await showSignatureDialog(context);
    if (drawn == null || !mounted) return; // the card was closed
    await _run(() async {
      final Map<String, Object?> page = await _api.signReport(appointmentId!);
      setState(() => (_page = page, _signature = drawn));
      _snack('Signature saved. The status is now Signed.');
    });
  }

  /// C2.3 steps 3 to 4 (QC2.7), with the validation message of Alternate
  /// Case 1 [Validation Failed].
  Future<void> clickFile() async {
    await _run(() async {
      final Map<String, Object?> page = await _api.fileReport(appointmentId!);
      setState(() => (_page = page, _filed = true));
      ref.invalidate(pendingConsultationsProvider);
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialog) => AlertDialog(
          icon: const Icon(Icons.task_alt),
          title: const Text('Report filed'),
          content: Text('Consultation report ${ReportShortcutCard.reportNo(page['report_id'])} for '
              '${page['claim_no']} has been filed. The evaluation officer has been notified and can now book the '
              'treatment.'),
          actions: <Widget>[FilledButton(onPressed: () => Navigator.of(dialog).pop(), child: const Text('OK'))],
        ),
      );
    });
  }

  /// Runs a change; a 422 shows what is missing, another error the server
  /// message.
  Future<void> _run(Future<void> Function() change) async {
    setState(() => (_busy = true, _banner = null, _textError = null));
    try {
      await change();
    } on ApiException catch (e) {
      final Map<String, Object?> fields = (e.body['fields'] as Map<String, Object?>?) ?? const <String, Object?>{};
      setState(() {
        if (editing) {
          _textError = (fields['report'] ?? fields['file']) as String?;
        } else {
          _banner = fields.isEmpty ? e.message : missingMessage(fields);
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// The banner of C2.3-1 from the 422 fields of QC2.7 (and of QC2.6).
  static String missingMessage(Map<String, Object?> fields) {
    final bool text = fields.containsKey('report');
    final bool sign = fields.containsKey('signature');
    if (text && sign) {
      return 'The report cannot be filed yet: there is no report text or file, and the signature status is '
          'Pending. Write the report and sign it, then click File the report again.';
    }
    if (sign) {
      return 'The report cannot be filed yet: the signature status is Pending. Sign the report, then click '
          'File the report again.';
    }
    return 'The report cannot be signed or filed yet: there is no report text or file. Write the report or attach '
        'a file first.';
  }

  void _snack(String text) {
    if (mounted) ScaffoldMessenger.of(context).showSnackBar(consoleSnackBar(text));
  }

  @override
  Widget build(BuildContext context) {
    final AsyncValue<List<Map<String, Object?>>> list = ref.watch(pendingConsultationsProvider);
    final List<Map<String, Object?>> rows = list.value ?? const <Map<String, Object?>>[];
    if (appointmentId == null && rows.isNotEmpty && !_filed) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && appointmentId == null) selectConsultation(rows.first['appointment_id']! as int);
      });
    }
    final Map<String, Object?>? page = _page;
    final bool signed = page?['signature_status'] == 'Signature signed';
    final Widget chips = ClaimChips(
      title: 'Consultations waiting for a report',
      empty: 'There are no consultations waiting for a report.',
      countLabel: 'waiting',
      idKey: 'appointment_id',
      labelOf: (Map<String, Object?> c) => '${c['claim_no']} · ${c['user_name']} · ${c['consultation_datetime']}',
      claims: rows,
      selectedId: appointmentId,
      loading: list.isLoading,
      onSelect: selectConsultation,
    );
    final Widget left = Column(crossAxisAlignment: CrossAxisAlignment.stretch, spacing: 16, children: <Widget>[
      if (_banner != null) ErrorBanner(_banner!),
      chips,
      if (page != null) ...<Widget>[
        ConsoleCard(title: 'Patient details', children: <Widget>[
          Wrap(spacing: 32, runSpacing: 16, children: <Widget>[
            LabelValue('User', '${page['user_name']}'),
            LabelValue('Age', '${page['user_age']}'),
            LabelValue('Consultation date and time', '${page['consultation_datetime']}'),
            LabelValue('Consultant', '${page['consultant_name']}'),
          ]),
        ]),
        ReportDraftCard(
          content: page['report_content'] as String?,
          fileName: _picked?.name ?? (_fileRemoved ? null : _savedFile),
          editing: editing,
          controller: _text,
          error: _textError,
          onAttach: clickAttach,
          onRemoveFile: () => setState(() => (_picked = null, _fileRemoved = true)),
          onViewFile: _savedFile == null
              ? null
              : () => showDocumentDialog(context,
                  <String, Object?>{'file_name': _savedFile, 'file_size': 'Report file'},
                  () => _api.openDraftFile(appointmentId!)),
        ),
      ],
    ]);
    final Widget right = page == null
        ? const SizedBox.shrink()
        : ReportStatusCards(
            signed: signed,
            signedDate: page['signed_date'] as String?,
            signature: _signature,
            filed: _filed,
            editing: editing,
            busy: _busy,
            onAmend: clickAmend,
            onSign: clickSign,
            onFile: clickFile,
          );
    return ConsolePage(
      title: page == null ? 'Create Consultation Report' : 'Consultation Report · ${page['claim_no']}',
      subtitle: page == null
          ? 'Consultations waiting for a report'
          : '${page['user_name']} · version ${page['version_no']} · '
              '${signed ? 'signed ${page['signed_date']}' : 'not signed yet'}',
      onBack: () => context.go('/schedule'),
      body: LayoutBuilder(builder: (BuildContext context, BoxConstraints box) {
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
      }),
    );
  }
}
