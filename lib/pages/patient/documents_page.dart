import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/claim.dart';
import '../../models/claim_document.dart';
import '../../providers/new_claim_provider.dart';
import '../../use-cases/uc_01_submit_injury_application.dart';
import '../../widgets/patient/action_bar.dart';
import '../../widgets/patient/notice_banner.dart';
import '../../widgets/patient/step_progress_header.dart';
import '../../widgets/shared/document_checklist_row.dart';
import '../../widgets/shared/info_card.dart';
import '../../widgets/shared/section_heading.dart';

/// M3 · Submit claim — documents (UC-01, steps 3 and 4).
///
/// BR-03 says that the checklist must be complete before the application
/// registers the claim. The Submit button stays inactive until then.
class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NewClaimState draft = ref.watch(newClaimProvider);
    final List<ClaimDocument> documents = draft.documents;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New injury claim'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/new-claim'),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: <Widget>[
            const StepProgressHeader(
              step: 2,
              totalSteps: 3,
              title: 'Documents',
            ),
            const SizedBox(height: 12),
            const SectionHeading('Required documents'),
            InfoCard(
              child: Column(
                children: <Widget>[
                  for (int i = 0; i < documents.length; i++)
                    DocumentChecklistRow(
                      document: documents[i],
                      isLast: i == documents.length - 1,
                      onAttach: () =>
                          _chooseSource(context, ref, documents[i].type),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _attachNext(context, ref, 'photo'),
                    icon: const Icon(Icons.photo_camera_outlined),
                    label: const Text('Take photo'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _attachNext(context, ref, 'file'),
                    icon: const Icon(Icons.attach_file),
                    label: const Text('Attach file'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            NoticeBanner(
              text: draft.hasAllDocuments
                  ? 'The checklist is complete. You can send the claim now.'
                  : 'Saved as a draft. The claim is not registered until '
                        'every document is attached.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: ActionBar(
        secondaryLabel: 'Save draft',
        primaryLabel: draft.busy ? 'Please wait' : 'Submit claim',
        onSecondary: () => _saveDraft(context),
        onPrimary: draft.hasAllDocuments && !draft.busy
            ? () => _submit(context, ref)
            : null,
      ),
    );
  }

  static void _saveDraft(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('The application saved your draft.')),
    );
  }

  /// A demonstration stands in for the camera and the file browser.
  static String _fileNameFor(DocumentType type, String source) {
    final String stem = switch (type) {
      DocumentType.medicalCertificate => 'medical_certificate',
      DocumentType.employerStatement => 'employer_statement',
      DocumentType.identification => 'national_id',
    };
    return source == 'photo' ? '$stem.jpg' : '$stem.pdf';
  }

  static void _attachNext(BuildContext context, WidgetRef ref, String source) {
    final NewClaimState draft = ref.read(newClaimProvider);
    for (final ClaimDocument document in draft.documents) {
      if (!document.isAttached) {
        ref
            .read(newClaimProvider.notifier)
            .attach(document.type, _fileNameFor(document.type, source));
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Every document is already attached.')),
    );
  }

  static Future<void> _chooseSource(
    BuildContext context,
    WidgetRef ref,
    DocumentType type,
  ) async {
    final String? source = await showModalBottomSheet<String>(
      context: context,
      builder: (BuildContext context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take photo'),
              subtitle: const Text('A photograph is accepted.'),
              onTap: () => Navigator.of(context).pop('photo'),
            ),
            ListTile(
              leading: const Icon(Icons.attach_file),
              title: const Text('Attach file'),
              onTap: () => Navigator.of(context).pop('file'),
            ),
          ],
        ),
      ),
    );
    if (source != null) {
      ref
          .read(newClaimProvider.notifier)
          .attach(type, _fileNameFor(type, source));
    }
  }

  static Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final SubmitResult result = await ref
        .read(newClaimProvider.notifier)
        .submit();
    if (!context.mounted) {
      return;
    }

    switch (result) {
      case Submitted(claim: final Claim claim):
        ref.read(newClaimProvider.notifier).reset();
        context.go('/claims/${claim.claimNumber}');

      case MissingRequiredFields(fields: final List<String> fields):
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Complete these first: ${fields.join(', ')}.'),
          ),
        );
        context.go('/new-claim');

      case SavedAsDraft(outstanding: final List<ClaimDocument> outstanding):
        final String names = outstanding
            .map((ClaimDocument d) => d.type.label)
            .join(', ');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Still outstanding: $names.')));

      case DuplicateOpenClaim(existing: final Claim existing):
        await _offerExisting(context, existing);
    }
  }

  /// Flow 4a: one injury must not produce two claims.
  static Future<void> _offerExisting(
    BuildContext context,
    Claim existing,
  ) async {
    final bool? open = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('A claim for this injury is open'),
        content: Text(
          'Claim ${existing.claimNumber} already covers an injury on that '
          'date. Add the new facts to that claim instead of a second one.',
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Open that claim'),
          ),
        ],
      ),
    );
    if (open ?? false) {
      if (context.mounted) {
        context.go('/claims/${existing.claimNumber}');
      }
    }
  }
}
