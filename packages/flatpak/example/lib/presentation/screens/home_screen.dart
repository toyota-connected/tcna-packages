import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../data/models/application_model.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/discovery/dicovery_cubit.dart';
import '../../business_logic/discovery/discovery_state.dart';
import '../../business_logic/event_listener/event_listener_bloc.dart';
import '../../business_logic/event_listener/event_listener_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installed_apps/installed_apps_cubit.dart';
import '../widgets/cateogry_section.dart';
import '../widgets/hero_widget.dart';
import '../widgets/top_bar.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
      body: BlocBuilder<DiscoveryCubit, DiscoveryState>(
        builder: (context, state) {
          if (state is DiscoveryLoading && state.category == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is DiscoveryError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${state.message}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<DiscoveryCubit>().initialize();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is DiscoveryLoaded) {
            return RefreshIndicator(
              onRefresh: () async {
                await context.read<DiscoveryCubit>().initialize();
              },
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Connection status indicator
                  SliverToBoxAdapter(
                    child: BlocBuilder<EventListenerBloc, EventListenerState>(
                      builder: (context, state) {
                        if (state is EventListenerListening) {
                          return Container(
                            padding: const EdgeInsets.all(8),
                            color: Colors.green.withOpacity(0.2),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_circle, color: Colors.green, size: 16),
                                SizedBox(width: 8),
                                Text('Connected to Flatpak'),
                              ],
                            ),
                          );
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: HeroWidget(
                      title: "Discover, Install, and Enjoy Apps on AGL Store.",
                      imageUrl: 'assets/images/Hero.png',
                      subtitle: "Explore a wide range of applications available through Flatpak.",
                    ),
                  ),
                  // Category sections
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                          (context, index) {
                        final categoryName = categoryOrder[index];
                        final apps = state.categoryApps[categoryName] ?? [];
                        final isLoading =
                        context.read<DiscoveryCubit>().isCategoryLoading(categoryName);

                        return Column(
                          children: [
                            CategorySection(
                              category_heading: categoryName,
                              apps: apps,
                              isLoading: isLoading,
                              onTap: (app) => _navigateToApp(app, context),
                              onInstall: (app) => _handleInstall(app, context),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                      childCount: categoryOrder.length,
                    ),
                  ),
                ],
              ),
            );
          }

          return const Center(child: Text('Initializing...'));
        },
      ),
    );
  }

  void _navigateToApp(Application app, BuildContext context) {
    context.push('/app/${app.shortId}');
  }

  Future<void> _handleInstall(Application app, BuildContext context) async {
    final installationCubit = context.read<InstallationCubit>();
    final launchCubit = context.read<AppLaunchCubit>();

    final isInstalled = context.read<InstalledAppsCubit>().isInstalled(app.id);

    if (isInstalled) {
      await launchCubit.launchApp(app.id);
    } else if (!installationCubit.isOperationInProgress(app.id)) {
      await installationCubit.installApp(app.id);
    }
  }
}