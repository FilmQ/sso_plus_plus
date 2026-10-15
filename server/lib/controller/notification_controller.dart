import '../auth/user_session.dart';
import '../repository/claim_repository.dart';
import '../repository/notification_repository.dart';
import 'controller.dart';

/// U2 View Notify Message (SA report 2.13, sequence U2).
///
/// The report passes `insured_id`; here it always comes from the session, so a
/// user can read only his or her own messages.
class NotificationController extends Controller {
  NotificationController(super.session, this.repository, this.claimRepository);

  final NotificationRepository repository;
  final ClaimRepository claimRepository;

  int get _insuredId => requireRole(Role.user).insuredId!;

  /// U2 step 2 (Q2.1): the number for the red dot on the bell icon.
  Future<int> checkUnreadNotifications() => repository.countUnread(_insuredId);

  /// U2 step 2 (Q2.4): the claim card of the Home page, or null.
  Future<Map<String, Object?>?> getHomeClaim() => claimRepository.findHomeClaim(_insuredId);

  /// U2 step 4 (Q2.2): the list of the pop-up, newest first.
  Future<List<Map<String, Object?>>> getNotifications() => repository.findNotifications(_insuredId);

  /// U2 step 6 (Q2.3): marks the message as read. Gives the message for the
  /// detail view, or throws 404 when it is not a message of this user.
  Future<Map<String, Object?>> markAsRead(int notificationId) async {
    final insuredId = _insuredId;
    await repository.markAsRead(notificationId, insuredId);
    final message = (await repository.findNotifications(insuredId))
        .where((n) => n['notification_id'] == notificationId)
        .firstOrNull;
    if (message == null) throw const ControllerException(404, 'The message was not found.');
    return message;
  }
}
