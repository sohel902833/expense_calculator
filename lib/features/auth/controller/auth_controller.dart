import 'dart:io';

import 'package:expense_calculator/features/auth/repository/auth_repository.dart';
import 'package:expense_calculator/features/auth/repository/local_auth_repository.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authControllerProvider = Provider((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return AuthController(authRepository: authRepository, ref: ref);
});

final userDataAuthProvider = FutureProvider((ref) {
  final authController = ref.watch(authControllerProvider);
  return authController.getUserData();
});

/// Firebase's own auth state as a provider, so other providers can react to
/// a different account signing in without needing the app to restart.
final firebaseAuthStateProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

/// Changes whenever *who* is signed in changes -- a different local profile
/// switched to, or a different Firebase account logged in -- regardless of
/// mode. Every per-user repository provider (`transactionRepositoryProvider`
/// and friends) watches this alongside `isOfflineModeProvider` purely so it
/// rebuilds on identity change: without it, a repository/controller created
/// while user A was signed in keeps streaming user A's query forever, even
/// after user B signs in in the same app session (StateNotifierProviders
/// are otherwise only recreated when something they watch changes).
final currentIdentityProvider = Provider<String?>((ref) {
  if (ref.watch(isOfflineModeProvider)) {
    return ref.watch(currentLocalUserIdProvider);
  }
  return ref.watch(firebaseAuthStateProvider).asData?.value?.uid;
});

/// The single source of truth for "who's signed in right now", regardless
/// of which mode resolved them -- `main.dart`'s Login/Dashboard switch
/// watches this instead of `userDataAuthProvider` directly, so neither
/// LoginScreen nor DashboardScreen needs to know which backend is active.
final sessionProvider = FutureProvider<UserModel?>((ref) async {
  final isOffline = ref.watch(isOfflineModeProvider);
  debugPrint('isOffline: $isOffline');
  if (isOffline) {
    final localUserId = ref.watch(currentLocalUserIdProvider);
    if (localUserId == null) return null;
    return ref.watch(localAuthRepositoryProvider).getUserById(localUserId);
  }
  return ref.watch(authControllerProvider).getUserData();
});

class AuthController {
  final AuthRepository authRepository;
  final Ref ref;
  AuthController({required this.authRepository, required this.ref});

  Future<UserModel?> getUserData() async {
    UserModel? user = await authRepository.getCurrentUserData();
    return user;
  }

  Future<void> logout() async {
    await authRepository.logout();
  }

  void signupWithEmailAndPassword({
    required String phoneNumber,
    required String email,
    required String password,
    required String name,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) {
    authRepository.signupWithEmailAndPassword(
      ref: ref,
      email: email,
      pasword: password,
      name: name,
      phoneNumber: phoneNumber,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  void loginWithEmailAndPassword({
    required String email,
    required String password,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) {
    authRepository.loginWithEmailAndPassword(
      ref: ref,
      email: email,
      password: password,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  void saveUserDataToFirebase(
    BuildContext context,
    String name,
    File? profilePic,
  ) {
    authRepository.saveUserDataToFirebase(
      name: name,
      profilePic: profilePic,
      ref: ref,
    );
  }

  Stream<UserModel> userDataById(String userId) {
    return authRepository.userData(userId);
  }

  void setUserState(bool isOnline) {
    authRepository.setUserState(isOnline);
  }
}
