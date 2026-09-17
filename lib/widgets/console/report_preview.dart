import 'package:flutter/material.dart';

import '../../models/consultation_report.dart';
import '../shared/formats.dart';
import '../shared/report_section.dart';
import 'console_card.dart';

/// The report as the claimant and the officer will read it (D7).
///
/// BR-30 says that the report is written in language the patient can read,
/// and that the clinical detail the officer needs stays in the same
/// document.
class ReportPreview extends StatelessWidget {
  const ReportPreview({
    super.key,
    required this.report,
    required this.patientName,
    required this.patientId,
  });

  final ConsultationReport report;
  final String patientName;
  final String patientId;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme colors = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: colors.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'CONSULTATION REPORT',
                      style: theme.textTheme.labelLarge?.copyWith(
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Social Security Office · standard template',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Chip(label: Text('Version ${report.version}')),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          FactGrid(
            perRow: 2,
            cells: <FactCell>[
              FactCell(label: 'Patient', value: '$patientName · $patientId'),
              FactCell(
                label: 'Consultation',
                value: report.consultedOn == null
                    ? 'Not recorded'
                    : Formats.dateAndTime(report.consultedOn!),
              ),
              FactCell(label: 'Consultant', value: report.consultantName),
              FactCell(label: 'Specialty', value: report.specialty),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          ReportSection(heading: 'Findings', body: report.findings),
          ReportSection(heading: 'Diagnosis', body: report.diagnosis),
          ReportSection(
            heading: 'Recommended treatment',
            body: report.recommendedTreatment,
          ),
          ReportSection(
            heading: 'Fitness for work',
            body: report.fitnessForWork.isEmpty
                ? 'Not recorded.'
                : report.fitnessForWork,
            isLast: true,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Divider(height: 1),
          ),
          Row(
            children: <Widget>[
              Icon(
                report.isSigned ? Icons.verified : Icons.draw_outlined,
                size: 18,
                color: report.isSigned ? colors.primary : colors.outline,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      report.isSigned
                          ? 'Signed by ${report.consultantName}'
                          : 'Signature pending',
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      report.isSigned
                          ? 'Locked on '
                                '${Formats.dateAndTime(report.signedAt!)}'
                          : 'The report is filed on the claim when it is '
                                'signed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
