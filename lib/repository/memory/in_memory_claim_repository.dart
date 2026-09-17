import '../../models/claim.dart';
import '../../models/claim_status.dart';
import '../claim_repository.dart';
import 'demo_store.dart';

/// Keeps claims in memory for the demonstration.
class InMemoryClaimRepository implements ClaimRepository {
  InMemoryClaimRepository(this._store);

  final DemoStore _store;

  /// The states in which a claim still counts as open.
  static const Set<ClaimStatus> _closedStates = <ClaimStatus>{
    ClaimStatus.rejected,
    ClaimStatus.closed,
  };

  @override
  Future<List<Claim>> claimsForPerson(String personId) async {
    final List<Claim> found = _store.claims
        .where((Claim c) => c.personId == personId)
        .toList();
    found.sort((Claim a, Claim b) {
      final DateTime left = a.submittedAt ?? a.createdAt ?? DateTime(0);
      final DateTime right = b.submittedAt ?? b.createdAt ?? DateTime(0);
      return right.compareTo(left);
    });
    return found;
  }

  @override
  Future<Claim?> byNumber(String claimNumber) async {
    for (final Claim claim in _store.claims) {
      if (claim.claimNumber == claimNumber) {
        return claim;
      }
    }
    return null;
  }

  @override
  Future<Claim> save(Claim claim) async {
    final int index = _store.claims.indexWhere(
      (Claim c) => c.claimNumber == claim.claimNumber,
    );
    if (index >= 0) {
      _store.claims[index] = claim;
    } else {
      _store.claims.add(claim);
    }
    return claim;
  }

  @override
  Future<String> nextClaimNumber() async => _store.nextClaimNumber();

  @override
  Future<List<Claim>> byStatuses(Set<ClaimStatus> statuses) async {
    final List<Claim> found = _store.claims
        .where((Claim c) => statuses.contains(c.status))
        .toList();
    // The design sorts the verification worklist by the oldest submission.
    found.sort((Claim a, Claim b) {
      final DateTime left = a.submittedAt ?? a.createdAt ?? DateTime(0);
      final DateTime right = b.submittedAt ?? b.createdAt ?? DateTime(0);
      return left.compareTo(right);
    });
    return found;
  }

  @override
  Future<Claim?> openClaimForInjury(
    String personId,
    DateTime injuryDate,
  ) async {
    for (final Claim claim in _store.claims) {
      if (claim.personId != personId) {
        continue;
      }
      if (_closedStates.contains(claim.status) || claim.isDraft) {
        continue;
      }
      final DateTime? other = claim.injury.date;
      if (other == null) {
        continue;
      }
      if (other.year == injuryDate.year &&
          other.month == injuryDate.month &&
          other.day == injuryDate.day) {
        return claim;
      }
    }
    return null;
  }
}
