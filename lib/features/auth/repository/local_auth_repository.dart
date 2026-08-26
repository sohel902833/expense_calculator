import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:expense_calculator/local_db/app_local_database.dart';
import 'package:expense_calculator/models/user_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final localAuthRepositoryProvider = Provider(
  (ref) => LocalAuthRepository(db: ref.watch(appLocalDatabaseProvider)),
);

class LocalAuthException implements Exception {
  final String message;
  LocalAuthException(this.message);
  @override
  String toString() => message;
}

class LocalAuthRepository {
  final AppLocalDatabase db;
  LocalAuthRepository({required this.db});

  static String _generateSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  static String _hash(String password, String salt) {
    return sha256.convert(utf8.encode('$salt:$password')).toString();
  }

  UserModel _toUserModel(LocalUser row) => UserModel(
    name: row.name,
    uid: row.id,
    profilePic: row.profilePic ?? '',
    isOnline: row.isOnline,
    phoneNumber: row.phoneNumber,
    email: row.email,
  );

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final existing = await (db.select(
      db.localUsers,
    )..where((t) => t.email.equals(normalizedEmail))).getSingleOrNull();
    if (existing != null) {
      throw LocalAuthException('An account with this email already exists');
    }

    final salt = _generateSalt();
    final id = const Uuid().v4();
    await db
        .into(db.localUsers)
        .insert(
          LocalUsersCompanion.insert(
            id: id,
            name: name.trim(),
            email: normalizedEmail,
            passwordHash: _hash(password, salt),
            passwordSalt: salt,
          ),
        );
    final row = await (db.select(
      db.localUsers,
    )..where((t) => t.id.equals(id))).getSingle();
    return _toUserModel(row);
  }

  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final row = await (db.select(
      db.localUsers,
    )..where((t) => t.email.equals(normalizedEmail))).getSingleOrNull();
    if (row == null || _hash(password, row.passwordSalt) != row.passwordHash) {
      throw LocalAuthException('Incorrect email or password');
    }
    return _toUserModel(row);
  }

  /// Used by the session-lock overlay to re-verify the current local
  /// profile's password without a fresh email lookup.
  Future<bool> verifyPassword(String userId, String password) async {
    final row = await (db.select(
      db.localUsers,
    )..where((t) => t.id.equals(userId))).getSingleOrNull();
    if (row == null) return false;
    return _hash(password, row.passwordSalt) == row.passwordHash;
  }

  Future<UserModel?> getUserById(String id) async {
    final row = await (db.select(
      db.localUsers,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _toUserModel(row);
  }

  Future<void> updateProfile({
    required String id,
    String? name,
    String? profilePic,
  }) async {
    await (db.update(db.localUsers)..where((t) => t.id.equals(id))).write(
      LocalUsersCompanion(
        name: name != null ? Value(name) : const Value.absent(),
        profilePic: profilePic != null
            ? Value(profilePic)
            : const Value.absent(),
      ),
    );
  }
}
