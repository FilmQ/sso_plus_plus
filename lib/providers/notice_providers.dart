import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/notice.dart';
import 'person_provider.dart';
import 'repository_providers.dart';

/// The inbox of the person, with the newest message first.
final FutureProvider<List<Notice>> noticesProvider =
    FutureProvider<List<Notice>>((Ref ref) async {
      final person = ref.watch(currentPersonProvider);
      return ref.watch(noticeRepositoryProvider).forPerson(person.id);
    });

/// The number of messages that the person has not read.
///
/// The navigation bar shows this number on the Inbox destination.
final FutureProvider<int> unreadNoticeCountProvider = FutureProvider<int>((
  Ref ref,
) async {
  final person = ref.watch(currentPersonProvider);
  return ref.watch(noticeRepositoryProvider).unreadCount(person.id);
});

/// Records that the person opened a message.
///
/// This is a state of the inbox and not a business rule, so it stays with
/// the read model. UC-03 keeps its own record of a rejection notice.
final Provider<Future<void> Function(Notice)> markNoticeReadProvider =
    Provider<Future<void> Function(Notice)>((Ref ref) {
      return (Notice notice) async {
        if (notice.isRead) {
          return;
        }
        await ref
            .read(noticeRepositoryProvider)
            .save(notice.copyWith(readAt: ref.read(clockProvider)()));
        ref.invalidate(noticesProvider);
        ref.invalidate(unreadNoticeCountProvider);
      };
    });
