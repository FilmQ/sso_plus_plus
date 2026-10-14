import 'package:sso_plus_plus/legacy/repository/memory/demo_store.dart';
import 'package:sso_plus_plus/legacy/repository/memory/in_memory_claim_repository.dart';
import 'package:sso_plus_plus/legacy/repository/memory/in_memory_consultation_repository.dart';
import 'package:sso_plus_plus/legacy/repository/memory/in_memory_insured_register_repository.dart';
import 'package:sso_plus_plus/legacy/repository/memory/in_memory_notice_repository.dart';
import 'package:sso_plus_plus/legacy/repository/memory/in_memory_scheduling_repository.dart';
import 'package:sso_plus_plus/legacy/repository/memory/seed_data.dart';

/// Builds a fresh store and its repositories for one test.
///
/// The hardcoded repositories are the test doubles. The project adds no mock
/// package, as section 11 of IMPLEMENTATION.md says.
class TestContext {
  TestContext({DateTime? now}) : store = DemoStore(startAt: now) {
    claims = InMemoryClaimRepository(store);
    scheduling = InMemorySchedulingRepository(store);
    consultation = InMemoryConsultationRepository(store);
    notices = InMemoryNoticeRepository(store);
    register = InMemoryInsuredRegisterRepository(store);
  }

  final DemoStore store;
  late final InMemoryClaimRepository claims;
  late final InMemorySchedulingRepository scheduling;
  late final InMemoryConsultationRepository consultation;
  late final InMemoryNoticeRepository notices;
  late final InMemoryInsuredRegisterRepository register;

  /// The clock that the use cases read. It follows the store.
  DateTime clock() => store.now;

  /// The person that the seed data describes.
  String get personId => SeedData.person.id;
}
