import 'package:flatpak_flutter_example/responsive.dart';
import 'package:flatpak_flutter_example/screens/category_screen.dart';
import 'package:flatpak_flutter_example/services/AppProvider.dart';
import 'package:flatpak_flutter_example/widgets/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flatpak_flutter/src/messages.g.dart';
import 'package:provider/provider.dart';

import '../services/flatpak_service.dart';

class CategorySection extends StatelessWidget {
  const CategorySection({
    super.key,
    required this.category_heading,
    required this.apps,
    required this.onTap,
    required this.onInstall,
    this.isLoading = false,
  });

  final String category_heading;
  final List<Application> apps;
  final Function(Application) onTap;
  final Function(Application) onInstall;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                category_heading,
                style: TextStyle(
                  color: const Color(0xFF111827),
                  fontSize: Responsive.scale(context, 24).clamp(16, 28),
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CategoryScreen(
                      category: category_heading,
                    ),
                  ),
                ),
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: Responsive.scale(context, 20).clamp(14, 24),
                    fontWeight: FontWeight.normal,
                  ),
                ),
              )
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 234,
          child: _buildContent(context),
        )
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && apps.isEmpty) {
      return _buildLoadingState();
    }

    if (apps.isEmpty && !isLoading) {
      return _buildEmptyState();
    }

    return Consumer<AppsProvider>(
      builder: (context, appsProvider, _) {
        return ListView.builder(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: apps.length + (isLoading ? 1 : 0),
          itemBuilder: (context, index) {
            if (index >= apps.length) {
              return _buildLoadingCard();
            }

            final app = apps[index];

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: AppCard(
                application: app,
                onTap: () => onTap(app),
                onInstall: () => onInstall(app),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: _buildLoadingCard(),
        );
      },
    );
  }

  Widget _buildLoadingCard() {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 100,
            height: 16,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: 80,
            height: 14,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: 120,
            height: 36,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.apps,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 8),
          Text(
            'No apps available in this category',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Pull to refresh or check your connection',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}