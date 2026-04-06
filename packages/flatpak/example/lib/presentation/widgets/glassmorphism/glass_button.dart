import 'package:flutter/material.dart';
import '../../../responsive.dart';

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
        padding: padding ?? EdgeInsets.symmetric(
          horizontal: Responsive.scaleWithConstraints(context, 20, minSize: 12, maxSize: 32),
        ),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              glassColor,
              glassColor.withValues(alpha: isPrimary ? 0.9 : 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(Responsive.scaleWithConstraints(context, 16, minSize: 8, maxSize: 24)),
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
              Icon(icon, size: Responsive.scaleWithConstraints(context, 20, minSize: 16, maxSize: 32), color: textColor),
              if (label.isNotEmpty) SizedBox(width: Responsive.scaleWithConstraints(context, 8, minSize: 4, maxSize: 16)),
            ],
            if (label.isNotEmpty)
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: Responsive.scaleWithConstraints(context, 16, minSize: 12, maxSize: 24),
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