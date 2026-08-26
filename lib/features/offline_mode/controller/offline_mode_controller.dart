import 'package:expense_calculator/features/offline_mode/repository/offline_mode_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app is currently operating against the local Drift database
/// instead of Firestore. Seeded synchronously from SharedPreferences before
/// `runApp` (see main.dart) via a ProviderScope override, so routing never
/// has to juggle a loading state for something this fundamental -- the
/// `false` default here only matters if that override is ever skipped
/// (e.g. a test harness).
final isOfflineModeProvider = StateProvider<bool>((ref) => false);

/// The signed-in local profile's id while in offline mode, or null. Also
/// seeded before `runApp`.
final currentLocalUserIdProvider = StateProvider<String?>((ref) => null);

/// The id of whoever is currently signed in, regardless of mode -- the
/// local profile id offline, the Firebase uid online. Used anywhere that
/// needs to key per-user local data (e.g. the session lock's biometric
/// flag) without caring which backend is active. Takes the two provider
/// values directly (rather than a `Ref`) so it works from both `Ref` and
/// `WidgetRef` call sites -- the two types don't share a common interface.
String? currentSessionUserId({
  required bool isOffline,
  required String? localUserId,
}) {
  if (isOffline) return localUserId;
  return FirebaseAuth.instance.currentUser?.uid;
}

final offlineModeControllerProvider = Provider(
  (ref) => OfflineModeController(
    repository: ref.watch(offlineModeRepositoryProvider),
    ref: ref,
  ),
);

class OfflineModeController {
  final OfflineModeRepository repository;
  final Ref ref;
  OfflineModeController({required this.repository, required this.ref});

  Future<void> setOfflineMode(bool preferred) async {
    await repository.setOfflineModePreferred(preferred);
    ref.read(isOfflineModeProvider.notifier).state = preferred;
  }

  Future<void> setCurrentLocalUser(String? uid) async {
    await repository.setCurrentLocalUserId(uid);
    ref.read(currentLocalUserIdProvider.notifier).state = uid;
  }
}
