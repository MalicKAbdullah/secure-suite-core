import 'package:core_lock/src/lock_controller.dart';
import 'package:core_lock/src/lock_screen.dart';
import 'package:core_lock/src/recovery_key_view.dart';
import 'package:flutter/material.dart';

/// Sits above the router (via MaterialApp.builder) and covers the whole app
/// with [LockScreen] while locked. The navigator stays mounted underneath, so
/// unlocking restores exactly where the user was. After an unlock that has
/// [LockController.recoveryPromptDue], it covers the app with the one-time
/// [RecoveryKeyOffer] instead. Forwards lifecycle changes to the controller
/// for the background re-lock timer.
///
/// Wire it without any state-management dependency: pass a [LockController]
/// (however your app builds it) and the router child.
final class AppLockGate extends StatefulWidget {
  const AppLockGate({required this.controller, required this.child, super.key});

  final LockController controller;
  final Widget child;

  @override
  State<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends State<AppLockGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    widget.controller.addListener(_onChange);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.controller.removeListener(_onChange);
    super.dispose();
  }

  void _onChange() {
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    widget.controller.onLifecycleChanged(state);
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    final locked = c.isLocked;
    final offer = c.recoveryPromptDue;
    return Stack(
      children: [
        Offstage(offstage: locked || offer, child: widget.child),
        if (locked)
          _OverlayHost(child: LockScreen(controller: c))
        else if (offer)
          _OverlayHost(child: RecoveryKeyOffer(controller: c)),
      ],
    );
  }
}

/// The gate sits above the app's navigator, so its covers have no Overlay
/// ancestor; text fields (selection handles, toolbar) and tooltips need one.
final class _OverlayHost extends StatefulWidget {
  const _OverlayHost({required this.child});

  final Widget child;

  @override
  State<_OverlayHost> createState() => _OverlayHostState();
}

class _OverlayHostState extends State<_OverlayHost> {
  late final OverlayEntry _entry = OverlayEntry(builder: (_) => widget.child);

  @override
  void didUpdateWidget(_OverlayHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _entry.markNeedsBuild();
  }

  @override
  Widget build(BuildContext context) => Overlay(initialEntries: [_entry]);
}
