import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/insured_person.dart';
import 'repository_providers.dart';

/// The person who uses the application.
///
/// The patient application has one actor, so it needs no session provider.
/// Section 6.3 of IMPLEMENTATION.md records this.
final Provider<InsuredPerson> currentPersonProvider = Provider<InsuredPerson>(
  (Ref ref) => ref.watch(demoStoreProvider).person,
);
