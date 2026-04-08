import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flatpak_flutter_example/responsive.dart';

class AppscreenHead extends StatelessWidget implements PreferredSizeWidget {
  const AppscreenHead({super.key, required this.appname});
  final String appname;

  @override
  Widget build(BuildContext context) {
    final barHeight = Responsive.scale(context, 100);

    return Container(
      height: barHeight,
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
            padding: Responsive.paddingSymmetric(context, horizontal: 40, vertical: 25),
            child: Row(
              children: [
                _buildBackWidget(context),
                Spacer(),
                _buildEngageWidget(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize {
    try {
      final view = PlatformDispatcher.instance.implicitView ?? PlatformDispatcher.instance.views.first;
      final w = view.physicalSize.width / view.devicePixelRatio;
      final h = view.physicalSize.height / view.devicePixelRatio;
      
      final wRatio = w / 1024.0;
      final hRatio = h / 768.0;
      final val = wRatio * hRatio;
      double scale = val <= 0 ? 1.0 : (val < 1 ? val + (1 - val) * 0.5 : val * 0.5 + 0.5);
      
      if (w < 600) {
        scale = scale.clamp(0.45, 0.85);
      } else if (w < 1024) {
        scale = scale.clamp(0.70, 1.10);
      } else if (w < 1440) {
        scale = scale.clamp(0.90, 1.40);
      } else {
        scale = scale.clamp(1.10, 2.00);
      }
      return Size.fromHeight(100.0 * scale);
    } catch (_) {
      return const Size.fromHeight(100.0);
    }
  }

  Widget _buildBackWidget(BuildContext context) {
    final backW = Responsive.scale(context, 26);
    final backH = Responsive.scale(context, 26);

    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Row(
        children: [
          SizedBox(
            height: backH,
            width: backW,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Icon(CupertinoIcons.back, color: Colors.black, size: Responsive.scale(context, 24)),
            ),
          ),
          Responsive.hGap(context, 10),
          Text(
            appname,
            style: TextStyle(
              fontSize: Responsive.fontSize(context, 20),
              fontWeight: FontWeight.bold,
              fontFamily: 'khand',
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngageWidget(BuildContext context) {
    final engageW = Responsive.scale(context, 56);
    final engageH = Responsive.scale(context, 20);

    return Row(
      children: [
        SizedBox(
          height: engageH,
          width: engageW,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/like.svg',
                width: Responsive.scale(context, 20),
                height: Responsive.scale(context, 20),
              ),
              Responsive.hGap(context, 12),
              SvgPicture.asset(
                'assets/icons/share.svg',
                width: Responsive.scale(context, 20),
                height: Responsive.scale(context, 20),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
