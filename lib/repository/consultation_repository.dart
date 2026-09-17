import '../models/consultation_report.dart';

/// Reads and writes consultation reports.
///
/// BR-28 says that a signed report is immutable. A correction is a new
/// version. `save` therefore adds a version. It never changes a signed one.
abstract interface class ConsultationRepository {
  /// Every report against one claim, with the newest version first.
  Future<List<ConsultationReport>> forClaim(String claimNumber);

  /// The newest signed report of one claim, or null if none is signed.
  Future<ConsultationReport?> latestSigned(String claimNumber);

  /// One report, or null if the identifier is not known.
  Future<ConsultationReport?> byId(String id);

  /// Stores a report version.
  Future<ConsultationReport> save(ConsultationReport report);
}
