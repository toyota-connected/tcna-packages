import 'dart:io';
import 'dart:ui';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/app_status/app_status_cubit.dart';
import '../../business_logic/app_status/app_status_state.dart';
import '../../business_logic/discovery/discovery_cubit.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../business_logic/discovery/discovery_state.dart';
import '../../data/models/application_model.dart';
import '../../helpers/id_utils.dart';
import '../../app_router.dart';

class InstalledScreen extends StatefulWidget {
  final AppStatusCubit appStatusCubit;
  final InstallationCubit installationCubit;
  final AppLaunchCubit appLaunchCubit;
  final DiscoveryCubit discoveryCubit;

  const InstalledScreen({
    super.key,
    required this.appStatusCubit,
    required this.installationCubit,
    required this.appLaunchCubit,
    required this.discoveryCubit,
  });

  @override
  State<InstalledScreen> createState() => _InstalledScreenState();
}

class _InstalledScreenState extends State<InstalledScreen>
    with AutomaticKeepAliveClientMixin, RouteAware {

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute) {
      routeObserver.subscribe(this, route);
    }
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    debugPrint('[InstalledScreen] Returned to screen - refreshing data');
    _refreshData();
  }

  void _loadData() {
    widget.appStatusCubit.loadAppStatus();
    widget.discoveryCubit.loadAllApps();
  }

  void _refreshData() {
    widget.appStatusCubit.refresh();
    widget.discoveryCubit.loadAllApps();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: BlocBuilder<AppStatusCubit, AppStatusState>(
              bloc: widget.appStatusCubit,
              builder: (context, statusState) {
                if (statusState is AppStatusLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (statusState is AppStatusError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error: ${statusState.message}',
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _loadData,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (statusState is AppStatusLoaded) {
                  return _buildContent(context, statusState);
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.2),
            width: 1.0,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'My Apps',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'khand',
                  ),
                ),
                Row(
                  children: [
                    _buildUpdateAllButton(context),
                    const SizedBox(width: 12),
                    _buildMenuButton(context),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
            padding: const EdgeInsets.all(8),
          ),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, AppStatusLoaded statusState) {
    return BlocBuilder<DiscoveryCubit, DiscoveryState>(
      bloc: widget.discoveryCubit,
      builder: (context, discoveryState) {
        if (discoveryState is! DiscoveryLoaded) {
          return const Center(child: CircularProgressIndicator());
        }

        // Get full app data from discovery for installed apps
        final allApps = widget.discoveryCubit.allApps;
        final installedApps = allApps.where((app) {
          final shortId = AppIdUtils.extractShortId(app.id);
          return statusState.installedIds.contains(shortId);
        }).toList();

        debugPrint(
            '[InstalledScreen] Installed IDs: ${statusState.installedIds}');
        debugPrint(
            '[InstalledScreen] Found ${installedApps.length} installed apps');

        // Separate apps that need updates
        final appsWithUpdates = installedApps.where((app) {
          final shortId = AppIdUtils.extractShortId(app.id);
          return statusState.updatableIds.contains(shortId);
        }).toList();

        final appsUpToDate = installedApps.where((app) {
          final shortId = AppIdUtils.extractShortId(app.id);
          return !statusState.updatableIds.contains(shortId);
        }).toList();

        return RefreshIndicator(
          onRefresh: () async {
            _refreshData();
            await Future.delayed(const Duration(milliseconds: 500));
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStorageSection(context, installedApps),
                const SizedBox(height: 40),
                if (appsWithUpdates.isNotEmpty) ...[
                  _buildSectionHeader(
                      'Apps with Updates', appsWithUpdates.length),
                  const SizedBox(height: 16),
                  _buildAppsList(
                    context,
                    appsWithUpdates,
                    showUpdateButton: true,
                  ),
                  const SizedBox(height: 40),
                ],
                if (appsUpToDate.isNotEmpty) ...[
                  _buildSectionHeader('Up to Date', appsUpToDate.length),
                  const SizedBox(height: 16),
                  _buildAppsList(
                    context,
                    appsUpToDate,
                    showUpdateButton: false,
                  ),
                ],
                if (installedApps.isEmpty)
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 80),
                        Icon(Icons.apps, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'No installed apps',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontFamily: 'general-sans',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            fontFamily: 'khand',
          ),
        ),
        const SizedBox(width: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: Colors.blue.shade800,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSection(BuildContext context, List<Application> apps) {
    final totalBytes = apps.fold<int>(0, (sum, app) => sum + app.installedSize);
    final usedGB = (totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1);

    const totalSpace = 200.0;
    final used = double.parse(usedGB);
    final available = totalSpace - used;
    final percentage = ((used / totalSpace) * 100).toInt();

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.25),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Storage Usage',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'general-sans',
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: used / totalSpace,
                            minHeight: 8,
                            backgroundColor: Colors.grey[200]!.withValues(
                                alpha: 0.5),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Color(0xFF2563EB),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Used: $usedGB GB',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontFamily: 'general-sans',
                              ),
                            ),
                            Text(
                              'Available: ${available.toStringAsFixed(1)} GB',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[700],
                                fontFamily: 'general-sans',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'general-sans',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppsList(BuildContext context,
      List<Application> apps, {
        required bool showUpdateButton,
      }) {
    return Column(
      children: apps
          .map((app) => _buildAppItem(context, app, showUpdateButton))
          .toList(),
    );
  }

  Widget _buildAppItem(BuildContext context,
      Application app,
      bool showUpdateButton,) {
    final sizeGB = (app.installedSize / (1024 * 1024 * 1024)).toStringAsFixed(
        2);

    return GestureDetector(
      onTap: () {
        // Navigate to app details when tapped
        context.push('/app/${app.shortId}');
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildAppIcon(app),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          app.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'khand',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$sizeGB GB',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'general-sans',
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (showUpdateButton)
                    _buildAppUpdateButton(context, app)
                  else
                    Row(
                      children: [
                        Text(
                          'Up to date',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                            fontFamily: 'general-sans',
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildOpenButton(context, app),
                        const SizedBox(width: 8),
                        _buildUninstallButton(context, app),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(Application app) {
    final iconPath = _getIconPath(app);
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: iconPath != null
            ? _buildIconImage(iconPath)
            : _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildIconImage(String iconPath) {
    if (iconPath.startsWith('http')) {
      return Image.network(
        iconPath,
        width: 48,
        height: 48,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
      );
    } else {
      final file = File(iconPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(),
        );
      }
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(Icons.apps, color: Colors.white, size: 24),
    );
  }

  String? _getIconPath(Application app) {
    try {
      if (app.appdata.isEmpty) return null;

      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final icons = appdata['icons'] as List<dynamic>?;

      if (icons != null) {
        for (final iconType in ['remote', 'cached', 'local']) {
          for (final icon in icons) {
            if (icon is Map<String, dynamic> && icon['type'] == iconType) {
              final path = icon['path'] as String?;
              if (icon['type'] == 'cached') {
                return '/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/$path';
              }
              if (path != null) return path;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('[InstalledScreen] Error parsing icon: $e');
    }
    return null;
  }

  Widget _buildOpenButton(BuildContext context, Application app) {
    return BlocBuilder<AppLaunchCubit, AppLaunchState>(
      bloc: widget.appLaunchCubit,
      builder: (context, state) {
        // Check specific app launch status
        final isLaunching = widget.appLaunchCubit.isLaunching(app.id);

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: isLaunching
                    ? null
                    : () => widget.appLaunchCubit.launchApp(app.id),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  foregroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isLaunching
                    ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFF2563EB)),
                  ),
                )
                    : const Text(
                  'Open',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUninstallButton(BuildContext context, Application app) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      bloc: widget.installationCubit,
      builder: (context, installState) {
        final isUninstalling = widget.installationCubit.isOperationInProgress(
            app.id) &&
            widget.installationCubit.getOperationType(app.id) == 'uninstall';
        double? progress;
        if (isUninstalling && installState is InstallationInProgress) {
          if (AppIdUtils.extractShortId(installState.appId ?? '') ==
              app.shortId) {
            progress = installState.progress;
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: TextButton(
                onPressed: isUninstalling
                    ? null
                    : () => _showUninstallDialog(context, app),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                  foregroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isUninstalling
                    ? (progress != null && progress > 0
                    ? _buildProgressIndicator(progress, 36)
                    : const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                  ),
                ))
                    : const Text(
                  'Uninstall',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildProgressIndicator(double progress, double buttonHeight) {
    final size = buttonHeight * 0.6;
    final percentage = (progress * 100).toInt();

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: Colors.white.withValues(alpha: 0.3),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        ),
        Text(
          '$percentage%',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  void _showUninstallDialog(BuildContext context, Application app) {
    showDialog(
      context: context,
      builder: (dialogContext) =>
          AlertDialog(
            title: const Text('Uninstall App'),
            content: Text('Are you sure you want to uninstall ${app.name}?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(dialogContext).pop();
                  debugPrint('[InstalledScreen] Uninstalling app: ${app.id}');
                  // Use the repository method directly
                  widget.installationCubit.uninstallApp(app.id);

                  // Show feedback
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Uninstalling ${app.name}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Uninstall'),
              ),
            ],
          ),
    );
  }

  Widget _buildAppUpdateButton(BuildContext context, Application app) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: widget.appStatusCubit,
      builder: (context, state) {
        final status = widget.appStatusCubit.getAppStatus(app.id);
        final isUpdating = status == AppStatus.updating;
        final progress = widget.appStatusCubit.getProgress(app.id);

        // Hide button if no update needed (double check)
        if (status != AppStatus.needsUpdate && !isUpdating) {
          return const SizedBox.shrink();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: isUpdating
                    ? Colors.grey.withValues(alpha: 0.6)
                    : const Color(0xFF3B82F6).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () => widget.installationCubit.updateApp(app.id),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: isUpdating && progress != null && progress > 0
                    ? SizedBox(
                  width: 60,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          value: progress,
                          strokeWidth: 2,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white),
                          backgroundColor: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${(progress * 100).toInt()}%',
                        style: const TextStyle(
                          fontSize: 12,
                          fontFamily: 'general-sans',
                        ),
                      ),
                    ],
                  ),
                )
                    : const Text(
                  'Update',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildUpdateAllButton(BuildContext context) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: widget.appStatusCubit,
      builder: (context, statusState) {
        if (statusState is! AppStatusLoaded) {
          return const SizedBox.shrink();
        }

        final count = statusState.updatableIds.length;
        if (count == 0) return const SizedBox.shrink();

        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2563EB).withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1.5,
                ),
              ),
              child: ElevatedButton.icon(
                onPressed: () {
                  for (final shortId in statusState.updatableIds) {
                    // Find the full App ID from the loaded apps list to be safe
                    final app = widget.discoveryCubit.allApps.firstWhere(
                          (a) => AppIdUtils.extractShortId(a.id) == shortId,
                      orElse: () => Application.empty(),
                    );

                    if (app.id.isNotEmpty) {
                      widget.installationCubit.updateApp(app.id);
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                icon: const Icon(Icons.system_update, size: 18),
                label: Text(
                  'Update All ($count)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}