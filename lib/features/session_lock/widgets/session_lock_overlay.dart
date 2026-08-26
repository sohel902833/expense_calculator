import 'dart:ui';

import 'package:expense_calculator/constants/color.dart';
import 'package:expense_calculator/features/auth/controller/auth_controller.dart';
import 'package:expense_calculator/features/auth/screens/login_screen.dart';
import 'package:expense_calculator/features/session_lock/controller/session_lock_controller.dart';
import 'package:expense_calculator/features/session_lock/repository/biometric_repository.dart';
import 'package:expense_calculator/features/session_lock/repository/session_lock_repository.dart';
import 'package:expense_calculator/router/router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Full-screen, non-route overlay -- lives as a sibling of the Navigator (see
/// SessionLockGate), not inside it, so it blurs and blocks whatever screen
/// was open without adding itself to the back stack. Because of that, it
/// cannot use `Navigator.of(context)` / `showDialog` (no Navigator ancestor
/// from here) -- the one navigation it needs (logout) goes through
/// [rootNavigatorKey], and "confirm logout" is inline rather than a dialog.
class SessionLockOverlay extends ConsumerStatefulWidget {
  const SessionLockOverlay({super.key});

  @override
  ConsumerState<SessionLockOverlay> createState() =>
      _SessionLockOverlayState();
}

enum _Mode { fingerprint, password }

class _SessionLockOverlayState extends ConsumerState<SessionLockOverlay> {
  final _passwordController = TextEditingController();
  bool? _biometricEnabled;
  _Mode _mode = _Mode.password;
  bool _submitting = false;
  bool _confirmingLogout = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadBiometricPreference() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final enabled = await ref
        .read(sessionLockRepositoryProvider)
        .isBiometricEnabled(uid);
    if (!mounted) return;
    setState(() {
      _biometricEnabled = enabled;
      _mode = enabled ? _Mode.fingerprint : _Mode.password;
    });
    if (enabled) _attemptBiometric();
  }

  Future<void> _attemptBiometric() async {
    setState(() {
      _submitting = true;
      _error = null;
    });
    final success = await ref
        .read(biometricRepositoryProvider)
        .authenticate(reason: "Unlock to continue");
    if (!mounted) return;
    if (success) {
      await ref.read(sessionLockControllerProvider).unlock();
      return;
    }
    setState(() {
      _submitting = false;
      _error = "Fingerprint not recognized. Try again or use your password.";
    });
  }

  Future<void> _submitPassword() async {
    final password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _error = "Enter your password");
      return;
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || user.email == null) {
      setState(() => _error = "No active session found");
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await user.reauthenticateWithCredential(
        EmailAuthProvider.credential(email: user.email!, password: password),
      );
      await ref.read(sessionLockControllerProvider).unlock();
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.message ?? "Incorrect password";
      });
    }
  }

  Future<void> _logout() async {
    setState(() => _submitting = true);
    await ref.read(authControllerProvider).logout();
    ref.read(sessionLockControllerProvider).resetOnLogout();
    rootNavigatorKey.currentState?.pushNamedAndRemoveUntil(
      LoginScreen.routeName,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Positioned.fill(
      // This overlay is a sibling of the app's routed content (see
      // SessionLockGate), not a screen of its own, so it doesn't inherit a
      // Material ancestor from any Scaffold -- TextField/buttons below need
      // one explicitly. `transparency` so it doesn't paint an opaque layer.
      child: Material(
        type: MaterialType.transparency,
        child: Stack(
        children: [
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                color: (isDark ? Colors.black : Colors.white).withValues(
                  alpha: 0.55,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.25),
                      blurRadius: 30,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Icon(Icons.lock_outline_rounded, size: 40, color: tabColor),
                    const SizedBox(height: 12),
                    Text(
                      "Session Locked",
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Verify your identity to continue",
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    if (_biometricEnabled == true) ...[
                      _modeToggle(),
                      const SizedBox(height: 16),
                    ],
                    if (_mode == _Mode.fingerprint && _biometricEnabled == true)
                      _fingerprintView()
                    else
                      _passwordView(),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE74C3C),
                          fontSize: 13,
                        ),
                      ),
                    ],
                    const SizedBox(height: 18),
                    _logoutSection(),
                  ],
                ),
              ),
            ),
          ),
        ],
        ),
      ),
    );
  }

  Widget _modeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.grey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          _toggleOption(
            label: "Fingerprint",
            icon: Icons.fingerprint_rounded,
            selected: _mode == _Mode.fingerprint,
            onTap: () {
              setState(() {
                _mode = _Mode.fingerprint;
                _error = null;
              });
              _attemptBiometric();
            },
          ),
          _toggleOption(
            label: "Password",
            icon: Icons.password_rounded,
            selected: _mode == _Mode.password,
            onTap: () => setState(() {
              _mode = _Mode.password;
              _error = null;
            }),
          ),
        ],
      ),
    );
  }

  Widget _toggleOption({
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: selected ? tabColor.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? tabColor : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: selected ? tabColor : Colors.grey),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? tabColor : Colors.grey,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fingerprintView() {
    return Column(
      children: [
        IconButton(
          onPressed: _submitting ? null : _attemptBiometric,
          iconSize: 56,
          icon: Icon(Icons.fingerprint_rounded, color: tabColor),
        ),
        const SizedBox(height: 4),
        Text(
          _submitting ? "Scanning..." : "Tap to scan again",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  Widget _passwordView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _passwordController,
          obscureText: true,
          enabled: !_submitting,
          decoration: const InputDecoration(
            labelText: "Password",
            prefixIcon: Icon(Icons.lock_outline_rounded),
          ),
          onSubmitted: (_) => _submitting ? null : _submitPassword(),
        ),
        const SizedBox(height: 14),
        ElevatedButton(
          onPressed: _submitting ? null : _submitPassword,
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 14),
            backgroundColor: tabColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _submitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Colors.white,
                  ),
                )
              : const Text(
                  "Unlock",
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }

  Widget _logoutSection() {
    if (!_confirmingLogout) {
      return TextButton(
        onPressed: _submitting
            ? null
            : () => setState(() => _confirmingLogout = true),
        child: const Text("Logout instead"),
      );
    }
    return Column(
      children: [
        const Text(
          "Logout and return to the login screen?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _confirmingLogout = false),
                child: const Text("Cancel"),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: FilledButton(
                onPressed: _submitting ? null : _logout,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFE74C3C),
                ),
                child: const Text("Logout"),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
