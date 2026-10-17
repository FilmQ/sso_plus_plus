import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api_exception.dart';
import '../notifications/notification_providers.dart';
import '../schedule/schedule_providers.dart';

/// Opens the Confirm Treatment page (U4-1) of a claim from a message or the
/// Home page. A message has only the claim_id, so the treatment comes from
/// the Q6.1 rows: the Pending one first, else the next one (D-045).
Future<void> openTreatmentOfClaim(BuildContext context, WidgetRef ref, int claimId) async {
  try {
    final List<Map<String, Object?>> rows = await ref.read(treatmentApiProvider).getTreatmentSchedule();
    final Iterable<Map<String, Object?>> ofClaim = rows.where((Map<String, Object?> t) => t['claim_id'] == claimId);
    final Map<String, Object?>? treatment =
        ofClaim.where((Map<String, Object?> t) => t['treatment_status'] == 'Pending').firstOrNull ?? ofClaim.firstOrNull;
    if (!context.mounted) return;
    if (treatment == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('There is no upcoming treatment for this claim.')));
      return;
    }
    await context.push('/treatment/${treatment['treatment_id']}');
    refreshUserData(ref);
  } on ApiException catch (e) {
    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
  }
}
