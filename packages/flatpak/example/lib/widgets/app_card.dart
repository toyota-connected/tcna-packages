import 'dart:io';
import 'dart:ui';
import 'dart:convert';
import 'package:flatpak_flutter_example/responsive.dart';
import 'package:flatpak_flutter_example/services/AppProvider.dart';
import 'package:flutter/material.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:provider/provider.dart';

class AppCard extends StatefulWidget {
  final Application application;
  final String? name;
  final String? summary;
  final String? iconPath;
  final VoidCallback? onInstall;
  final VoidCallback? onTap;

  const AppCard({
    super.key,
    required this.application,
    this.name,
    this.summary,
    this.iconPath,
    this.onInstall,
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

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _elevationAnimation = Tween<double>(
      begin: 0.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _loadingController,
      curve: Curves.linear,
    ));
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
    final cardWidth = Responsive.scaleWithConstraints(
      context,
      220,
      minSize: 200,
      maxSize: 250,
    );

    final cardHeight = Responsive.scaleWithConstraints(
      context,
      220,
      minSize: 200,
      maxSize: 250,
    );

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
                margin: EdgeInsets.all(Responsive.scale(context, 12.0).clamp(10.0, 16.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20 + _elevationAnimation.value,
                      offset: Offset(0, 4 + _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? Colors.white.withValues(alpha: 0.35)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isHovered
                              ? Colors.white.withValues(alpha: 0.4)
                              : Colors.white.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(
                          Responsive.scale(context, 12.0).clamp(10.0, 16.0),
                        ),
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
    final iconSize = Responsive.scale(context, 92).clamp(64.0, 128.0);
    return Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
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
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _getAppName(app),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: Responsive.scale(context, 20.0).clamp(16.0, 24.0),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                _getAppSummary(app),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.color
                      ?.withValues(alpha: 0.7),
                  fontSize: Responsive.scale(context, 12.0).clamp(10.0, 14.0),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildGetButton(context),
          ],
        ),
      ],
    );
  }

  Widget _buildGetButton(BuildContext context) {


    return Consumer<AppsProvider>(
      builder: (context, appsProvider, child) {
        final isInstalling = appsProvider.isAppInstalling(widget.application.id);
        final isInstalled = appsProvider.isAppInstalled(widget.application.id);

        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (isInstalling && !_loadingController.isAnimating) {
            _loadingController.repeat();
          } else if (!isInstalling && _loadingController.isAnimating) {
            _loadingController.stop();
            _loadingController.reset();
          }
        });
        return GestureDetector(
          onTap: () async {
            if (isInstalled || isInstalling) {
              await appsProvider.openApp(widget.application.id);
            } else {
              final provider = Provider.of<AppsProvider>(context, listen: false);
              final success = await provider.installApp(widget.application.id);

              if (mounted && !success) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Failed to install ${widget.application.name}'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 8),
                decoration: BoxDecoration(
                  color: isInstalling
                      ? Colors.grey.withValues(alpha: 0.8)
                      : Colors.black87,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    width: 1.5,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isInstalling)
                      AnimatedBuilder(
                        animation: _rotationAnimation,
                        builder: (context, child) {
                          return Transform.rotate(
                            angle: _rotationAnimation.value * 2.0 *
                                3.141592653589793,
                            child: const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white),
                              ),
                            ),
                          );
                        },
                      ),
                    if (isInstalling) const SizedBox(width: 8),
                    Text(
                      isInstalling
                          ? "Installing..."
                          : (isInstalled ? "Open" : "Get"),
                      style: TextStyle(
                        color: isInstalling
                            ? Colors.white.withValues(alpha: 0.7)
                            : Colors.white,
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }
    );
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
                final cachedPath = '/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/$path';
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