import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/claim.dart';
import '../models/consultation_report.dart';
import 'person_provider.dart';
import 'repository_providers.dart';

/// Every claim of the person, with the newest first.
final FutureProvider<List<Claim>> claimsProvider = FutureProvider<List<Claim>>((
  Ref ref,
) async {
  final person = ref.watch(currentPersonProvider);
  return ref.watch(claimRepositoryProvider).claimsForPerson(person.id);
});

/// One claim by its number.
final claimProvider = FutureProvider.family<Claim?, String>((
  Ref ref,
  String claimNumber,
) async {
  return ref.watch(claimRepositoryProvider).byNumber(claimNumber);
});

/// The newest signed report of one claim, or null if none is signed.
final latestReportProvider = FutureProvider.family<ConsultationReport?, String>(
  (Ref ref, String claimNumber) async {
    return ref.watch(consultationRepositoryProvider).latestSigned(claimNumber);
  },
);
