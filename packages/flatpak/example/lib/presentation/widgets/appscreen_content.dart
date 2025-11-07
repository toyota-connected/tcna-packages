import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flatpak_flutter_example/presentation/widgets/screenshot_widget.dart';
import 'package:flatpak_flutter_example/responsive.dart';
import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_launch/app_launch_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../business_logic/installation/installation_state.dart';
import '../../business_logic/installed_apps/installed_apps_cubit.dart';
import '../../business_logic/installed_apps/installed_apps_state.dart';
import '../../data/models/application_model.dart';
import 'app_info.dart';

class AppscreenContent extends StatelessWidget {
  const AppscreenContent({
    super.key,
    required this.app,
    required this.installedAppsCubit,
    required this.installationCubit,
    required this.appLaunchCubit,
  });

  final Application app;
  final InstalledAppsCubit installedAppsCubit;
  final InstallationCubit installationCubit;
  final AppLaunchCubit appLaunchCubit;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
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
                child: Row(
                  children: [
                    _buildApp(context),
                    const Spacer(),
                    _buildInstallButton(context),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 18),
        _buildScreenshot(context),
        const SizedBox(height: 18),
        _buildInfo(context),
      ],
    );
  }

  Widget _buildApp(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildAppinfo(context, app)],
      ),
    );
  }

  Widget _buildAppinfo(BuildContext context, Application app) {
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
                      fontSize: Responsive.scale(
                        context,
                        13.0,
                      ).clamp(11.0, 15.0),
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
        ],
      ),
    );
  }

  Widget _buildAppIcon(BuildContext context, Application app) {
    final cardSize = Responsive.scale(context, 80).clamp(68.0, 92.0);
    final iconSize = cardSize * 0.5;
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
        );
      } else {
        return Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      }
    }
    return Image.asset('assets/icons/default_app_icon.png', fit: BoxFit.cover);
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
        horizontal: Responsive.responsiveValue(
          context,
          mobile: 16.0,
          tablet: 24.0,
          desktop: 32.0,
        ),
        vertical: Responsive.responsiveValue(
          context,
          mobile: 12.0,
          tablet: 16.0,
          desktop: 20.0,
        ),
      ),
      child: Screenshot(images: images, captions: captions),
    );
  }

  Widget _buildInstallButton(BuildContext context) {
    final buttonW = Responsive.scaleWithConstraints(
      context,
      112,
      minSize: 100,
      maxSize: 120,
    );
    final buttonH = Responsive.scaleWithConstraints(
      context,
      48,
      minSize: 40,
      maxSize: 56,
    );

    return BlocBuilder<InstalledAppsCubit, InstalledAppsState>(
      bloc: installedAppsCubit,
      builder: (context, installedState) {
        return BlocBuilder<InstallationCubit, InstallationState>(
          bloc: installationCubit,
          builder: (context, installState) {
            return BlocBuilder<AppLaunchCubit, AppLaunchState>(
              bloc: appLaunchCubit,
              builder: (context, launchState) {
                final isInstalled =
                    installedState is InstalledAppsLoaded &&
                    installedState.installedIds.contains(app.id);

                final isInstalling = installationCubit.isOperationInProgress(
                  app.id,
                );
                final isLaunching = appLaunchCubit.isLaunching(app.id);

                // Get progress
                double? progress;
                if (isInstalling && installState is InstallationInProgress) {
                  if (installState.appId == app.id) {
                    progress = installState.progress;
                  }
                }

                String buttonText;
                if (isInstalling) {
                  buttonText = "Installing...";
                } else if (isLaunching) {
                  buttonText = "Opening...";
                } else if (isInstalled) {
                  buttonText = "Open";
                } else {
                  buttonText = "Install";
                }

                final canTap = !isInstalling && !isLaunching;

                return GestureDetector(
                  onTap: canTap
                      ? () async {
                          if (isInstalled) {
                            await appLaunchCubit.launchApp(app.id);
                          } else {
                            await installationCubit.installApp(app.id);
                          }
                        }
                      : null,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9999),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: buttonW,
                        height: buttonH,
                        decoration: BoxDecoration(
                          color: canTap ? const Color(0xFF2563EB) : Colors.grey,
                          borderRadius: BorderRadius.circular(9999),
                          border: Border.all(
                            width: 1.5,
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Center(
                          child: isInstalling && progress != null
                              ? _buildProgressIndicator(progress, buttonH)
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (isLaunching)
                                      const SizedBox(
                                        width: 14,
                                        height: 14,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                        ),
                                      ),
                                    if (isLaunching) const SizedBox(width: 8),
                                    Text(
                                      buttonText,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w300,
                                        fontSize: 16,
                                        fontFamily: 'general-sans',
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            );
          },
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
            fontSize: 8,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
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
                description,
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
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(9999),
                ),
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
                version: version,
                License: app.license,
                last_upadate: lastUpdate,
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
      String result = '';
      final Map<String?, Object?> contentRating = app.contentRating;
      if (contentRating.isNotEmpty) {
        for (final k in contentRating.keys) {
          Object? v = contentRating[k];
          result += '$k : $v';
        }
        return result;
      }
      return '';
    } catch (e) {
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
      String formattedSize = size == size.toInt()
          ? size.toInt().toString()
          : size.toStringAsFixed(2);
      return '~$formattedSize ${units[unitIndex]}';
    } catch (e) {
      return '';
    }
  }

  String _getDescription(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final description = appdata['description'] as String;
      return description.trim().replaceAll(RegExp(r'\s+'), ' ');
    } catch (e) {
      return '';
    }
  }

  String _getReleaseVersion(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final releases = appdata['releases'] as List<dynamic>?;
      if (releases != null) {
        for (final r in releases) {
          final release = r['version'] as String?;
          if (release != null) return release;
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  String _getReleaseTimestamp(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final releases = appdata['releases'] as List<dynamic>?;
      if (releases != null) {
        for (final r in releases) {
          final timestampString = r['timestamp'] as String?;
          if (timestampString != null) {
            final dateTime = DateTime.parse(timestampString);
            return DateFormat('MMM dd, yyyy - HH:mm').format(dateTime);
          }
        }
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  String _getUrl(Application app) {
    try {
      if (app.metadata.isEmpty) return '';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final url = metadata['url'];
      if (url != null) {
        return url.toString().trim();
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  String _getDeveloper(Application app) {
    try {
      if (app.metadata.isEmpty) return '';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final dev = metadata['developer'];
      if (dev != null) {
        String devString = dev is List && dev.isNotEmpty
            ? dev.first.toString()
            : dev.toString();
        return "by ${devString.trim()}";
      }
      return '';
    } catch (e) {
      return '';
    }
  }

  List<Widget> _getCategories(BuildContext context, Application app) {
    try {
      if (app.metadata.isEmpty) return [];
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final categoriesData = metadata['categories'];
      if (categoriesData == null) return [];
      List<dynamic> categories = categoriesData is List
          ? categoriesData
          : [categoriesData];
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
    } catch (e) {
      return [];
    }
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
      return 'assets/icons/default_app_icon.png';
    } catch (e) {
      return 'assets/icons/default_app_icon.png';
    }
  }

  List<String>? _getScreenshotsimage(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      List<String> result = [];
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final screenshots = appdata['screenshots'] as List<dynamic>?;
      if (screenshots != null) {
        for (final screenshot in screenshots) {
          final images = screenshot['images'] as List<dynamic>?;
          if (images != null) {
            String? bestUrl;
            int maxWidth = 0;
            for (final image in images) {
              final imageMap = image as Map<String, dynamic>;
              final url = imageMap['url'] as String?;
              final width = imageMap['width'] as String?;
              if (url != null && width != null) {
                try {
                  final widthInt = int.parse(width);
                  if (widthInt >= 700 && widthInt > maxWidth) {
                    maxWidth = widthInt;
                    bestUrl = url;
                  }
                } catch (e) {
                  continue;
                }
              }
            }
            if (bestUrl != null) result.add(bestUrl);
          }
        }
      }
      return result.isEmpty ? null : result;
    } catch (e) {
      return null;
    }
  }

  List<String>? _getScreenshotsCaption(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      List<String> result = [];
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final screenshots = appdata['screenshots'] as List<dynamic>?;
      if (screenshots != null) {
        for (final screenshot in screenshots) {
          final captions = screenshot['captions'] as List?;
          if (captions != null) {
            for (final caption in captions) {
              final c = caption['caption'] as String?;
              if (c != null) result.add(c);
            }
          }
        }
      }
      return result;
    } catch (e) {
      return [];
    }
  }
}
