import '../../models/claim.dart';
import '../../models/notice.dart';
import '../notice_repository.dart';
import 'demo_store.dart';

/// Keeps the inbox of the person in memory for the demonstration.
class InMemoryNoticeRepository implements NoticeRepository {
  InMemoryNoticeRepository(this._store);

  final DemoStore _store;

  Set<String> _claimNumbersOf(String personId) => _store.claims
      .where((Claim c) => c.personId == personId)
      .map((Claim c) => c.claimNumber)
      .toSet();

  @override
  Future<List<Notice>> forPerson(String personId) async {
    final Set<String> numbers = _claimNumbersOf(personId);
    final List<Notice> found = _store.notices
        .where((Notice n) => numbers.contains(n.claimNumber))
        .toList();
    found.sort((Notice a, Notice b) => b.sentAt.compareTo(a.sentAt));
    return found;
  }

  @override
  Future<int> unreadCount(String personId) async {
    final List<Notice> all = await forPerson(personId);
    return all.where((Notice n) => !n.isRead).length;
  }

  @override
  Future<Notice> save(Notice notice) async {
    final int index = _store.notices.indexWhere(
      (Notice n) => n.id == notice.id,
    );
    if (index >= 0) {
      _store.notices[index] = notice;
    } else {
      _store.notices.insert(0, notice);
    }
    return notice;
  }
}
