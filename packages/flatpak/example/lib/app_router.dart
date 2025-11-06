import 'package:flatpak_flutter_example/presentation/screens/apps_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/category_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/discover_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/home_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/installed_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/navigation_menu.dart';
import 'package:flatpak_flutter_example/presentation/screens/search_screen.dart';
import 'package:flatpak_flutter_example/presentation/screens/settings_screen.dart';
import 'package:flatpak_flutter_example/presentation/widgets/splash.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'business_logic/app_launch/app_launch_cubit.dart';
import 'business_logic/discovery/dicovery_cubit.dart';
import 'business_logic/installation/installation_cubit.dart';
import 'business_logic/installed_apps/installed_apps_cubit.dart';

class RouteNames {
  static const String splash = '/';
  static const String home = '/home';
  static const String discover = '/discover';
  static const String installed = '/installed';
  static const String appDetail = '/app/:appId';
  static const String search = '/search';
  static const String settings = '/settings';
  static const String category = '/category/:categoryName';
}

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: RouteNames.splash,
    routes: [
      GoRoute(
        path: RouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      ShellRoute(
        builder: (context, state, child) {
          return NavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: RouteNames.home,
            name: 'home',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const HomeScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.discover,
            name: 'discover',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const DiscoverScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.installed,
            name: 'installed',
            pageBuilder: (context, state) => NoTransitionPage(
              child: InstalledScreen(
                installedAppsCubit: context.read<InstalledAppsCubit>(),
                installationCubit: context.read<InstallationCubit>(),
                appLaunchCubit: context.read<AppLaunchCubit>(),
                discoveryCubit: context.read<DiscoveryCubit>(),
              ),
            ),
          ),
          GoRoute(
            path: RouteNames.search,
            name: 'search',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SearchScreen(),
            ),
          ),
          GoRoute(
            path: RouteNames.settings,
            name: 'settings',
            pageBuilder: (context, state) => NoTransitionPage(
              child: const SettingsScreen(),
            ),
          ),
        ],
      ),

      GoRoute(
        path: '/app/:appId',
        name: 'appDetail',
        builder: (context, state) {
          final appId = state.pathParameters['appId']!;
          return AppDetailScreen(appId: appId);
        },
      ),
    ],
  );
}