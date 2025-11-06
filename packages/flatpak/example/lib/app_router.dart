import 'package:flatpak_flutter_example/screens/apps_screen.dart';
import 'package:flatpak_flutter_example/screens/category_screen.dart';
import 'package:flatpak_flutter_example/screens/discover_screen.dart';
import 'package:flatpak_flutter_example/screens/home_screen.dart';
import 'package:flatpak_flutter_example/screens/installed_screen.dart';
import 'package:flatpak_flutter_example/screens/search_screen.dart';
import 'package:flatpak_flutter_example/screens/settings_screen.dart';
import 'package:flatpak_flutter_example/widgets/splash.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

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

      // Main app routes
      GoRoute(
        path: RouteNames.home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
      ),
      GoRoute(
        path: RouteNames.discover,
        name: 'discover',
        builder: (context, state) => const DiscoverScreen(),
      ),
      GoRoute(
        path: RouteNames.installed,
        name: 'installed',
        builder: (context, state) => const InstalledScreen(),
      ),
      GoRoute(
        path: '/app/:appId',
        name: 'appDetail',
        builder: (context, state) {
          final appId = state.pathParameters['appId']!;
          return AppDetailScreen(appId: appId);
        },
      ),
      GoRoute(
        path: '/category/:categoryName',
        name: 'category',
        builder: (context, state) {
          final categoryName = state.pathParameters['categoryName']!;
          return CategoryScreen(category: categoryName);
        },
      ),
      GoRoute(
        path: RouteNames.search,
        name: 'search',
        builder: (context, state) => const SearchScreen(),
      ),
      GoRoute(
        path: RouteNames.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text('Page not found: ${state.uri}'),
      ),
    ),
  );
}