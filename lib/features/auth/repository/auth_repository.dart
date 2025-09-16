import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:expense_calculator/common/repository/common_firebase_storage_repository.dart';
import 'package:expense_calculator/common/repository/utils/utils.dart';
import 'package:expense_calculator/constants/firestore_collection_path.dart';
import 'package:expense_calculator/features/dashboard/screens/dashboard_screen.dart';
import 'package:expense_calculator/models/user_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authRepositoryProvider = Provider((ref) {
  return AuthRepository(
    auth: FirebaseAuth.instance,
    firestore: FirebaseFirestore.instance,
  );
});

class AuthRepository {
  final FirebaseAuth auth;
  final FirebaseFirestore firestore;
  AuthRepository({required this.auth, required this.firestore});

  Future<UserModel?> getCurrentUserData() async {
    var userData = await firestore
        .collection(FireSotreCollection.USER_COLLECTION)
        .doc(auth.currentUser?.uid)
        .get();
    UserModel? user;
    if (userData.data() != null) {
      user = UserModel.fromMap(userData.data()!);
    }
    return user;
  }

  Future<void> logout() async {
    await auth.signOut();
  }

  void signupWithEmailAndPassword({
    required Ref ref,
    required String email,
    required String pasword,
    required String name,
    required String phoneNumber,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) async {
    try {
      var result = await auth.createUserWithEmailAndPassword(
        email: email,
        password: pasword,
      );
      //save signup information
      await saveUserDataToFirebase(
        name: name,
        ref: ref,
        onSuccess: onSuccess,
        onError: onError,
      );
    } on FirebaseAuthException catch (e) {
      if (onError != null) {
        onError(e.message);
      }
    }
  }

  Future<void> loginWithEmailAndPassword({
    required Ref ref,
    required String email,
    required String password,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) async {
    try {
      await auth.signInWithEmailAndPassword(email: email, password: password);

      if (onSuccess != null) {
        onSuccess();
      }
    } on FirebaseAuthException catch (e) {
      if (onError != null) {
        onError(e.message);
      }
    }
  }

  Future saveUserDataToFirebase({
    required String name,
    required Ref ref,
    File? profilePic,
    Function()? onSuccess,
    Function(String? error)? onError,
  }) async {
    try {
      String uid = auth.currentUser!.uid;
      String photoUrl =
          'https://png.pngitem.com/pimgs/s/649-6490124_katie-notopoulos-katienotopoulos-i-write-about-tech-round.png';

      if (profilePic != null) {
        photoUrl = await ref
            .read(commonFirebaseStorageRepositoryProvider)
            .storeFileToFirebase('profilePic/$uid', profilePic);
      }

      var user = UserModel(
        name: name,
        uid: uid,
        profilePic: photoUrl,
        isOnline: true,
        phoneNumber: auth.currentUser?.phoneNumber ?? "",
      );

      await firestore
          .collection(FireSotreCollection.USER_COLLECTION)
          .doc(uid)
          .set(user.toMap());

      if (onSuccess != null) {
        onSuccess();
      }
    } catch (e) {
      print(e);
      if (onError != null) {
        onError(e.toString());
      }
    }
  }

  Stream<UserModel> userData(String userId) {
    return firestore
        .collection(FireSotreCollection.USER_COLLECTION)
        .doc(userId)
        .snapshots()
        .map((event) => UserModel.fromMap(event.data()!));
  }

  void setUserState(bool isOnline) async {
    await firestore
        .collection(FireSotreCollection.USER_COLLECTION)
        .doc(auth.currentUser!.uid)
        .update({'isOnline': isOnline});
  }
}
