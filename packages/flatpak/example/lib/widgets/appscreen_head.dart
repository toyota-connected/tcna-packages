import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flatpak_flutter_example/responsive.dart';

class AppscreanHead extends StatelessWidget implements PreferredSizeWidget{
  const AppscreanHead({super.key,
  required this.appname,
  });
  final String appname;

  @override
  Widget build(BuildContext context){
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
              horizontal: 40,
              vertical: 25,
            ),
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
  Size get preferredSize => const Size.fromHeight(100);

  Widget _buildBackWidget(BuildContext context){
    final backW = Responsive.scaleWithConstraints(
      context,
      24,
      minSize: 20,
      maxSize: 28,
    );

    final backH = Responsive.scaleWithConstraints(
      context,
      24,
      minSize: 20,
      maxSize: 28,
    );

    return GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Row(
          children: [
              SizedBox(
                height: backH,
                width: backW,
                child: Icon(CupertinoIcons.back,
                  color: Colors.black,
                ),
              ),
            SizedBox(width: 10,),
            Text(appname,
              style: TextStyle(
                  fontSize: Responsive.scaleWithConstraints(
                    context,
                    18,
                    minSize: 16,
                    maxSize: 24,
                  ),
                  fontWeight: FontWeight.bold,
                  color: Colors.black
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildEngageWidget(BuildContext context){
    final engageW = Responsive.scaleWithConstraints(
      context,
      56,
      minSize: 48,
      maxSize: 64,
    );

    final engageH = Responsive.scaleWithConstraints(
      context,
      20,
      minSize: 16,
      maxSize: 24,
    );

    return Row(
      children: [
        SizedBox(
          height: engageH,
          width: engageW,
          child: Row(
            children: [
              SvgPicture.asset(
                'assets/icons/like.svg',
                width: Responsive.scaleWithConstraints(
                  context,
                  20,
                  minSize: 16,
                  maxSize: 24,
                ),
                height: Responsive.scaleWithConstraints(
                  context,
                  20,
                  minSize: 16,
                  maxSize: 24,
                ),
              ),
              SizedBox(width: 12,),
              SvgPicture.asset(
                'assets/icons/share.svg',
                width: Responsive.scaleWithConstraints(
                  context,
                  20,
                  minSize: 16,
                  maxSize: 24,
                ),
                height: Responsive.scaleWithConstraints(
                  context,
                  20,
                  minSize: 16,
                  maxSize: 24,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

}
