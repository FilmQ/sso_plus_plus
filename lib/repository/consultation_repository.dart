import '../models/consultation_report.dart';
import '../models/consultation_session.dart';

/// Reads and writes consultation sessions and their reports.
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

  // --- The console needs these ---

  /// The sessions of one consultant (BR-22).
  ///
  /// A consultant sees the claims assigned to them and no others. This
  /// repository enforces that rule, and not the router.
  Future<List<ConsultationSession>> sessionsForConsultant(String consultantId);

  /// One session, or null if the identifier is not known.
  Future<ConsultationSession?> sessionById(String id);

  /// The session against one claim, or null if none was arranged.
  Future<ConsultationSession?> sessionForClaim(String claimNumber);

  /// Stores a new session or replaces an existing one.
  Future<ConsultationSession> saveSession(ConsultationSession session);

  /// The reports of one consultant that wait for a signature.
  Future<List<ConsultationReport>> unsignedFor(String consultantId);
}
