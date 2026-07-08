import 'package:flutter/widgets.dart';

typedef OnLockRequested = void Function();

final class LifecycleSecurityService with WidgetsBindingObserver {
  LifecycleSecurityService({required this.onLockRequested});

  final OnLockRequested onLockRequested;

  void attach() {
    WidgetsBinding.instance.addObserver(this);
  }

  void detach() {
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      onLockRequested();
    }
  }
}
