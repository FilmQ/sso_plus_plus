import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'routing/user_router.dart';
import 'sst_app.dart';

/// The user app (ผู้ใช้งาน): phone layout, web and mobile.
/// The officer and consultant console starts at `lib/main_console.dart`.
void main() {
  runApp(ProviderScope(child: SstApp(title: 'SST Injury Claim', router: userRouterProvider)));
}
