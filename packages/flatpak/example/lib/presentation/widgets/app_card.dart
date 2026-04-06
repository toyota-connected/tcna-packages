import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flatpak_flutter_example/business_logic/app_status/app_status_cubit.dart';
import 'package:flatpak_flutter_example/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../business_logic/app_launch/app_launch_cubit.dart';
import '../../business_logic/app_status/app_status_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../data/models/application_model.dart';

class AppCard extends StatefulWidget {
  final Application application;
  final String? name;
  final String? summary;
  final String? iconPath;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.application,
    this.name,
    this.summary,
    this.iconPath,
    this.onTap,
  });

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> with TickerProviderStateMixin {
  bool _isHovered = false;
  late AnimationController _hoverController;
  late AnimationController _loadingController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _elevationAnimation = Tween<double>(begin: 0.0, end: 8.0).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _loadingController, curve: Curves.linear),
    );
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _loadingController.dispose();
    super.dispose();
  }

  void _onHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
      if (isHovered) {
        _hoverController.forward();
      } else {
        _hoverController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final cardWidth = Responsive.scale(context, 220);
    final cardHeight = Responsive.scale(context, 220);

    return AnimatedBuilder(
      animation: _hoverController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: MouseRegion(
            onEnter: (_) => _onHover(true),
            onExit: (_) => _onHover(false),
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                width: cardWidth,
                height: cardHeight,
                margin: Responsive.paddingAll(context, 12.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(Responsive.scale(context, 16)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20 + _elevationAnimation.value,
                      offset: Offset(0, 4 + _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(Responsive.scale(context, 16)),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(Responsive.scale(context, 16)),
                        border: Border.all(
                          color: _isHovered
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: Responsive.paddingAll(context, 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildAppIcon(context, widget.application),
                            const Spacer(),
                            _buildBottomSection(context, widget.application),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAppIcon(BuildContext context, Application app) {
    final iconSize = Responsive.scale(context, 92);
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(Responsive.scale(context, 12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.scale(context, 12)),
        child: _buildIcon(iconSize),
      ),
    );
  }

  Widget _buildIcon(double size) {
    final iconPath = widget.iconPath ?? _getIconPath(widget.application);
    if (iconPath != null) {
      if (iconPath.startsWith('http')) {
        return Image.network(
          iconPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultIcon(size);
          },
        );
      } else {
        return Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return _buildDefaultIcon(size);
          },
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
    );
  }

  Widget _buildBottomSection(BuildContext context, Application app) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _getAppName(app),
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: Responsive.fontSize(context, 20.0),
                  fontFamily: 'khand',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Responsive.vGap(context, 4),
              Text(
                _getAppSummary(app),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).textTheme.bodyMedium?.color
                      ?.withValues(alpha: 0.7),
                  fontSize: Responsive.fontSize(context, 12.0),
                  fontFamily: 'general-sans',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        Responsive.hGap(context, 8),

        ConstrainedBox(
          constraints: BoxConstraints(maxWidth: Responsive.scale(context, 130)),
          child: _buildActionButton(context),
        ),
      ],
    );
  }

  Widget _buildActionButton(BuildContext context) {
    // Get unified app status
    final appStatus = context.select<AppStatusCubit, AppStatus>(
          (cubit) => cubit.getAppStatus(widget.application.id),
    );

    final progress = context.select<AppStatusCubit, double?>(
          (cubit) => cubit.getProgress(widget.application.id),
    );

    // Update loading animation
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isLoading = appStatus == AppStatus.installing ||
          appStatus == AppStatus.updating ||
          appStatus == AppStatus.launching;

      if (isLoading && !_loadingController.isAnimating) {
        _loadingController.repeat();
      } else if (!isLoading && _loadingController.isAnimating) {
        _loadingController.stop();
        _loadingController.reset();
      }
    });

    // Determine button appearance
    final ButtonConfig config = _getButtonConfig(appStatus, progress);

    return GestureDetector(
      onTap: config.isEnabled
          ? () => _handleButtonTap(context, appStatus)
          : null,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.scale(context, 20)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: Responsive.paddingSymmetric(
              context,
              horizontal: 16,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: config.backgroundColor,
              borderRadius: BorderRadius.circular(Responsive.scale(context, 20)),
              border: Border.all(
                width: 1.5,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (config.showProgress) ...[
                  AnimatedBuilder(
                    animation: _rotationAnimation,
                    builder: (context, child) {
                      return Transform.rotate(
                        angle: _rotationAnimation.value * 2.0 * 3.141592653589793,
                        child: SizedBox(
                          width: Responsive.scale(context, 14),
                          height: Responsive.scale(context, 14),
                          child: CircularProgressIndicator(
                            value: progress != null && progress > 0 ? progress : null,
                            strokeWidth: 2,
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  Responsive.hGap(context, 8),
                ],
                Flexible(
                  child: Text(
                    config.text,
                    style: TextStyle(
                      color: config.textColor,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'general-sans',
                      fontSize: Responsive.fontSize(context, 14),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  ButtonConfig _getButtonConfig(AppStatus status, double? progress) {
    switch (status) {
      case AppStatus.notInstalled:
        return ButtonConfig(
          text: 'Get',
          isEnabled: true,
          showProgress: false,
          backgroundColor: Colors.black87,
          textColor: Colors.white,
        );

      case AppStatus.installed:
        return ButtonConfig(
          text: 'Open',
          isEnabled: true,
          showProgress: false,
          backgroundColor: Colors.blue.shade700,
          textColor: Colors.white,
        );

      case AppStatus.needsUpdate:
        return ButtonConfig(
          text: 'Update',
          isEnabled: true,
          showProgress: false,
          backgroundColor: Colors.orange.shade700,
          textColor: Colors.white,
        );

      case AppStatus.installing:
        return ButtonConfig(
          text: progress != null && progress > 0
              ? '${(progress * 100).toInt()}%'
              : 'Installing...',
          isEnabled: false,
          showProgress: true,
          backgroundColor: Colors.grey.withValues(alpha: 0.8),
          textColor: Colors.white.withValues(alpha: 0.7),
        );

      case AppStatus.updating:
        return ButtonConfig(
          text: progress != null && progress > 0
              ? '${(progress * 100).toInt()}%'
              : 'Updating...',
          isEnabled: false,
          showProgress: true,
          backgroundColor: Colors.grey.withValues(alpha: 0.8),
          textColor: Colors.white.withValues(alpha: 0.7),
        );

      case AppStatus.launching:
        return ButtonConfig(
          text: 'Opening...',
          isEnabled: false,
          showProgress: true,
          backgroundColor: Colors.grey.withValues(alpha: 0.8),
          textColor: Colors.white.withValues(alpha: 0.7),
        );
    }
  }

  Future<void> _handleButtonTap(BuildContext context, AppStatus status) async {
    final appStatusCubit = context.read<AppStatusCubit>();

    try {
      switch (status) {
        case AppStatus.notInstalled:
          appStatusCubit.updateAppStatus(
            widget.application.id,
            AppStatus.installing,
          );
          await context
              .read<InstallationCubit>()
              .installApp(widget.application.id);
          break;

        case AppStatus.needsUpdate:
          appStatusCubit.updateAppStatus(
            widget.application.id,
            AppStatus.updating,
          );
          await context
              .read<InstallationCubit>()
              .updateApp(widget.application.id);
          break;

        case AppStatus.installed:
          appStatusCubit.updateAppStatus(
            widget.application.id,
            AppStatus.launching,
          );
          await context
              .read<AppLaunchCubit>()
              .launchApp(widget.application.id);

          Future.delayed(const Duration(seconds: 2), () {
            if (mounted) {
              appStatusCubit.updateAppStatus(
                widget.application.id,
                AppStatus.installed,
              );
            }
          });
          break;

        default:
          break;
      }
    } catch (e) {
      debugPrint('[AppCard] Action error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
        appStatusCubit.refresh();
      }
    }
  }

  String _getAppName(Application app) {
    return widget.name ?? app.name;
  }

  String _getAppSummary(Application app) {
    return widget.summary ?? app.summary;
  }

  String? _getIconPath(Application app) {
    try {
      if (widget.application.appdata.isEmpty) {
        return null;
      }

      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final icons = appdata['icons'] as List<dynamic>?;

      if (icons != null) {
        for (final iconType in ['remote', 'cached', 'local']) {
          for (final icon in icons) {
            if (icon is Map<String, dynamic> && icon['type'] == iconType) {
              final path = icon['path'] as String?;
              if (icon['type'] == 'cached') {
                final cachedPath =
                    '/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/$path';
                return cachedPath;
              }
              if (path != null) {
                return path;
              }
            }
          }
        }
      }

      return 'assets/icons/default_app_icon.png';
    } catch (e) {
      return 'assets/icons/default_app_icon.png';
    }
  }
}

class ButtonConfig {
  final String text;
  final bool isEnabled;
  final bool showProgress;
  final Color backgroundColor;
  final Color textColor;

  ButtonConfig({
    required this.text,
    required this.isEnabled,
    required this.showProgress,
    required this.backgroundColor,
    required this.textColor,
  });
}