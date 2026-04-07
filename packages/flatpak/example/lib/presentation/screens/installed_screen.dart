import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../responsive.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/app_status/app_status_cubit.dart';
import '../../business_logic/app_status/app_status_state.dart';
import '../../business_logic/discovery/discovery_cubit.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../business_logic/discovery/discovery_state.dart';
import '../../business_logic/system_info/system_info_cubit.dart';
import '../../business_logic/system_info/system_info_state.dart';
import '../../business_logic/system_info/system_info_cubit.dart';
import '../../business_logic/system_info/system_info_state.dart';
import '../../data/models/application_model.dart';
import '../../helpers/id_utils.dart';
import '../../app_router.dart';
import '../widgets/glassmorphism/glass_button.dart';
import '../widgets/glassmorphism/glass_container.dart';

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
    context.read<SystemInfoCubit>().loadSystemInfo();
  }

  void _refreshData() {
    widget.appStatusCubit.refresh();
    widget.discoveryCubit.loadAllApps();
    context.read<SystemInfoCubit>().refresh();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF5F7FA),
                  Color(0xFFE4E9F2),
                ],
              ),
            ),
          ),

          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.blue.withValues(alpha: 0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withValues(alpha: 0.2),
                    blurRadius: 100,
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: BlocBuilder<AppStatusCubit, AppStatusState>(
                  bloc: widget.appStatusCubit,
                  builder: (context, statusState) {
                    if (statusState is AppStatusLoading) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (statusState is AppStatusError) {
                      return _buildErrorState(statusState);
                    } else if (statusState is AppStatusLoaded) {
                      return _buildContent(context, statusState);
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(AppStatusError statusState) {
    return Center(
      child: GlassContainer(
        borderRadius: 24,
        color: Colors.white.withValues(alpha: 0.4),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
              const SizedBox(height: 16),
              Text(
                'Error: ${statusState.message}',
                style: const TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              GlassButton(
                onTap: _loadData,
                label: 'Retry',
                icon: Icons.refresh,
                textColor: Colors.white,
                glassColor: Colors.blue.withValues(alpha: 0.8),
                borderColor: Colors.white.withValues(alpha: 0.3),
                isPrimary: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return GlassContainer(
      borderRadius: 0,
      blur: 20,
      color: Colors.white.withValues(alpha: 0.6),
      borderOpacity: 0.2,
      child: SafeArea(
        bottom: false,
        child: Container(
          padding: EdgeInsets.fromLTRB(
            Responsive.scaleWithConstraints(context, 24, minSize: 16, maxSize: 40),
            Responsive.scaleWithConstraints(context, 16, minSize: 12, maxSize: 24),
            Responsive.scaleWithConstraints(context, 24, minSize: 16, maxSize: 40),
            Responsive.scaleWithConstraints(context, 20, minSize: 12, maxSize: 28),
          ),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                  color: Colors.white.withValues(alpha: 0.3),
                  width: 1
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Apps',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'khand',
                  letterSpacing: 0.5,
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
    );
  }

  Widget _buildMenuButton(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.6),
              Colors.white.withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
            )
          ]
      ),
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Material(
            color: Colors.white.withValues(alpha: 0.2),
            child: InkWell(
              onTap: () {},
              child: Icon(Icons.more_vert, color: Colors.grey[800], size: 20),
            ),
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

        final allApps = widget.discoveryCubit.allApps;
        final installedApps = allApps.where((app) {
          final shortId = AppIdUtils.extractShortId(app.id);
          return statusState.installedIds.contains(shortId);
        }).toList();

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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStorageSection(context, installedApps),
                const SizedBox(height: 32),

                if (appsWithUpdates.isNotEmpty) ...[
                  _buildSectionHeader('Apps with Updates', appsWithUpdates.length, isUpdate: true),
                  const SizedBox(height: 16),
                  _buildAppsList(context, appsWithUpdates, showUpdateButton: true),
                  const SizedBox(height: 32),
                ],

                if (appsUpToDate.isNotEmpty) ...[
                  _buildSectionHeader('Up to Date', appsUpToDate.length, isUpdate: false),
                  const SizedBox(height: 16),
                  _buildAppsList(context, appsUpToDate, showUpdateButton: false),
                ],

                if (installedApps.isEmpty)
                  _buildEmptyState(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 80),
          Icon(Icons.apps, size: 64, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No installed apps',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[500],
              fontFamily: 'general-sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, int count, {bool isUpdate = false}) {
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isUpdate
                ? Colors.blue.withValues(alpha: 0.1)
                : Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isUpdate
                  ? Colors.blue.withValues(alpha: 0.2)
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              color: isUpdate ? Colors.blue[700] : Colors.grey[700],
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStorageSection(BuildContext context, List<Application> apps) {
    return BlocBuilder<SystemInfoCubit, SystemInfoState>(
      builder: (context, systemInfoState) {
        double totalSpace = 200.0;
        double available = 0.0;
        double used = 0.0;
        
        final appsTotalBytes = apps.fold<int>(0, (sum, app) => sum + app.installedSize);
        final appsUsedGB = appsTotalBytes / (1024 * 1024 * 1024);

        if (systemInfoState is SystemInfoLoaded && systemInfoState.systemStorage != null) {
          final storage = systemInfoState.systemStorage!;
          final totalBytesSys = storage['total'] as int? ?? 1;
          final availableBytesSys = storage['available'] as int? ?? 0;
          
          totalSpace = totalBytesSys / (1024.0 * 1024.0 * 1024.0);
          available = availableBytesSys / (1024.0 * 1024.0 * 1024.0);
          used = totalSpace - available;
        } else {
          // Fallback if native system info isn't available
          used = appsUsedGB;
          available = totalSpace - used;
        }

        final percentage = totalSpace > 0 ? ((used / totalSpace) * 100).toInt().clamp(0, 100) : 0;
        final usedGBStr = used.toStringAsFixed(1);
        final availableGBStr = available.toStringAsFixed(1);

        return GlassContainer(
          borderRadius: 24,
          blur: 20,
          color: Colors.white.withValues(alpha: 0.4),
          borderOpacity: 0.4,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.storage_rounded, size: 20, color: Colors.grey[700]),
                    const SizedBox(width: 8),
                    const Text(
                      'System Storage',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'general-sans',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 12,
                            decoration: BoxDecoration(
                                color: Colors.grey.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                            ),
                            child: FractionallySizedBox(
                              alignment: Alignment.centerLeft,
                              widthFactor: totalSpace > 0 ? (used / totalSpace).clamp(0.0, 1.0) : 0.0,
                              child: Container(
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF60A5FA), Color(0xFF2563EB)],
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.blue.withValues(alpha: 0.3),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Used: $usedGBStr GB',
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                'Free: $availableGBStr GB',
                                style: const TextStyle(
                                  color: Color(0xFF2563EB),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 24),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.3),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        '${percentage}%',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  Widget _buildAppsList(BuildContext context, List<Application> apps, {required bool showUpdateButton}) {
    return Column(
      children: apps.map((app) => _buildAppItem(context, app, showUpdateButton)).toList(),
    );
  }

  Widget _buildAppItem(BuildContext context, Application app, bool showUpdateButton) {
    final sizeGB = (app.installedSize / (1024 * 1024 * 1024)).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => context.push('/app/${app.shortId}'),
        child: GlassContainer(
          borderRadius: 20,
          blur: 15,
          color: Colors.white.withValues(alpha: 0.45),
          borderOpacity: 0.3,
          child: Padding(
            padding: const EdgeInsets.all(16),
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
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'khand',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '$sizeGB GB',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[600],
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
                      _buildOpenButton(context, app),
                      const SizedBox(width: 12),
                      _buildUninstallButton(context, app),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppIcon(Application app) {
    final iconPath = _getIconPath(app);
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: iconPath != null
            ? _buildIconImage(iconPath)
            : _buildDefaultIcon(),
      ),
    );
  }

  Widget _buildIconImage(String iconPath) {
    if (iconPath.startsWith('http')) {
      return Image.network(
        iconPath, width: 52, height: 52, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => _buildDefaultIcon(),
      );
    } else {
      final file = File(iconPath);
      if (file.existsSync()) {
        return Image.file(
          file, width: 52, height: 52, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _buildDefaultIcon(),
        );
      }
      return _buildDefaultIcon();
    }
  }

  Widget _buildDefaultIcon() {
    return Container(
      width: 52, height: 52,
      color: const Color(0xFF6366F1),
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
      debugPrint('Error: $e');
    }
    return null;
  }

  Widget _buildOpenButton(BuildContext context, Application app) {
    return BlocBuilder<AppLaunchCubit, AppLaunchState>(
      bloc: widget.appLaunchCubit,
      builder: (context, state) {
        final isLaunching = widget.appLaunchCubit.isLaunching(app.id);

        if (isLaunching) {
          return GlassContainer(
            borderRadius: 16,
            color: Colors.white.withValues(alpha: 0.3),
            blur: 10,
            child: const SizedBox(
              height: 48,
              width: 80,
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          width: 90,
          child: GlassButton(
            onTap: () => widget.appLaunchCubit.launchApp(app.id),
            label: 'Open',
            icon: null,
            textColor: Colors.blue[700]!,
            glassColor: Colors.blue.withValues(alpha: 0.08),
            borderColor: Colors.blue.withValues(alpha: 0.3),
            padding: const EdgeInsets.symmetric(horizontal: 12),
          ),
        );
      },
    );
  }

  Widget _buildUninstallButton(BuildContext context, Application app) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      bloc: widget.installationCubit,
      builder: (context, installState) {
        final isUninstalling = widget.installationCubit.isOperationInProgress(app.id) &&
            widget.installationCubit.getOperationType(app.id) == 'uninstall';
        double? progress;
        if (isUninstalling && installState is InstallationInProgress) {
          if (AppIdUtils.extractShortId(installState.appId ?? '') == app.shortId) {
            progress = installState.progress;
          }
        }

        if (isUninstalling) {
          return GlassContainer(
            borderRadius: 12,
            color: Colors.red.withValues(alpha: 0.1),
            blur: 10,
            borderOpacity: 0.2,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 2,
                        color: Colors.redAccent
                    ),
                  ),
                  if (progress != null) ...[
                    const SizedBox(width: 8),
                    Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 12, color: Colors.redAccent)),
                  ]
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          width: 48,
          child: GlassButton(
            onTap: () => _showUninstallDialog(context, app),
            label: '',
            icon: Icons.delete_outline_rounded,
            textColor: Colors.red[400]!,
            glassColor: Colors.red.withValues(alpha: 0.05),
            borderColor: Colors.red.withValues(alpha: 0.2),
            padding: EdgeInsets.zero,
          ),
        );
      },
    );
  }

  Widget _buildAppUpdateButton(BuildContext context, Application app) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: widget.appStatusCubit,
      builder: (context, state) {
        final status = widget.appStatusCubit.getAppStatus(app.id);
        final isUpdating = status == AppStatus.updating;
        final progress = widget.appStatusCubit.getProgress(app.id);

        if (status != AppStatus.needsUpdate && !isUpdating) return const SizedBox.shrink();

        if (isUpdating) {
          return GlassContainer(
            borderRadius: 12,
            blur: 10,
            color: Colors.blue.withValues(alpha: 0.1),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 2,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${((progress ?? 0) * 100).toInt()}%',
                    style: TextStyle(fontSize: 12, color: Colors.blue[700], fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 48,
          child: GlassButton(
            onTap: () => widget.installationCubit.updateApp(app.id),
            label: 'Update',
            icon: Icons.system_update_alt_rounded,
            textColor: Colors.white,
            glassColor: const Color(0xFF2563EB).withValues(alpha: 0.8),
            borderColor: Colors.white.withValues(alpha: 0.4),
            isPrimary: true,
          ),
        );
      },
    );
  }

  Widget _buildUpdateAllButton(BuildContext context) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: widget.appStatusCubit,
      builder: (context, statusState) {
        if (statusState is! AppStatusLoaded) return const SizedBox.shrink();
        final count = statusState.updatableIds.length;
        if (count == 0) return const SizedBox.shrink();

        return SizedBox(
          height: 44,
          child: GlassButton(
            onTap: () {
              for (final shortId in statusState.updatableIds) {
                final app = widget.discoveryCubit.allApps.firstWhere(
                      (a) => AppIdUtils.extractShortId(a.id) == shortId,
                  orElse: () => Application.empty(),
                );
                if (app.id.isNotEmpty) widget.installationCubit.updateApp(app.id);
              }
            },
            label: 'Update All ($count)',
            icon: Icons.update,
            textColor: Colors.white,
            glassColor: const Color(0xFF2563EB).withValues(alpha: 0.85),
            borderColor: Colors.white.withValues(alpha: 0.5),
            isPrimary: true,
          ),
        );
      },
    );
  }

  void _showUninstallDialog(BuildContext context, Application app) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
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
              widget.installationCubit.uninstallApp(app.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }
}