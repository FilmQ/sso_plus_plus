import '../../models/consultation_report.dart';
import '../../models/consultation_session.dart';
import '../consultation_repository.dart';
import 'demo_store.dart';

/// Keeps consultation reports in memory for the demonstration.
class InMemoryConsultationRepository implements ConsultationRepository {
  InMemoryConsultationRepository(this._store);

  final DemoStore _store;

  @override
  Future<List<ConsultationReport>> forClaim(String claimNumber) async {
    final List<ConsultationReport> found = _store.reports
        .where((ConsultationReport r) => r.claimNumber == claimNumber)
        .toList();
    found.sort(
      (ConsultationReport a, ConsultationReport b) =>
          b.version.compareTo(a.version),
    );
    return found;
  }

  @override
  Future<ConsultationReport?> latestSigned(String claimNumber) async {
    final List<ConsultationReport> all = await forClaim(claimNumber);
    for (final ConsultationReport report in all) {
      if (report.isSigned && !report.superseded) {
        return report;
      }
    }
    return null;
  }

  @override
  Future<ConsultationReport?> byId(String id) async {
    for (final ConsultationReport report in _store.reports) {
      if (report.id == id) {
        return report;
      }
    }
    return null;
  }

  @override
  Future<ConsultationReport> save(ConsultationReport report) async {
    final int index = _store.reports.indexWhere(
      (ConsultationReport r) => r.id == report.id,
    );
    if (index >= 0) {
      _store.reports[index] = report;
    } else {
      _store.reports.add(report);
    }
    return report;
  }

  // --- The console needs these ---

  @override
  Future<List<ConsultationSession>> sessionsForConsultant(
    String consultantId,
  ) async {
    // BR-22: a consultant sees the claims assigned to them and no others.
    // The rule lives here, and not in the router, so it holds even when a
    // demonstration changes the member of staff.
    final List<ConsultationSession> found = _store.sessions
        .where((ConsultationSession s) => s.consultantId == consultantId)
        .toList();
    found.sort(
      (ConsultationSession a, ConsultationSession b) => a.id.compareTo(b.id),
    );
    return found;
  }

  @override
  Future<ConsultationSession?> sessionById(String id) async {
    for (final ConsultationSession session in _store.sessions) {
      if (session.id == id) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<ConsultationSession?> sessionForClaim(String claimNumber) async {
    for (final ConsultationSession session in _store.sessions) {
      if (session.claimNumber == claimNumber) {
        return session;
      }
    }
    return null;
  }

  @override
  Future<ConsultationSession> saveSession(ConsultationSession session) async {
    final int index = _store.sessions.indexWhere(
      (ConsultationSession s) => s.id == session.id,
    );
    if (index >= 0) {
      _store.sessions[index] = session;
    } else {
      _store.sessions.add(session);
    }
    return session;
  }

  @override
  Future<List<ConsultationReport>> unsignedFor(String consultantId) async {
    final List<String> mine = (await sessionsForConsultant(consultantId))
        .map((ConsultationSession s) => s.claimNumber)
        .toList();
    return _store.reports
        .where(
          (ConsultationReport r) => !r.isSigned && mine.contains(r.claimNumber),
        )
        .toList();
  }
}
