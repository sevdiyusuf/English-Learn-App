import 'package:go_router/go_router.dart';

import '../../features/profile_settings/ui/profile_settings_page.dart';
import '../../features/friends/ui/friends_page.dart';

final profileRoutes = [
  GoRoute(
    path: '/profile',
    name: 'profile',
    builder: (context, state) => const ProfileSettingsPage(),
  ),
  GoRoute(
    path: '/friends',
    name: FriendsPage.routeName,
    builder: (context, state) => const FriendsPage(),
  ),
];
