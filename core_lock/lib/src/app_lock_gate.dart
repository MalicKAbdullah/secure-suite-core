import 'package:core_lock/src/lock_controller.dart';
import 'package:core_lock/src/lock_screen.dart';
import 'package:flutter/material.dart';

/// Sits above the router (via MaterialApp.builder) and covers the whole app
/// with [LockScreen] while locked. The navigator stays mounted underneath, so
/// unlocking restores exactly where the user was. Forwards lifecycle changes
/// to the controller for the background re-lock timer.
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
    final locked = widget.controller.isLocked;
    return Stack(
      children: [
        Offstage(offstage: locked, child: widget.child),
        if (locked) LockScreen(controller: widget.controller),
      ],
    );
  }
}
