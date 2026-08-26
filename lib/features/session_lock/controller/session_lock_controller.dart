import 'package:expense_calculator/features/session_lock/repository/session_lock_repository.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whether the app-lock overlay should currently be shown.
final sessionLockedProvider = StateProvider<bool>((ref) => false);

final sessionLockControllerProvider = Provider((ref) {
  return SessionLockController(
    repository: ref.watch(sessionLockRepositoryProvider),
    ref: ref,
  );
});

class SessionLockController {
  final SessionLockRepository repository;
  final Ref ref;
  SessionLockController({required this.repository, required this.ref});

  /// Only ever turns the lock *on* -- never call this to unlock.
  Future<void> checkAndLockIfNeeded() async {
    if (FirebaseAuth.instance.currentUser == null) return;
    if (await repository.isTimedOut()) {
      ref.read(sessionLockedProvider.notifier).state = true;
    }
  }

  /// Resets the timeout anchor to now, e.g. on backgrounding or a fresh
  /// successful login/unlock.
  Future<void> markActiveNow() => repository.touch();

  /// Call only after a real successful password/biometric check.
  Future<void> unlock() async {
    await markActiveNow();
    ref.read(sessionLockedProvider.notifier).state = false;
  }

  /// Clears the locked flag without touching the timeout anchor -- used on
  /// logout so a later fresh login doesn't start in a locked state.
  void resetOnLogout() {
    ref.read(sessionLockedProvider.notifier).state = false;
  }
}
