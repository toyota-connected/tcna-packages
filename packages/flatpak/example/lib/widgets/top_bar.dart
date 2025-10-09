import 'dart:ui';
import 'package:flatpak_flutter_example/screens/profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flatpak_flutter_example/app_theme.dart';
import 'package:flatpak_flutter_example/responsive.dart';

class AppTopBar extends StatelessWidget implements PreferredSizeWidget {
  const AppTopBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
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
          filter: ImageFilter.blur(
            sigmaX: 10.0,
            sigmaY: 10.0,
          ),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: 65,
              vertical: 33.0,
            ),
            child: Row(
              children: [
                _buildLogo(context),
                Spacer(),

                _buildSearchBar(context),
                SizedBox(width: Responsive.scaleWithConstraints(
                  context,
                  61,
                  minSize: 24,
                  maxSize: 72,
                )),
                _buildUserSection(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(100);

  Widget _buildLogo(BuildContext context){
    final logoH = Responsive.scaleWithConstraints(
      context,
      36,
      minSize: 24,
      maxSize: 48,
    );

    final logoW = Responsive.scaleWithConstraints(
      context,
      168,
      minSize: 112,
      maxSize: 224,
    );

    return Expanded(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            height: logoH,
            width: logoW,
            child: SvgPicture.asset(
              'assets/logos/AGL.svg',
              height: logoH,
              width: logoW,
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 7),
          Container(
            height: logoH,
            alignment: Alignment.centerLeft,
            child: ShaderMask(
              shaderCallback: (bounds) => const LinearGradient(
                colors: [Color(0x00000000), Color(0xFF33D17A)],
                begin: Alignment.bottomRight,
                end: Alignment.topLeft,
              ).createShader(bounds),
              child: Text(
                'Store',
                style: TextStyle(
                  fontSize: Responsive.scaleWithConstraints(
                    context,
                    36,
                    minSize: 24,
                    maxSize: 48,
                  ),
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                  letterSpacing: -0.5,
                  height: 1.0,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    final searchBarWidth = Responsive.scaleWithConstraints(
      context,
      280,
      minSize: 200,
      maxSize: 400,
    );

    final searchBarHeight = Responsive.scaleWithConstraints(
      context,
      42,
      minSize: 36,
      maxSize: 48,
    );

    return Container(
      width: searchBarWidth,
      height: searchBarHeight,
      constraints: BoxConstraints(
        maxWidth: Responsive.isMobile(context) ? double.infinity : searchBarWidth,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
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
              fontSize: Responsive.scale(context, 16).clamp(12.0, 18.0),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: const Color(0xFF9CA3AF).withValues(alpha: 0.8),
              size: Responsive.scale(context, 16).clamp(12.0, 18.0),
            ),
            border: InputBorder.none,
            contentPadding: EdgeInsets.symmetric(
              horizontal: Responsive.scale(context, 16).clamp(12.0, 20.0),
              vertical: (searchBarHeight - 20 ) / 2,
            ),
            isDense: true,
          ),
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: Responsive.scale(context, 14.0).clamp(12.0,16.0),
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
            width: 17.05,
            height: 19.5,

          ),
        ),

        const SizedBox(width: 16),

        GestureDetector(
          onTap:()=> Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen())) ,
          child: Container(
            width: 31.18,
            height: 31.18,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
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
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/person.png',
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
      ],
    );
  }
  
}
