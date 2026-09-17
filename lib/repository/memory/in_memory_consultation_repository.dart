import '../../models/consultation_report.dart';
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
}
