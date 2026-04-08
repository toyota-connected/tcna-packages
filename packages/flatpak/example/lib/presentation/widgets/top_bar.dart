import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flatpak_flutter_example/app_theme.dart';
import 'package:flatpak_flutter_example/responsive.dart';
import '../screens/profile_screen.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

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
            padding: Responsive.paddingSymmetric(
              context,
              horizontal: 65, 
              vertical: 33,
            ),
            child: Row(
              children: [
                _buildLogo(context),
                Spacer(),

                _buildSearchBar(context),
                Responsive.hGap(context, 61),
                _buildUserSection(context),
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

  Widget _buildLogo(BuildContext context) {
    final logoH = Responsive.scale(context, 36);
    final logoW = Responsive.scale(context, 168);

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Flexible(
            child: SizedBox(
              height: logoH,
              width: logoW,
              child: SvgPicture.asset(
                'assets/logos/AGL.svg',
                height: logoH,
                width: logoW,
                fit: BoxFit.contain,
              ),
            ),
          ),
          Responsive.hGap(context, 7),
          Flexible(
            child: Container(
              height: logoH,
              alignment: Alignment.centerLeft,
              child: ShaderMask(
                shaderCallback: (bounds) => const LinearGradient(
                  colors: [Color(0x00000000), Color(0xFF33D17A)],
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                ).createShader(bounds),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Store',
                    style: TextStyle(
                      fontSize: Responsive.fontSize(context, 36),
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final searchBarWidth = Responsive.scale(context, 280);
    final searchBarHeight = Responsive.scale(context, 42);

    return Container(
      width: searchBarWidth,
      height: searchBarHeight,
      constraints: BoxConstraints(
        maxWidth: Responsive.isMobile(context)
            ? double.infinity
            : searchBarWidth,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(Responsive.scale(context, AppTheme.borderRadiusMedium)),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.0,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          decoration: InputDecoration(
            hintText: 'Search for apps...',
            hintStyle: TextStyle(
              color: const Color(0xFFADAEBC).withValues(alpha: 0.8),
              fontSize: Responsive.fontSize(context, 16),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.8),
              size: Responsive.scale(context, 16),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 16),
              vertical: (searchBarHeight - Responsive.scale(context, 20)) / 2,
            ),
            isDense: true,
          ),
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: Responsive.fontSize(context, 14.0),
          ),
        ),
      ),
    );
  }

  Widget _buildUserSection(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          // TODO: notification widget
          ///onTap: ,
          child: SvgPicture.asset(
            'assets/icons/bell.svg',
            width: Responsive.scale(context, 17.05),
            height: Responsive.scale(context, 19.5),
          ),
        ),

        Responsive.hGap(context, 16),

        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => ProfileScreen()),
          ),
          child: Container(
            width: Responsive.scale(context, 31.18),
            height: Responsive.scale(context, 31.18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 10)),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.3),
                width: 2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(Responsive.scale(context, 8)),
              child: Image.asset('assets/images/person.png', fit: BoxFit.cover),
            ),
          ),
        ),
      ],
    );
  }
}
