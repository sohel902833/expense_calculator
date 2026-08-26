import 'package:expense_calculator/features/session_lock/controller/session_lock_controller.dart';
import 'package:expense_calculator/features/session_lock/widgets/session_lock_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Wraps the whole app (via MaterialApp.builder) so a stale session can be
/// caught and locked regardless of which screen is currently open, without
/// touching every screen individually.
class SessionLockGate extends ConsumerStatefulWidget {
  final Widget child;
  const SessionLockGate({required this.child, super.key});

  @override
  ConsumerState<SessionLockGate> createState() => _SessionLockGateState();
}

class _SessionLockGateState extends ConsumerState<SessionLockGate>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Covers cold start after the process was killed for longer than the
    // timeout while still logged in -- Firebase restores the session
    // silently with no login screen in between, so this is the only hook
    // for that case.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(sessionLockControllerProvider).checkAndLockIfNeeded();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = ref.read(sessionLockControllerProvider);
    // `inactive` is bidirectional -- it also fires transiently right before
    // `resumed` when *returning* to the app (transition animations, system
    // dialogs, the biometric prompt itself), not just when leaving. Touching
    // the timestamp on it would reset the anchor immediately before the
    // resume check reads it, making isTimedOut() always see a ~0 diff. Only
    // `paused` reliably means "actually backgrounded".
    if (state == AppLifecycleState.paused) {
      controller.markActiveNow();
    } else if (state == AppLifecycleState.resumed) {
      controller.checkAndLockIfNeeded();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = ref.watch(sessionLockedProvider);
    // Deliberately not intercepting the system back button here:
    // BackButtonListener/PopScope both require a Router/Navigator ancestor,
    // which this context doesn't have (MaterialApp.builder sits above the
    // Navigator, not inside it -- see session_lock_overlay.dart's doc
    // comment for the same constraint). It isn't load-bearing for security
    // either way: pressing back while locked either pops a route the
    // overlay is already fully covering, or backgrounds the app -- and
    // `locked` stays true in memory either way, so the overlay is exactly
    // where it was when the app is next shown.
    return Stack(
      children: [widget.child, if (locked) const SessionLockOverlay()],
    );
  }
}
