import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final offlineModeRepositoryProvider = Provider(
  (ref) => OfflineModeRepository(),
);

/// Local, per-device storage for which auth mode the user last chose and,
/// while in offline mode, which local profile is currently signed in --
/// the offline equivalent of Firebase's own persisted auth session.
class OfflineModeRepository {
  static const _offlinePreferredKey = 'offline_mode_preferred';
  static const _currentLocalUserIdKey = 'current_local_user_id';

  Future<bool> isOfflineModePreferred() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_offlinePreferredKey) ?? false;
  }

  Future<void> setOfflineModePreferred(bool preferred) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_offlinePreferredKey, preferred);
  }

  Future<String?> currentLocalUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_currentLocalUserIdKey);
  }

  Future<void> setCurrentLocalUserId(String? uid) async {
    final prefs = await SharedPreferences.getInstance();
    if (uid == null) {
      await prefs.remove(_currentLocalUserIdKey);
    } else {
      await prefs.setString(_currentLocalUserIdKey, uid);
    }
  }
}
