import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/app_status/app_status_cubit.dart';
import '../../business_logic/app_status/app_status_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../data/models/application_model.dart';
import '../../helpers/id_utils.dart';
import 'package:flatpak_flutter_example/responsive.dart';
import 'package:flatpak_flutter_example/presentation/widgets/screenshot_widget.dart';
import 'app_info.dart';

class AppscreenContent extends StatelessWidget {
  const AppscreenContent({
    super.key,
    required this.app,
    required this.appStatusCubit,
    required this.installationCubit,
    required this.appLaunchCubit,
  });

  final Application app;
  final AppStatusCubit appStatusCubit;
  final InstallationCubit installationCubit;
  final AppLaunchCubit appLaunchCubit;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
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
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 54,
                    vertical: 15,
                  ),
                  child: _buildAppHeader(context),
                ),
              ),
            ),
          ),

          const SizedBox(height: 18),
          _buildScreenshot(context),
          const SizedBox(height: 18),
          _buildInfo(context),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildAppHeader(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildAppInfoRow(context, app),
        ),
      ],
    );
  }

  Widget _buildAppInfoRow(BuildContext context, Application app) {
    final String developerName = _getDeveloper(app);
    final List<Widget> categories = _getCategories(context, app);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAppIcon(context, app),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  app.name,
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: Responsive.scale(context, 18.0).clamp(15.0, 20.0),
                    fontWeight: FontWeight.w600,
                    fontFamily: 'khand',
                    height: 1.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 5),
                if (developerName.isNotEmpty)
                  Text(
                    developerName,
                    style: TextStyle(
                      color: const Color(0xFF8B8B8B),
                      fontSize:
                      Responsive.scale(context, 13.0).clamp(11.0, 15.0),
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                if (categories.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width - 200,
                    ),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: categories,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          _buildActionButtons(context),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: appStatusCubit,
      builder: (context, statusState) {
        if (statusState is AppStatusInitial) {
          return const SizedBox.shrink();
        }

        final isInstalled = appStatusCubit.isInstalled(app.id);
        final needsUpdate = appStatusCubit.needsUpdate(app.id);
        final status = appStatusCubit.getAppStatus(app.id);

        if (isInstalled) {
          return Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildOpenButton(context),
              const SizedBox(width: 12),
              if (needsUpdate || status == AppStatus.updating)
                _buildUpdateButton(context)
              else
                _buildUninstallButton(context),
            ],
          );
        } else {
          return _buildInstallButton(context);
        }
      },
    );
  }

  Widget _buildInstallButton(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      bloc: installationCubit,
      builder: (context, installState) {
        final isInstalling = installationCubit.isOperationInProgress(app.id) &&
            installationCubit.getOperationType(app.id) == 'install';

        double? progress;
        if (isInstalling && installState is InstallationInProgress) {
          if (AppIdUtils.extractShortId(installState.appId ?? '') ==
              app.shortId) {
            progress = installState.progress;
          }
        }

        return _GlassActionButton(
          label: isInstalling ? 'Installing...' : 'Install',
          baseColor: const Color(0xFF2563EB), // Blue
          onTap:
          isInstalling ? null : () => installationCubit.installApp(app.id),
          isLoading: isInstalling,
          progress: progress,
          isFilled: true,
        );
      },
    );
  }

  Widget _buildOpenButton(BuildContext context) {
    return BlocBuilder<AppLaunchCubit, AppLaunchState>(
      bloc: appLaunchCubit,
      builder: (context, state) {
        final isLaunching = appLaunchCubit.isLaunching(app.id);

        return _GlassActionButton(
          label: isLaunching ? 'Opening...' : 'Open',
          baseColor: const Color(0xFF2563EB), // Blue
          onTap: isLaunching ? null : () => appLaunchCubit.launchApp(app.id),
          isLoading: isLaunching,
          isFilled: true,
        );
      },
    );
  }

  Widget _buildUpdateButton(BuildContext context) {
    return BlocBuilder<AppStatusCubit, AppStatusState>(
      bloc: appStatusCubit,
      builder: (context, state) {
        final isUpdating =
            appStatusCubit.getAppStatus(app.id) == AppStatus.updating;
        final progress = appStatusCubit.getProgress(app.id);

        return _GlassActionButton(
          label: 'Update',
          baseColor: Colors.orange.shade700,
          onTap: isUpdating ? null : () => installationCubit.updateApp(app.id),
          isLoading: isUpdating,
          progress: progress,
          isFilled: true,
        );
      },
    );
  }

  Widget _buildUninstallButton(BuildContext context) {
    return BlocBuilder<InstallationCubit, InstallationState>(
      bloc: installationCubit,
      builder: (context, state) {
        final isUninstalling =
            installationCubit.isOperationInProgress(app.id) &&
                installationCubit.getOperationType(app.id) == 'uninstall';

        return _GlassActionButton(
          label: isUninstalling ? 'Uninstalling...' : 'Uninstall',
          baseColor: Colors.red.shade600, // Red
          onTap: isUninstalling ? null : () => _showUninstallDialog(context),
          isLoading: isUninstalling,
          isFilled: true,
        );
      },
    );
  }

  void _showUninstallDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Uninstall App'),
        content: Text(
          'Are you sure you want to uninstall ${app.name}? This will remove the app and all its data.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              installationCubit.uninstallApp(app.id);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Uninstall'),
          ),
        ],
      ),
    );
  }

  Widget _buildAppIcon(BuildContext context, Application app) {
    final cardSize = Responsive.scale(context, 80).clamp(68.0, 92.0);
    final iconSize = cardSize * 0.7;

    return Container(
      width: cardSize,
      height: cardSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: _buildIcon(iconSize),
        ),
      ),
    );
  }

  Widget _buildIcon(double size) {
    final iconPath = _getIconPath(app);
    if (iconPath != null) {
      if (iconPath.startsWith('http')) {
        return Image.network(
          iconPath,
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(size),
        );
      } else {
        return Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(size),
        );
      }
    }
    return _buildDefaultIcon(size);
  }

  Widget _buildDefaultIcon(double size) {
    return Image.asset(
      'assets/icons/default_app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Icon(
        Icons.apps,
        size: size * 0.5,
        color: Colors.grey,
      ),
    );
  }

  Widget _buildScreenshot(BuildContext context) {
    List<String>? images = _getScreenshotsimage(app);
    List<String>? captions = _getScreenshotsCaption(app);

    if (images == null || images.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      height: Responsive.responsiveValue(
        context,
        mobile: Responsive.height(context) * 0.3,
        tablet: Responsive.height(context) * 0.4,
        desktop: Responsive.height(context) * 0.5,
      ).clamp(300.0, 600.0),
      padding: EdgeInsets.symmetric(
        horizontal: Responsive.responsiveValue(context,
            mobile: 16.0, tablet: 24.0, desktop: 32.0),
        vertical: 16.0,
      ),
      child: Screenshot(images: images, captions: captions),
    );
  }

  Widget _buildInfo(BuildContext context) {
    final String description = _getDescription(app);
    final String url = _getUrl(app);
    final String contentRating = _getContentRating(app);
    final String size = _getInstalledSize(app);
    final String version = _getReleaseVersion(app);
    final String lastUpdate = _getReleaseTimestamp(app);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
      alignment: Alignment.topLeft,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(
              color: Colors.white.withValues(alpha: 0.2), width: 1.0),
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
          filter: ImageFilter.blur(sigmaY: 10, sigmaX: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "About this app",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'general-sans',
                ),
              ),
              const SizedBox(height: 30),
              Text(
                description.isNotEmpty
                    ? description
                    : "No description available.",
                style: const TextStyle(
                  color: Color(0xFF4B5563),
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                  fontFamily: 'general-sans',
                ),
              ),
              const SizedBox(height: 30),
              Container(
                width: double.infinity,
                height: 1,
                color: Colors.grey.shade300,
              ),
              const Padding(
                padding: EdgeInsets.all(12.0),
                child: Text(
                  "App Info",
                  style: TextStyle(
                    color: Colors.black87,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
              AppInfo(
                version: version.isNotEmpty ? version : "Unknown",
                License: app.license.isNotEmpty ? app.license : "Unknown",
                last_upadate: lastUpdate.isNotEmpty ? lastUpdate : "-",
                url: url,
                content_rating: contentRating,
                size: size,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getContentRating(Application app) {
    try {
      if (app.contentRatingType.isEmpty) return '';
      if (app.contentRating.isNotEmpty) {
        return app.contentRating.keys.join(", ");
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  String _getInstalledSize(Application app) {
    try {
      if (app.installedSize <= 0) return '';
      const List<String> units = ["B", "KiB", "MiB", "GiB", "TiB"];
      const int base = 1024;
      int unitIndex = 0;
      double size = app.installedSize.toDouble();
      while (size >= base && unitIndex < units.length - 1) {
        size /= base;
        unitIndex++;
      }
      return '~${size.toStringAsFixed(1)} ${units[unitIndex]}';
    } catch (_) {
      return '';
    }
  }

  String _getDescription(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final description = appdata['description'] as String?;
      return description?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    } catch (_) {
      return '';
    }
  }

  String _getReleaseVersion(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final releases = appdata['releases'] as List<dynamic>?;
      if (releases != null && releases.isNotEmpty) {
        return releases.first['version']?.toString() ?? '';
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  String _getReleaseTimestamp(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final releases = appdata['releases'] as List<dynamic>?;
      if (releases != null && releases.isNotEmpty) {
        final timestamp = releases.first['timestamp']?.toString();
        if (timestamp != null) {
          final validTimestamp = int.tryParse(timestamp);
          final date = validTimestamp != null
              ? DateTime.fromMillisecondsSinceEpoch(validTimestamp * 1000)
              : DateTime.tryParse(timestamp);

          if (date != null) {
            return DateFormat('MMM dd, yyyy').format(date);
          }
        }
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  String _getUrl(Application app) {
    try {
      if (app.metadata.isEmpty) return '';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      return metadata['url']?.toString().trim() ?? '';
    } catch (_) {
      return '';
    }
  }

  String _getDeveloper(Application app) {
    try {
      if (app.metadata.isEmpty) return '';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final dev = metadata['developer'];
      if (dev != null) {
        String devString =
        dev is List && dev.isNotEmpty ? dev.first.toString() : dev.toString();
        return "by ${devString.trim()}";
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  List<Widget> _getCategories(BuildContext context, Application app) {
    try {
      if (app.metadata.isEmpty) return [];
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final categoriesData = metadata['categories'];
      if (categoriesData == null) return [];
      List<dynamic> categories =
      categoriesData is List ? categoriesData : [categoriesData];

      return categories.take(3).where((c) => c != null).map((category) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.grey.shade300, width: 0.5),
          ),
          child: Text(
            category.toString().trim(),
            style: const TextStyle(
              fontSize: 11,
              color: Color(0xFF374151),
              fontWeight: FontWeight.w400,
            ),
          ),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  String? _getIconPath(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final icons = appdata['icons'] as List<dynamic>?;

      if (icons != null) {
        for (final icon in icons) {
          if (icon is Map<String, dynamic>) {
            final type = icon['type'];
            final path = icon['path']?.toString();
            if (path == null) continue;
            if (type == 'cached') {
              final fullPath =
                  '/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/$path';
              if (File(fullPath).existsSync()) return fullPath;
            } else if (type == 'remote') {
              return path;
            }
          }
        }
        for (final icon in icons) {
          if (icon is Map<String, dynamic> && icon['type'] == 'remote') {
            return icon['path']?.toString();
          }
        }
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  List<String>? _getScreenshotsimage(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final screenshots = appdata['screenshots'] as List<dynamic>?;
      if (screenshots == null) return null;
      List<String> result = [];
      for (final screenshot in screenshots) {
        final images = screenshot['images'] as List<dynamic>?;
        if (images != null) {
          String? bestUrl;
          int maxWidth = 0;
          for (final image in images) {
            final imgMap = image as Map<String, dynamic>;
            final url = imgMap['url']?.toString();
            final w = int.tryParse(imgMap['width']?.toString() ?? '0') ?? 0;
            if (url != null && w > maxWidth) {
              maxWidth = w;
              bestUrl = url;
            }
          }
          if (bestUrl != null) result.add(bestUrl);
        }
      }
      return result.isEmpty ? null : result;
    } catch (_) {
      return null;
    }
  }

  List<String>? _getScreenshotsCaption(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final screenshots = appdata['screenshots'] as List<dynamic>?;
      if (screenshots == null) return null;
      List<String> result = [];
      for (final screenshot in screenshots) {
        final captions = screenshot['captions'] as List<dynamic>?;
        if (captions != null && captions.isNotEmpty) {
          final cap = captions.first['caption']?.toString();
          if (cap != null) result.add(cap);
        }
      }
      return result;
    } catch (_) {
      return [];
    }
  }
}

class _GlassActionButton extends StatelessWidget {
  final String label;
  final Color baseColor;
  final VoidCallback? onTap;
  final bool isLoading;
  final double? progress;
  final bool isFilled;

  const _GlassActionButton({
    required this.label,
    required this.baseColor,
    required this.onTap,
    this.isLoading = false,
    this.progress,
    this.isFilled = true,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = onTap == null && !isLoading ? Colors.grey : baseColor;

    final decoration = isFilled
        ? BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          effectiveColor.withValues(alpha: 0.9),
          effectiveColor.withValues(alpha: 0.7),
        ],
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1.0,
      ),
      boxShadow: [
        BoxShadow(
          color: effectiveColor.withValues(alpha: 0.3),
          blurRadius: 12,
          offset: const Offset(0, 4),
        ),
      ],
    )
        : BoxDecoration(
      color: effectiveColor.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: effectiveColor.withValues(alpha: 0.4),
        width: 1.5,
      ),
    );

    final textColor = isFilled ? Colors.white : effectiveColor;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          decoration: decoration,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isLoading) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 2,
                    color: textColor,
                  ),
                ),
                const SizedBox(width: 8),
                if (progress != null && progress! > 0)
                  Text(
                    '${(progress! * 100).toInt()}%',
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (progress == null)
                  Text(
                    label,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ] else
                Text(
                  label,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}