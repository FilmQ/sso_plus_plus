import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../session/session_providers.dart';
import '../session/user_session.dart';

/// Tells the router to run its redirect again when the session changes.
class SessionRefresh extends ChangeNotifier {
  SessionRefresh(Ref ref) {
    ref.listen<AsyncValue<UserSession?>>(sessionProvider, (_, _) => notifyListeners());
  }
}
