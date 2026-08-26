import 'package:expense_calculator/features/auth/repository/local_auth_repository.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final localAuthControllerProvider = Provider((ref) {
  return LocalAuthController(
    repository: ref.watch(localAuthRepositoryProvider),
    ref: ref,
  );
});

/// Mirrors AuthController's shape (same callback-style signup/login) so the
/// Login/Signup screens can branch between the two with minimal duplication.
class LocalAuthController {
  final LocalAuthRepository repository;
  final Ref ref;
  LocalAuthController({required this.repository, required this.ref});

  Future<void> _completeSession(String localUserId) async {
    final offlineModeController = ref.read(offlineModeControllerProvider);
    await offlineModeController.setCurrentLocalUser(localUserId);
    await offlineModeController.setOfflineMode(true);
  }

  Future<void> signupWithEmailAndPassword({
    required String email,
    required String password,
    required String name,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) async {
    try {
      final user = await repository.register(
        name: name,
        email: email,
        password: password,
      );
      await _completeSession(user.uid);
      onSuccess?.call();
    } on LocalAuthException catch (e) {
      onError?.call(e.message);
    } catch (e) {
      onError?.call(e.toString());
    }
  }

  Future<void> loginWithEmailAndPassword({
    required String email,
    required String password,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) async {
    try {
      final user = await repository.login(email: email, password: password);
      await _completeSession(user.uid);
      onSuccess?.call();
    } on LocalAuthException catch (e) {
      onError?.call(e.message);
    } catch (e) {
      onError?.call(e.toString());
    }
  }
}
