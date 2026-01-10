import 'package:flutter/material.dart';
import '../../core/permissions/permission_types.dart';
import '../../data/models/flatpak_permission_model.dart';
import 'glassmorphism/glass_button.dart';
import 'glassmorphism/glass_container.dart';

class FlatpakPermissionDialog {
  static Future<bool?> show({
    required BuildContext context,
    required PermissionEvent event,
  }) async {
    if (event.permission == null) return null;

    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.3),
      builder: (dialogContext) => _PermissionDialogContent(event: event),
    );
  }
}

class _PermissionDialogContent extends StatefulWidget {
  final PermissionEvent event;

  const _PermissionDialogContent({required this.event});

  @override
  State<_PermissionDialogContent> createState() =>
      _PermissionDialogContentState();
}

class _PermissionDialogContentState extends State<_PermissionDialogContent>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final permission = widget.event.permission!;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          insetPadding: const EdgeInsets.all(20),
          child: GlassContainer(
            borderRadius: 32,
            blur: 20,
            borderOpacity: 0.2,
            color: isDark
                ? Colors.black.withValues(alpha: 0.6)
                : Colors.white.withValues(alpha: 0.7),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 400),
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildIconHeader(colorScheme, permission),

                  const SizedBox(height: 28),

                  Text(
                    'Permission Required',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      // Ensure text is readable on glass
                      color: isDark ? Colors.white : Colors.black87,
                      letterSpacing: -0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: isDark ? Colors.white70 : Colors.black54,
                        height: 1.5,
                      ),
                      children: [
                        TextSpan(
                          text: _getAppDisplayName(widget.event.appId),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                        const TextSpan(text: ' wants to access your '),
                        TextSpan(
                          text: permission.displayName.toLowerCase(),
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  _buildDescriptionCard(context, permission),

                  if (widget.event.total != null && widget.event.total! > 1) ...[
                    const SizedBox(height: 24),
                    _buildProgressIndicator(colorScheme),
                  ],

                  const SizedBox(height: 32),

                  // Action buttons
                  _buildActionButtons(colorScheme, isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIconHeader(
      ColorScheme colorScheme, FlatpakPermission permission) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: colorScheme.primary.withValues(alpha: 0.2),
            boxShadow: [
              BoxShadow(
                color: colorScheme.primary.withValues(alpha: 0.4),
                blurRadius: 40,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
        GlassContainer(
          borderRadius: 50,
          blur: 10,
          color: colorScheme.surface.withValues(alpha: 0.1),
          borderOpacity: 0.2,
          child: Container(
            width: 80,
            height: 80,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withValues(alpha: 0.2),
                  Colors.white.withValues(alpha: 0.05),
                ],
              ),
            ),
            child: Icon(
              permission.icon,
              size: 36,
              color: colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionCard(BuildContext context, FlatpakPermission permission) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassContainer(
      borderRadius: 16,
      blur: 0,
      color: isDark
          ? Colors.white.withValues(alpha: 0.05)
          : Colors.black.withValues(alpha: 0.03),
      borderOpacity: 0.1,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 20,
              color: isDark ? Colors.white70 : Colors.black54,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                permission.description,
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : Colors.black54,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressIndicator(ColorScheme colorScheme) {
    final progress = widget.event.progress!;
    final total = widget.event.total!;

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Permission $progress of $total',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colorScheme.primary,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          height: 6,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: colorScheme.onSurface.withValues(alpha: 0.1),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: progress / total,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: LinearGradient(
                  colors: [
                    colorScheme.primary.withValues(alpha: 0.7),
                    colorScheme.primary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(ColorScheme colorScheme, bool isDark) {
    return Row(
      children: [
        Expanded(
          child: GlassButton(
            onTap: () {
              _controller.reverse().then((_) {
                Navigator.of(context).pop(false);
              });
            },
            label: 'Deny',
            icon: Icons.close_rounded,
            textColor: Colors.redAccent.shade100,
            glassColor: Colors.red.withValues(alpha: 0.05),
            borderColor: Colors.red.withValues(alpha: 0.2),
          ),
        ),

        const SizedBox(width: 16),

        Expanded(
          child: GlassButton(
            onTap: () {
              _controller.reverse().then((_) {
                Navigator.of(context).pop(true);
              });
            },
            label: 'Allow',
            icon: Icons.check_rounded,
            textColor: Colors.white,
            glassColor: colorScheme.primary.withValues(alpha: 0.8),
            borderColor: Colors.white.withValues(alpha: 0.4),
            isPrimary: true,
          ),
        ),
      ],
    );
  }

  String _getAppDisplayName(String appId) {
    final parts = appId.split('.');
    if (parts.length >= 3) {
      final name = parts.last;
      return name
          .split('_')
          .map((word) => word.isNotEmpty
          ? word[0].toUpperCase() + word.substring(1)
          : '')
          .join(' ');
    }
    return appId;
  }
}