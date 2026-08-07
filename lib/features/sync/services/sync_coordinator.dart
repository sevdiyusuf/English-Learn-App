import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../auth/models/app_user.dart';

enum SyncStatus { idle, syncing, upToDate, error }

/// Abstract contract for sync coordinator lifecycle.
abstract class SyncCoordinator extends ChangeNotifier {
  SyncCoordinator.custom();

  SyncStatus get status;
  Future<void> onUserLogin(AppUser user);
  Future<void> onUserLogout();
  Future<void> triggerSync();
}
