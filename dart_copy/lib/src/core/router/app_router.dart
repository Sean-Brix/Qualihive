import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../features/auth/application/auth_providers.dart';
import '../../features/auth/domain/account.dart';
import '../../features/auth/presentation/profile_screen.dart';
import '../../features/auth/presentation/sign_in_screen.dart';
import '../../features/history/presentation/batch_detail_screen.dart';
import '../../features/history/presentation/history_screen.dart';
import '../../features/monitoring/application/monitoring_providers.dart';
import '../../features/monitoring/presentation/device_screen.dart';
import '../../features/monitoring/presentation/home_screen.dart';
import '../../features/monitoring/presentation/live_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/reports/presentation/export_screen.dart';
import '../../features/settings/presentation/about_screen.dart';
import '../../features/settings/presentation/more_screen.dart';
import '../../features/settings/presentation/thresholds_screen.dart';
import '../../features/statistics/presentation/statistics_screen.dart';

part 'app_router.g.dart';

/// Single place where every route is declared.
///
/// The five tabs of specification §10 sit in a [StatefulShellRoute] so each
/// keeps its own navigation stack and scroll position when you switch between
/// them. Everything the More tab leads to is a child of that branch, so a
/// back gesture from Settings lands on More rather than on Home.
@Riverpod(keepAlive: true)
GoRouter appRouter(Ref ref) {
  // GoRouter takes a Listenable, not a provider, so the session is mirrored
  // into one. Rebuilding the router itself would reset every navigation stack.
  final session = ValueNotifier<AsyncValue<Account?>>(
    const AsyncLoading<Account?>(),
  );
  ref.listen<AsyncValue<Account?>>(
    sessionControllerProvider,
    (_, next) => session.value = next,
    fireImmediately: true,
  );
  ref.onDispose(session.dispose);

  return GoRouter(
    initialLocation: HomeScreen.path,
    refreshListenable: session,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      // Still reading the stored session — hold still rather than bouncing the
      // user to Sign in and straight back out again.
      if (session.value.isLoading) return null;

      final signedIn = session.value.value != null;
      final atSignIn = state.matchedLocation == SignInScreen.path;

      if (!signedIn && !atSignIn) return SignInScreen.path;
      if (signedIn && atSignIn) return HomeScreen.path;
      return null;
    },
    routes: <RouteBase>[
      GoRoute(
        path: SignInScreen.path,
        name: SignInScreen.name,
        builder: (context, state) => const SignInScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HomeScreen.path,
                name: HomeScreen.name,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: LiveScreen.path,
                name: LiveScreen.name,
                builder: (context, state) => const LiveScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: StatisticsScreen.path,
                name: StatisticsScreen.name,
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: HistoryScreen.path,
                name: HistoryScreen.name,
                builder: (context, state) => const HistoryScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: ':code',
                    name: BatchDetailScreen.name,
                    builder: (context, state) => BatchDetailScreen(
                      code: state.pathParameters['code']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: MoreScreen.path,
                name: MoreScreen.name,
                builder: (context, state) => const MoreScreen(),
                routes: <RouteBase>[
                  GoRoute(
                    path: NotificationsScreen.segment,
                    name: NotificationsScreen.name,
                    builder: (context, state) => const NotificationsScreen(),
                  ),
                  GoRoute(
                    path: DeviceScreen.segment,
                    name: DeviceScreen.name,
                    builder: (context, state) => const DeviceScreen(),
                  ),
                  GoRoute(
                    path: ThresholdsScreen.segment,
                    name: ThresholdsScreen.name,
                    builder: (context, state) => const ThresholdsScreen(),
                  ),
                  GoRoute(
                    path: ExportScreen.segment,
                    name: ExportScreen.name,
                    builder: (context, state) => const ExportScreen(),
                  ),
                  GoRoute(
                    path: ProfileScreen.segment,
                    name: ProfileScreen.name,
                    builder: (context, state) => const ProfileScreen(),
                  ),
                  GoRoute(
                    path: AboutScreen.segment,
                    name: AboutScreen.name,
                    builder: (context, state) => const AboutScreen(),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class _ShellScaffold extends ConsumerWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watched here rather than on a screen so the disconnection watchdog runs
    // regardless of which tab is on top.
    ref.watch(connectionWatchdogProvider);

    final unread = ref.watch(unreadAlertCountProvider).value ?? 0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tapping the current tab returns it to its root.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: <NavigationDestination>[
          const NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          const NavigationDestination(
            icon: Icon(Icons.monitor_heart_outlined),
            selectedIcon: Icon(Icons.monitor_heart),
            label: 'Live',
          ),
          const NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights),
            label: 'Statistics',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.more_horiz_outlined),
            ),
            selectedIcon: Badge.count(
              count: unread,
              isLabelVisible: unread > 0,
              child: const Icon(Icons.more_horiz),
            ),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
