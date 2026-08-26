import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final sessionLockRepositoryProvider = Provider(
  (ref) => SessionLockRepository(),
);

/// Local, per-device storage for the app-lock feature. Deliberately not
/// Firestore-backed -- both the last-active anchor and the biometric opt-in
/// are inherently device-local (and the opt-in is additionally scoped per
/// user id so a second account on the same device gets its own setting).
class SessionLockRepository {
  static const kSessionTimeout = Duration(minutes: 1);
  static const _lastActiveKey = 'session_last_active_at';

  Future<void> touch() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _lastActiveKey,
      DateTime.now().millisecondsSinceEpoch,
    );
    print('SessionLockRepository.touch: updated lastActive to now');
  }

  /// False if never recorded yet -- nothing to compare against.
  Future<bool> isTimedOut() async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt(_lastActiveKey);
    if (ms == null) return false;
    final lastActive = DateTime.fromMillisecondsSinceEpoch(ms);
    final diff=DateTime.now().difference(lastActive);
    print('SessionLockRepository.isTimedOut: now=${DateTime.now()} lastActive=$lastActive diff=$diff');
    bool isTimedOut= diff > kSessionTimeout;
    print('SessionLockRepository.isTimedOut: $isTimedOut (lastActive=$lastActive)');
    return isTimedOut;
  }

  Future<bool> isBiometricEnabled(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('biometric_enabled_$uid') ?? false;
  }

  Future<void> setBiometricEnabled(String uid, bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled_$uid', enabled);
  }
}
