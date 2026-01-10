import 'package:flutter/material.dart';

class GlassButton extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  final IconData? icon;
  final Color textColor;
  final Color glassColor;
  final Color borderColor;
  final bool isPrimary;
  final EdgeInsetsGeometry? padding;

  const GlassButton({
    super.key,
    required this.onTap,
    required this.label,
    this.icon,
    required this.textColor,
    required this.glassColor,
    required this.borderColor,
    this.isPrimary = false,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glassColor,
              glassColor.withValues(alpha: isPrimary ? 0.9 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: borderColor,
            width: 1,
          ),
          boxShadow: isPrimary
              ? [
            BoxShadow(
              color: glassColor.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 8),
            )
          ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: textColor),
              if (label.isNotEmpty) const SizedBox(width: 8),
            ],
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
          ],
        ),
      ),
    );
  }
}