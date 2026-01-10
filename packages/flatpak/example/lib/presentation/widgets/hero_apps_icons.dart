import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flatpak_flutter_example/data/models/application_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../business_logic/discovery/discovery_cubit.dart';

class AppsIcons extends StatefulWidget {
  const AppsIcons({super.key});

  @override
  State<AppsIcons> createState() => _AppIconsState();
}

class _AppIconsState extends State<AppsIcons> {
  List<Application> _apps = [];
  bool _isLoading = true;
  static const List<String> appIds = [
    'com.brave.Browser',
    'org.libreoffice.LibreOffice',
    'org.telegram.desktop',
    'com.visualstudio.code',
    'org.gimp.GIMP',
    'org.kde.krita',
    'com.github.tenderowl.frog',
    'org.libretro.RetroArch',
    'org.videolan.VLC',
  ];

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    try {
      final discoveryCubit = context.read<DiscoveryCubit>();

      await discoveryCubit.loadAllApps();

      final allApps = discoveryCubit.allApps;
      final loadedApps = <Application>[];

      for (final appId in appIds) {
        try {
          final app = allApps.firstWhere(
            (a) => a.id == appId || a.shortId == appId || a.id.contains(appId),
            orElse: () => throw Exception('App not found'),
          );
          loadedApps.add(app);
        } catch (e) {
          debugPrint('[AppsIcons] Could not find app: $appId');
        }
      }

      if (mounted) {
        setState(() {
          _apps = loadedApps;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('[AppsIcons] Error loading apps: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CupertinoActivityIndicator(color: Colors.white),
      );
    }

    if (_apps.isEmpty) {
      return const Center(
        child: Text(
          'No apps available',
          style: TextStyle(color: Colors.white70),
        ),
      );
    }

    return SizedBox(
      height: 200,
      child: Stack(clipBehavior: Clip.none, children: _buildFloatingIcons()),
    );
  }

  List<Widget> _buildFloatingIcons() {
    final positions = [
      {'top': 0.0, 'left': 10.0, 'rotation': 0.0},
      {'top': 20.0, 'left': 160.0, 'rotation': 0.0},
      {'top': 10.0, 'right': 10.0, 'rotation': 0.0},
      {'top': 70.0, 'right': 30.0, 'rotation': 0.0},
      {'bottom': 10.0, 'left': 100.0, 'rotation': 0.0},
      {'top': 50.0, 'left': 80.0, 'rotation': 0.0},
      {'bottom': 30.0, 'left': 20.0, 'rotation': 0.0},
      {'bottom': 0.0, 'right': 20.0, 'rotation': 0.0},
      {'bottom': 50.0, 'left': 180.0, 'rotation': 0.0},
    ];

    final widgets = <Widget>[];

    for (int i = 0; i < _apps.length && i < positions.length; i++) {
      final pos = positions[i];
      widgets.add(
        Positioned(
          top: pos['top'],
          bottom: pos['bottom'],
          left: pos['left'],
          right: pos['right'],
          child: Transform.rotate(
            angle: pos['rotation'] as double,
            child: _buildGlassIcon(_apps[i]),
          ),
        ),
      );
    }

    return widgets;
  }

  Widget _buildGlassIcon(Application app) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16.0),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(16.0),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14.0),
            child: _buildIcon(64, app),
          ),
        ),
      ),
    );
  }

  String? _getIconPath(Application app) {
    try {
      if (app.appdata.isEmpty) {
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

  Widget _buildIcon(double size, Application app) {
    final iconPath = _getIconPath(app);
    if (iconPath != null) {
      if (iconPath.startsWith('http')) {
        return Image.network(
          iconPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/icons/default_app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          },
        );
      } else if (iconPath.startsWith('assets/')) {
        return Image.asset(
          iconPath,
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      } else {
        return Image.file(
          File(iconPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Image.asset(
              'assets/icons/default_app_icon.png',
              width: size,
              height: size,
              fit: BoxFit.cover,
            );
          },
        );
      }
    }
    return Image.asset(
      'assets/icons/default_app_icon.png',
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }
}
