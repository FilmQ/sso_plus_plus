import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/staff_member.dart';
import 'repository_providers.dart';

/// The member of staff who uses the console now.
///
/// This identity goes on every decision (BR-06, BR-13, BR-16 and BR-29). It
/// does **not** decide what the rail shows: the design shows the work of
/// both roles at all times. BR-22 is enforced in the repository.
class CurrentStaffNotifier extends Notifier<StaffMember> {
  @override
  StaffMember build() => ref.watch(demoStoreProvider).currentStaff;

  /// Changes the member of staff. The demonstration needs this, because one
  /// console serves the officer and the consultant.
  void change(StaffMember staff) {
    ref.read(demoStoreProvider).currentStaff = staff;
    state = staff;
  }
}

final NotifierProvider<CurrentStaffNotifier, StaffMember> currentStaffProvider =
    NotifierProvider<CurrentStaffNotifier, StaffMember>(
      CurrentStaffNotifier.new,
    );

/// Everybody who may sign in to the console.
final Provider<List<StaffMember>> staffListProvider =
    Provider<List<StaffMember>>(
      (Ref ref) => ref.watch(demoStoreProvider).staff,
    );

/// The consultant record of the member of staff, if they are a consultant.
///
/// The clinic screens read this. An officer has none, so those screens show
/// an empty list to them.
final Provider<String?> currentConsultantIdProvider = Provider<String?>(
  (Ref ref) => ref.watch(currentStaffProvider).consultantId,
);
