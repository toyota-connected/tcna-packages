import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../responsive.dart';
import 'hero_apps_icons.dart';

class HeroWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Widget>? featuredAppCards;

  const HeroWidget({
    super.key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.featuredAppCards,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: Responsive.paddingSymmetric(
        context,
        horizontal: 16.0,
        vertical: 12.0,
      ),
      height: Responsive.scale(context, 280),
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 24.0),
              ),
              child: Image.asset(imageUrl, fit: BoxFit.cover),
            ),
          ),
          // Glass effect container with content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 24.0),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.2),
                        Colors.white.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(
                      Responsive.scale(context, 24.0),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: Responsive.scale(context, 20),
                        offset: Offset(0, Responsive.scale(context, 10)),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: Responsive.paddingAll(context, 24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left side - Text content
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Title
                              Text(
                                title,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 32),
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'khand',
                                  height: 1.2,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              Responsive.vGap(context, 12),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: Responsive.fontSize(context, 14),
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontFamily: 'general-sans',
                                  height: 1.4,
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              Responsive.vGap(context, 20),
                              // Explore button with glass effect
                              _buildExploreButton(context),
                            ],
                          ),
                        ),
                        Responsive.hGap(context, 24),
                        // Right side - App icons
                        const Expanded(flex: 2, child: AppsIcons()),
                      ],
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

  Widget _buildExploreButton(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // Handle button tap
        context.push('/discover');
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(Responsive.scale(context, 25)),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: Responsive.paddingSymmetric(
              context,
              horizontal: 28.0,
              vertical: 14.0,
            ),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withValues(alpha: 0.9),
                  Colors.green.shade600.withValues(alpha: 0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(
                Responsive.scale(context, 25),
              ),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF33D17A),
                  blurRadius: Responsive.scale(context, 12),
                  offset: Offset(0, Responsive.scale(context, 4)),
                ),
              ],
            ),
            child: Text(
              'Explore Apps',
              style: TextStyle(
                fontSize: Responsive.fontSize(context, 16),
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFamily: 'general-sans',
              ),
            ),
          ),
        ),
      ),
    );
  }
}
