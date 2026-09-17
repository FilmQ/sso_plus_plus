import '../models/notice.dart';

/// Reads and writes the inbox of the person.
///
/// The application delivers every decision here. UC-03 puts the rejection
/// notice in this inbox, and UC-10 puts the report notice in it.
abstract interface class NoticeRepository {
  /// Every message for one person, with the newest first.
  Future<List<Notice>> forPerson(String personId);

  /// The number of messages that the person has not read.
  Future<int> unreadCount(String personId);

  /// Stores a new message or replaces an existing one.
  Future<Notice> save(Notice notice);
}
