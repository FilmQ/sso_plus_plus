import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/appointment.dart';
import 'person_provider.dart';
import 'repository_providers.dart';

/// Every appointment of the person, with the newest first.
final FutureProvider<List<Appointment>> appointmentsProvider =
    FutureProvider<List<Appointment>>((Ref ref) async {
      final person = ref.watch(currentPersonProvider);
      return ref.watch(schedulingRepositoryProvider).forPerson(person.id);
    });

/// One appointment by its identifier.
final appointmentProvider = FutureProvider.family<Appointment?, String>((
  Ref ref,
  String id,
) async {
  return ref.watch(schedulingRepositoryProvider).byId(id);
});

/// The appointment that waits for an answer.
///
/// The home screen shows this one in its "next step" card. It is null when
/// nothing waits for the person.
final FutureProvider<Appointment?> appointmentAwaitingReplyProvider =
    FutureProvider<Appointment?>((Ref ref) async {
      final person = ref.watch(currentPersonProvider);
      return ref.watch(schedulingRepositoryProvider).awaitingReply(person.id);
    });
