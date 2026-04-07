import 'dart:ui';
import 'package:flutter/material.dart';

class StorageErrorDialog extends StatefulWidget {
  final String appName;
  final double usedGB;
  final double totalGB;
  final VoidCallback onDismiss;
  final VoidCallback onSettings;
 
  const StorageErrorDialog({
    super.key,
    required this.appName,
    required this.usedGB,
    required this.totalGB,
    required this.onDismiss,
    required this.onSettings,
  });
 
  @override
  State<StorageErrorDialog> createState() => _StorageErrorDialogState();
}

class _StorageErrorDialogState extends State<StorageErrorDialog>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _fade;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
 
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.of(context).size;
    final dialogWidth = screen.width.clamp(280.0, 400.0);
 
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(
        scale: _scale,
        child: SizedBox(
          width: dialogWidth,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1.2,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withOpacity(0.22),
                      Colors.white.withOpacity(0.06),
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 40,
                      offset: const Offset(0, 20),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(),
                    _buildBody(dialogWidth),
                    _buildDivider(),
                    _buildActions(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 0),
      child: Column(
        children: [
          // Glowing warning icon
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF4444).withOpacity(0.18),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withOpacity(0.5),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFF4444).withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: const Icon(
              Icons.storage_rounded,
              color: Color(0xFFFF6B6B),
              size: 30,
            ),
          ),
          const SizedBox(height: 16),
 
          // Title
          Text(
            'Unable to Install',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.95),
              letterSpacing: -0.3,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            '"${widget.appName}"',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFF8C8C),
              letterSpacing: -0.3,
              height: 1.2,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildBody(double dialogWidth) {
    final freeGB = widget.totalGB - widget.usedGB;
    final usedFraction = widget.usedGB / widget.totalGB;
 
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        children: [
          Text(
            'Your device does not have enough available storage to install this app.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.75),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
 
          // Storage bar card
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.15),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'iPhone Storage',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withOpacity(0.85),
                          ),
                        ),
                        Text(
                          '${widget.usedGB} / ${widget.totalGB.toInt()} GB',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.55),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _StorageBar(usedFraction: usedFraction),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _StorageLegend(
                          color: const Color(0xFFFF6B6B),
                          label: 'Used',
                          value: '${widget.usedGB} GB',
                        ),
                        _StorageLegend(
                          color: Colors.white.withOpacity(0.25),
                          label: 'Free',
                          value:
                              '${freeGB.toStringAsFixed(1)} GB',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 1,
      color: Colors.white.withOpacity(0.12),
    );
  }

  Widget _buildActions() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(
            child: _GlassButton(
              label: 'OK',
              onTap: widget.onDismiss,
              isPrimary: false,
            ),
          ),
          VerticalDivider(
            width: 1,
            color: Colors.white.withOpacity(0.12),
          ),
          Expanded(
            child: _GlassButton(
              label: 'Settings',
              onTap: widget.onSettings,
              isPrimary: true,
            ),
          ),
        ],
      ),
    );
  }
}

class _StorageBar extends StatefulWidget {
  final double usedFraction;
  const _StorageBar({required this.usedFraction});
 
  @override
  State<_StorageBar> createState() => _StorageBarState();
}
 
class _StorageBarState extends State<_StorageBar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;
 
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
  }
 
  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }
 
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        return LayoutBuilder(
          builder: (ctx, constraints) {
            return Container(
              height: 8,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Stack(
                children: [
                  FractionallySizedBox(
                    widthFactor: _anim.value * widget.usedFraction,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        gradient: const LinearGradient(
                          colors: [Color(0xFFFF4444), Color(0xFFFF8C00)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF4444).withOpacity(0.6),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StorageLegend extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
 
  const _StorageLegend({
    required this.color,
    required this.label,
    required this.value,
  });
 
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.45),
              ),
            ),
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _GlassButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;
 
  const _GlassButton({
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });
 
  @override
  State<_GlassButton> createState() => _GlassButtonState();
}
 
class _GlassButtonState extends State<_GlassButton> {
  bool _pressed = false;
 
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _pressed
              ? Colors.white.withOpacity(0.12)
              : Colors.transparent,
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 17,
            fontWeight:
                widget.isPrimary ? FontWeight.w600 : FontWeight.w400,
            color: widget.isPrimary
                ? const Color(0xFF64B5FF)
                : Colors.white.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}