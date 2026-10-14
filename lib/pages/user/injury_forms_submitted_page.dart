import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../theme/status_colors.dart';
import '../../widgets/centered_body.dart';
import '../../widgets/info_card.dart';
import '../../widgets/key_value.dart';
import '../../widgets/status_chip.dart';
import 'submission_provider.dart';

/// U1-5 Injury forms submitted (SA report figure 2-13): U1 step 6 shows the
/// claim_no of the new claim.
class InjuryFormsSubmittedPage extends ConsumerWidget {
  const InjuryFormsSubmittedPage({super.key});

  static const Map<int, String> _fileNames = <int, String>{1: 'National ID card', 2: 'medical record', 3: 'injury form'};

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Map<String, Object?> claim = ref.watch(submissionProvider) ?? const <String, Object?>{};
    final TextTheme text = Theme.of(context).textTheme;
    final StatusColors ok = StatusColors.of(context);
    final List<Object?> files = (claim['files_received'] as List<Object?>?) ?? const <Object?>[];
    final String received = files.map((Object? id) => _fileNames[id]).join(', ');
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
          child: CenteredBody(
            child: Column(
              spacing: 20,
              children: <Widget>[
                CircleAvatar(
                  radius: 44,
                  backgroundColor: ok.successContainer,
                  child: Icon(Icons.check_circle, size: 48, color: ok.success),
                ),
                Text('Injury forms submitted', style: text.headlineSmall, textAlign: TextAlign.center),
                Text(
                  'Your claim has been sent to an evaluation officer. We will notify you when it has been checked.',
                  style: text.bodyMedium?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  textAlign: TextAlign.center,
                ),
                InfoCard(
                  icon: Icons.assignment,
                  title: 'Claim ${claim['claim_no'] ?? ''}',
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(child: Text('Status', style: text.bodyMedium)),
                        ClaimStatusChip((claim['claim_status'] as String?) ?? ''),
                      ],
                    ),
                    const Divider(),
                    KeyValue('Submitted', (claim['submitted_time'] as String?) ?? ''),
                    KeyValue('Claimant', (claim['claimant_name'] as String?) ?? ''),
                    KeyValue('Files received', received.isEmpty ? '' : '${received[0].toUpperCase()}${received.substring(1)}'),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(onPressed: () => context.go('/home'), child: const Text('Go to Home')),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
