import 'dart:io';

import 'package:expense_calculator/features/auth/repository/auth_repository.dart';
import 'package:expense_calculator/features/auth/repository/local_auth_repository.dart';
import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/models/user_model.dart';
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

/// The single source of truth for "who's signed in right now", regardless
/// of which mode resolved them -- `main.dart`'s Login/Dashboard switch
/// watches this instead of `userDataAuthProvider` directly, so neither
/// LoginScreen nor DashboardScreen needs to know which backend is active.
final sessionProvider = FutureProvider<UserModel?>((ref) async {
  final isOffline = ref.watch(isOfflineModeProvider);
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
