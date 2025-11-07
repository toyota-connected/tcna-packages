import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'hero_apps_icons.dart';

class HeroWidget extends StatelessWidget {
  final String title;
  final String subtitle;
  final String imageUrl;
  final List<Widget>? featuredAppCards;

  const HeroWidget({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.imageUrl,
    this.featuredAppCards,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      height: 280,
      child: Stack(
        children: [
          // Background image
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: Image.asset(
                imageUrl,
                fit: BoxFit.cover,
              ),
            ),
          ),
          // Glass effect container with content
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24.0),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 0, sigmaY: 0),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withOpacity(0.2),
                        Colors.white.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24.0),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
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
                                style: const TextStyle(
                                  fontSize: 32.0,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontFamily: 'khand',
                                  height: 1.2,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                subtitle,
                                style: TextStyle(
                                  fontSize: 14.0,
                                  color: Colors.white.withOpacity(0.9),
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
                              const SizedBox(height: 20.0),
                              // Explore button with glass effect
                              _buildExploreButton(context),
                            ],
                          ),
                        ),
                        const SizedBox(width: 24.0),
                        // Right side - App icons
                        const Expanded(
                          flex: 2,
                          child: AppsIcons(),
                        ),
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
        borderRadius: BorderRadius.circular(25.0),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 14.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.green.withOpacity(0.9),
                  Colors.green.shade600.withOpacity(0.9),
                ],
              ),
              borderRadius: BorderRadius.circular(25.0),
              border: Border.all(
                color: Colors.white.withOpacity(0.4),
                width: 1.5,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0xFF33D17A),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: const Text(
              'Explore Apps',
              style: TextStyle(
                fontSize: 16.0,
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