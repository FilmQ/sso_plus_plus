import '../repository/claim_repository.dart';
import '../repository/repository.dart' show NoRowChangedException;
import '../storage/file_storage.dart';
import 'field_rules.dart';
import 'injury_form.dart';
import 'insured_person_model.dart';
import 'model.dart';

/// InjuryClaim (SA report 2.18, used in U1, O1, O2, O3, O5.2).
class ClaimModel extends Model {
  ClaimModel(this.claims, this.storage);

  final ClaimRepository claims;
  final FileStorage storage;

  /// The claim_id of the last [createClaim], so that the caller can remove the
  /// stored files when the transaction rolls back.
  int? lastClaimId;

  /// U1 steps 5.4 to 5.8. Gives the claim_no and submitted_at (Q1.7) for U1-5.
  /// Run it in a transaction.
  Future<({String claimNo, DateTime submittedAt})> createClaim(int insuredId, InjuryForm form, List<UploadedFile> files, Registration reg) async {
    // Q1.6
    final claimId = await claims.insertClaim(
      insuredId: insuredId,
      employerId: reg.employerId,
      injuryDatetime: form.injuryDatetime,
      injuryPlace: form.injuryPlace,
      injuryCause: form.injuryCause,
      bodyPart: form.bodyPart,
      injuryCategory: form.injuryCategory,
      registerResult: reg.registerResult,
    );
    lastClaimId = claimId;
    // Q1.7
    final assigned = await claims.assignClaimNo(claimId);
    // Q1.8, one row for each file
    for (final file in files) {
      await claims.insertDocument(
        claimId: claimId,
        docTypeId: file.docTypeId,
        fileName: file.fileName,
        fileUri: await storage.save(claimId, file.fileName, file.bytes),
        mimeType: FieldRules.mimeTypeOf(file.fileName)!,
        fileSizeBytes: file.bytes.length,
      );
    }
    // Q1.9
    await claims.insertAutoEligibility(
      claimId: claimId,
      coverageId: reg.coverageId,
      registerResult: reg.registerResult,
      evidenceRef: reg.registerResult == 'Covered' ? evidenceRef(claimId) : null,
    );
    // Q1.10
    await claims.insertFirstStatus(claimId);
    return assigned;
  }

  /// O2 Approve Injury Application: QO2.1 with result 'Covered'. QO2.1 itself
  /// decides only a claim that is not yet decided; else StateConflictException.
  Future<void> confirmResult(int claimId, {required int officerId, String? overrideReason}) =>
      _decide(() => claims.saveResult(
          claimId: claimId, result: 'Covered', officerId: officerId, overrideReason: overrideReason));

  /// O3 Reject Injury Application: QO3.1 ('Not covered'), then QO3.2 ('Rejected').
  Future<void> rejectApplication(int claimId,
          {required int officerId, required String reasonCode, String? officerMessage}) =>
      _decide(() async {
        await claims.saveResult(claimId: claimId, result: 'Not covered', officerId: officerId, overrideReason: reasonCode);
        await claims.insertRejection(
            claimId: claimId, reasonCode: reasonCode, officerId: officerId, officerMessage: officerMessage);
      });

  /// Runs a decision in one transaction. A guarded query that changes no row
  /// rolls the transaction back: the claim is already decided, or it has no
  /// automatic Section 33 check row (R-013).
  Future<void> _decide(Future<void> Function() body) async {
    try {
      await claims.db.transaction(body);
    } on NoRowChangedException {
      throw const StateConflictException('The claim is already decided.');
    }
  }

  /// The register reference, in the seed format 'REG-20261002-0143' (D-017).
  static String evidenceRef(int claimId, [DateTime? now]) {
    final d = now ?? DateTime.now();
    String pad(int n, int w) => n.toString().padLeft(w, '0');
    return 'REG-${d.year}${pad(d.month, 2)}${pad(d.day, 2)}-${pad(claimId, 4)}';
  }
}
