import '../models/claim.dart';
import '../models/claim_status.dart';

/// Reads and writes claims.
///
/// This is the seam that `CLAUDE.md` demands. The use cases know this
/// interface only. They never see where the data comes from. When the table
/// schemas become complete, a new class against this interface replaces the
/// in-memory one, and no use case changes.
abstract interface class ClaimRepository {
  /// All claims of one person, with the newest first.
  Future<List<Claim>> claimsForPerson(String personId);

  /// One claim, or null if no claim carries that number.
  Future<Claim?> byNumber(String claimNumber);

  /// Stores a new claim or replaces an existing one.
  Future<Claim> save(Claim claim);

  /// Supplies the next free claim number, for example `CLM-2569-0144`.
  Future<String> nextClaimNumber();

  /// The open claim for the same injury, if the person already has one.
  ///
  /// UC-01 (4a) offers to add the new facts to this claim, instead of a
  /// second claim for one injury.
  Future<Claim?> openClaimForInjury(String personId, DateTime injuryDate);

  // --- The console needs this ---

  /// Every claim in one of [statuses], oldest submission first.
  ///
  /// The officer worklists are built from this call. The design sorts the
  /// verification worklist by the oldest submission.
  Future<List<Claim>> byStatuses(Set<ClaimStatus> statuses);
}
