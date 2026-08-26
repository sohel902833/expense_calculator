import 'package:expense_calculator/features/offline_mode/controller/offline_mode_controller.dart';
import 'package:expense_calculator/features/session_lock/repository/biometric_repository.dart';
import 'package:expense_calculator/features/session_lock/repository/session_lock_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BiometricSettingsScreen extends ConsumerStatefulWidget {
  static const routeName = '/biometric-settings-screen';
  const BiometricSettingsScreen({super.key});

  @override
  ConsumerState<BiometricSettingsScreen> createState() =>
      _BiometricSettingsScreenState();
}

class _BiometricSettingsScreenState
    extends ConsumerState<BiometricSettingsScreen> {
  bool _loading = true;
  bool _enabled = false;
  bool _updating = false;
  String get _uid => currentSessionUserId(
    isOffline: ref.read(isOfflineModeProvider),
    localUserId: ref.read(currentLocalUserIdProvider),
  )!;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ref
        .read(sessionLockRepositoryProvider)
        .isBiometricEnabled(_uid);
    if (!mounted) return;
    setState(() {
      _enabled = enabled;
      _loading = false;
    });
  }

  Future<void> _toggle(bool value) async {
    if (value) {
      setState(() => _updating = true);
      final biometricRepository = ref.read(biometricRepositoryProvider);
      final supported = await biometricRepository.canCheckBiometrics();
      if (!supported) {
        if (!mounted) return;
        setState(() => _updating = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "No fingerprint is set up on this device. Enroll one in your "
              "device's Settings first.",
            ),
          ),
        );
        return;
      }
      final confirmed = await biometricRepository.authenticate(
        reason: "Confirm your fingerprint to enable biometric lock",
      );
      if (!mounted) return;
      setState(() => _updating = false);
      if (!confirmed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Fingerprint not confirmed")),
        );
        return;
      }
    }

    setState(() => _updating = true);
    await ref
        .read(sessionLockRepositoryProvider)
        .setBiometricEnabled(_uid, value);
    if (!mounted) return;
    setState(() {
      _enabled = value;
      _updating = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          value ? "Biometric lock enabled" : "Biometric lock disabled",
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Biometric Lock")),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.fromLTRB(0, 8, 0, 24),
              children: [
                SwitchListTile(
                  secondary: const Icon(Icons.fingerprint_rounded),
                  title: const Text("Unlock with fingerprint"),
                  subtitle: const Text(
                    "Use your fingerprint instead of your password when the "
                    "session lock appears, for this account on this device.",
                  ),
                  value: _enabled,
                  onChanged: _updating ? null : _toggle,
                ),
                if (_updating)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                  child: Text(
                    "Your password always works as a fallback, even when "
                    "fingerprint unlock is enabled.",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
    );
  }
}
