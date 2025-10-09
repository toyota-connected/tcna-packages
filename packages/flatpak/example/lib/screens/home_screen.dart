import 'dart:core';
import 'package:flatpak_flutter_example/screens/apps_screen.dart';
import 'package:flatpak_flutter_example/widgets/cateogry_section.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../widgets/top_bar.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:flatpak_flutter_example/services/AppProvider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const List<String> categoryOrder = [
    'Popular Apps',
    'Productivity',
    'Development',
    'Graphics & Photography',
    'Audio & Video',
    'Gaming',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const AppTopBar(),
      body: Consumer<AppsProvider>(
        builder: (context, appsProvider, child) {
          return RefreshIndicator(
              onRefresh: () async {
                await appsProvider.loadInstalled();
                await appsProvider.loadRemotes();
        },
        child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 32),

                    ...categoryOrder.map((categoryName) {
                      final apps = appsProvider.getCategoryApps(categoryName);
                      final isLoading = appsProvider.isCategoryLoading(categoryName);

                      return Column(
                        children: [
                          CategorySection(
                            category_heading: categoryName,
                            apps: apps,
                            isLoading: isLoading,
                            onTap: _navigateToApp,
                            onInstall: _handleInstall,
                          ),
                          const SizedBox(height: 32),
                        ],
                      );
                    }).toList(),
                  ],
                ),
              ),
            );
          },
      ),
    );
  }


  void _navigateToApp(Application app) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AppsScreen(application: app),
      ),
    );
  }

  Future<void> _handleInstall(Application app) async {
    final appsProvider = context.read<AppsProvider>();

    if (appsProvider.isAppInstalled(app.id)) {
      _openApp(app);
    } else if (appsProvider.isAppInstalling(app.id)) {
      return;
    } else {
      final success = await appsProvider.installApp(app.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? '${app.name} installed successfully!'
                  : 'Failed to install ${app.name}',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  void _openApp(Application app) {
    // TODO: Implement app opening logic
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${app.name}...'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  /// TODO : Get Button
  /// Should make a modern dragger widget to get app bottom sheet when pressing "Get" button
  /// If Application is Already installed "Get" button => "open" button


}