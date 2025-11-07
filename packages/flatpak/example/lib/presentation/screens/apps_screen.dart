import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/discovery/dicovery_cubit.dart';
import '../../business_logic/discovery/discovery_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installed_apps/installed_apps_cubit.dart';
import '../../business_logic/installed_apps/installed_apps_state.dart';
import '../../data/models/application_model.dart';
import '../../helpers/id_utils.dart';
import '../widgets/appscreen_content.dart';
import '../widgets/appscreen_head.dart';

class AppDetailScreen extends StatefulWidget {
  final String appId;

  const AppDetailScreen({super.key, required this.appId});

  @override
  State<AppDetailScreen> createState() => _AppDetailScreenState();
}

class _AppDetailScreenState extends State<AppDetailScreen> {
  Application? _app;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAppDetails();
  }

  Future<void> _loadAppDetails() async {
    debugPrint('[AppDetailScreen] Loading app details for: ${widget.appId}');

    final discoveryCubit = context.read<DiscoveryCubit>();

    final allApps = discoveryCubit.allApps;
    debugPrint(
      '[AppDetailScreen] Searching in ${allApps.length} apps from discovery',
    );

    if (allApps.isNotEmpty) {
      try {
        final app = allApps.firstWhere((a) {
          final match =
              a.shortId == widget.appId ||
              a.id == widget.appId ||
              AppIdUtils.extractShortId(a.id) == widget.appId ||
              AppIdUtils.extractShortId(a.id) ==
                  AppIdUtils.extractShortId(widget.appId);
          if (match) {
            debugPrint('[AppDetailScreen] Found match: ${a.name} (${a.id})');
          }
          return match;
        });
        if (mounted) {
          setState(() {
            _app = app;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('[AppDetailScreen] App not found in allApps: $e');
      }
    }

    await discoveryCubit.loadAllApps();

    final updatedAllApps = discoveryCubit.allApps;
    if (updatedAllApps.isNotEmpty) {
      try {
        final app = updatedAllApps.firstWhere(
          (a) =>
              a.shortId == widget.appId ||
              a.id == widget.appId ||
              AppIdUtils.extractShortId(a.id) == widget.appId ||
              AppIdUtils.extractShortId(a.id) ==
                  AppIdUtils.extractShortId(widget.appId),
        );
        if (mounted) {
          setState(() {
            _app = app;
            _isLoading = false;
          });
        }
        return;
      } catch (e) {
        debugPrint('[AppDetailScreen] App not found after loading: $e');
      }
    }

    final discoveryState = discoveryCubit.state;
    if (discoveryState is DiscoveryLoaded) {
      for (final apps in discoveryState.categoryApps.values) {
        try {
          final app = apps.firstWhere(
            (a) =>
                a.shortId == widget.appId ||
                a.id == widget.appId ||
                AppIdUtils.extractShortId(a.id) == widget.appId,
          );
          if (mounted) {
            setState(() {
              _app = app;
              _isLoading = false;
            });
          }
          return;
        } catch (_) {}
      }
    }

    final installedCubit = context.read<InstalledAppsCubit>();
    final installedState = installedCubit.state;

    if (installedState is InstalledAppsLoaded) {
      try {
        final app = installedState.apps.firstWhere(
          (a) =>
              a.shortId == widget.appId ||
              a.id == widget.appId ||
              AppIdUtils.extractShortId(a.id) == widget.appId,
        );
        if (mounted) {
          setState(() {
            _app = app;
            _isLoading = false;
          });
        }
        return;
      } catch (_) {}
    }

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Loading...')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_app == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('App Not Found')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('App ${widget.appId} not found'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppscreenHead(appname: _app!.name),
      body: SingleChildScrollView(
        child: AppscreenContent(
          app: _app!,
          installedAppsCubit: context.read<InstalledAppsCubit>(),
          installationCubit: context.read<InstallationCubit>(),
          appLaunchCubit: context.read<AppLaunchCubit>(),
        ),
      ),
    );
  }
}
