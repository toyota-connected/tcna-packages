import 'package:flatpak_flutter_example/responsive.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/application_model.dart';
import 'app_card.dart';

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
          padding: Responsive.paddingSymmetric(context, horizontal: 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    category_heading,
                    style: TextStyle(
                      color: const Color(0xFF111827),
                      fontSize: Responsive.fontSize(context, 24),
                      fontWeight: FontWeight.bold,
                      fontFamily: 'khand',
                    ),
                  ),
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/category/$category_heading'),
                child: Text(
                  "See All",
                  style: TextStyle(
                    color: const Color(0xFF2563EB),
                    fontSize: Responsive.fontSize(context, 20),
                    fontWeight: FontWeight.normal,
                    fontFamily: 'general-sans',
                  ),
                ),
              ),
            ],
          ),
        ),
        Responsive.vGap(context, 20),
        SizedBox(
          height: Responsive.scale(context, 234),
          child: _buildContent(context),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    if (isLoading && apps.isEmpty) {
      return _buildLoadingState(context);
    }

    if (apps.isEmpty && !isLoading) {
      return _buildEmptyState(context);
    }

    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: Responsive.paddingSymmetric(context, horizontal: 16),
      itemCount: apps.length + (isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= apps.length) {
          return _buildLoadingCard(context);
        }

        final app = apps[index];

        return Padding(
          padding: Responsive.paddingSymmetric(context, horizontal: 8.0),
          child: AppCard(
            application: app,
            onTap: () => onTap(app),
          ),
        );
      },
    );
  }

  Widget _buildLoadingState(BuildContext context) {
    return ListView.builder(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: Responsive.paddingSymmetric(context, horizontal: 16),
      itemCount: 5,
      itemBuilder: (context, index) {
        return Padding(
          padding: Responsive.paddingSymmetric(context, horizontal: 8.0),
          child: _buildLoadingCard(context),
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context) {
    return Container(
      width: Responsive.scale(context, 160),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(Responsive.scale(context, 12)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: Responsive.scale(context, 64),
            height: Responsive.scale(context, 64),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.scale(context, 8)),
            ),
          ),
          Responsive.vGap(context, 12),
          Container(
            width: Responsive.scale(context, 100),
            height: Responsive.scale(context, 16),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
          Responsive.vGap(context, 8),
          Container(
            width: Responsive.scale(context, 80),
            height: Responsive.scale(context, 14),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.scale(context, 4)),
            ),
          ),
          Responsive.vGap(context, 12),
          Container(
            width: Responsive.scale(context, 120),
            height: Responsive.scale(context, 36),
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(Responsive.scale(context, 18)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.apps, size: Responsive.scale(context, 48), color: Colors.grey[400]),
          Responsive.vGap(context, 8),
          Text(
            'No apps available in this category',
            style: TextStyle(color: Colors.grey[600], fontSize: Responsive.fontSize(context, 16)),
          ),
          Responsive.vGap(context, 8),
          Text(
            'Pull to refresh or check your connection',
            style: TextStyle(color: Colors.grey[500], fontSize: Responsive.fontSize(context, 12)),
          ),
        ],
      ),
    );
  }
}