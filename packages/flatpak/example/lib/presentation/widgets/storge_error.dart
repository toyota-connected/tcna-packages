import 'package:flutter/material.dart';
import '../../responsive.dart';

class StorageErrorDialog extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Responsive width limiting
    final dialogWidth = Responsive.responsiveValue(
      context,
      small: Responsive.width(context) * 0.85,
      medium: Responsive.scale(context, 320.0),
      large: Responsive.scale(context, 400.0),
    ).clamp(320.0, 800.0);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: Responsive.paddingSymmetric(context, horizontal: 16),
      child: Container(
        width: dialogWidth,
        padding: EdgeInsets.fromLTRB(
          Responsive.scale(context, 20), 
          Responsive.scale(context, 24), 
          Responsive.scale(context, 20), 
          Responsive.scale(context, 20)
        ),
        decoration: BoxDecoration(
          color: const Color(0xFFF2F2F7),
          borderRadius: BorderRadius.circular(Responsive.scale(context, 24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: Responsive.scale(context, 20),
              spreadRadius: Responsive.scale(context, 5),
            )
          ]
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Cannot Download App',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 17),
                fontWeight: FontWeight.w600,
                color: Colors.black,
                letterSpacing: -0.4,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.scale(context, 8)),
            Text(
              'There is not enough available storage to download $appName. You can manage your storage in Settings.',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 13),
                fontWeight: FontWeight.w400,
                color: Colors.black87,
                height: 1.3,
                letterSpacing: -0.1,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: Responsive.scale(context, 24)),
            Row(
              children: [
                Expanded(
                  child: _PillButton(
                    label: 'Close',
                    backgroundColor: const Color(0xFFE5E5EA),
                    textColor: Colors.black,
                    onTap: onDismiss,
                  ),
                ),
                SizedBox(width: Responsive.scale(context, 12)),
                Expanded(
                  child: _PillButton(
                    label: 'Storage',
                    backgroundColor: const Color(0xFF007AFF),
                    textColor: Colors.white,
                    onTap: onSettings,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback onTap;

  const _PillButton({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(Responsive.scale(context, 24)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(Responsive.scale(context, 24)),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: Responsive.scale(context, 14)),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 15),
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: -0.2,
            ),
          ),
        ),
      ),
    );
  }
}
