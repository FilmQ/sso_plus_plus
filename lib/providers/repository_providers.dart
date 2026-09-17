import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../repository/claim_repository.dart';
import '../repository/consultation_repository.dart';
import '../repository/insured_register_repository.dart';
import '../repository/memory/demo_store.dart';
import '../repository/memory/in_memory_claim_repository.dart';
import '../repository/memory/in_memory_consultation_repository.dart';
import '../repository/memory/in_memory_insured_register_repository.dart';
import '../repository/memory/in_memory_notice_repository.dart';
import '../repository/memory/in_memory_scheduling_repository.dart';
import '../repository/notice_repository.dart';
import '../repository/scheduling_repository.dart';
import '../use-cases/clock.dart';

/// This file is the only place that a change of backend touches.
///
/// When the table schemas become complete, point each provider at an
/// implementation that speaks to the service. No use case and no screen
/// changes. Section 3.2 of IMPLEMENTATION.md explains the seam.

/// The one mutable store that holds all demo data.
final Provider<DemoStore> demoStoreProvider = Provider<DemoStore>(
  (Ref ref) => DemoStore(),
);

/// The time that the use cases read.
///
/// It comes from the store, so a demo control can move it forward.
final Provider<Clock> clockProvider = Provider<Clock>(
  (Ref ref) =>
      () => ref.read(demoStoreProvider).now,
);

final Provider<ClaimRepository> claimRepositoryProvider =
    Provider<ClaimRepository>(
      (Ref ref) => InMemoryClaimRepository(ref.watch(demoStoreProvider)),
    );

final Provider<SchedulingRepository> schedulingRepositoryProvider =
    Provider<SchedulingRepository>(
      (Ref ref) => InMemorySchedulingRepository(ref.watch(demoStoreProvider)),
    );

final Provider<ConsultationRepository> consultationRepositoryProvider =
    Provider<ConsultationRepository>(
      (Ref ref) => InMemoryConsultationRepository(ref.watch(demoStoreProvider)),
    );

final Provider<NoticeRepository> noticeRepositoryProvider =
    Provider<NoticeRepository>(
      (Ref ref) => InMemoryNoticeRepository(ref.watch(demoStoreProvider)),
    );

final Provider<InsuredRegisterRepository> insuredRegisterRepositoryProvider =
    Provider<InsuredRegisterRepository>(
      (Ref ref) =>
          InMemoryInsuredRegisterRepository(ref.watch(demoStoreProvider)),
    );
