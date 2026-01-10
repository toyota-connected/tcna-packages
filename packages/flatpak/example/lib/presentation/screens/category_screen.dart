import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../business_logic/discovery/discovery_cubit.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../data/models/application_model.dart';
import '../../responsive.dart';
import '../widgets/app_card.dart';

class CategoryScreen extends StatefulWidget {
  const CategoryScreen({super.key, required this.category});

  final String category;

  @override
  State<StatefulWidget> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  final ScrollController _scrollController = ScrollController();
  List<Application> _categoryApps = [];
  bool _isLoading = true;
  String _sortBy = 'name';

  @override
  void initState() {
    super.initState();
    _loadCategoryApps();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadCategoryApps() async {
    setState(() => _isLoading = true);

    final cubit = context.read<DiscoveryCubit>();
    final allApps = cubit.allApps;

    if (allApps.isEmpty) {
      await cubit.loadAllApps();
    }

    final updatedApps = cubit.allApps;
    final categoryApps = <Application>[];

    // Filter apps that belong to this category
    for (final app in updatedApps) {
      final categories = _getCategories(app);
      final cleanedCategories = categories
          .map((c) => _cleanCategoryName(c))
          .toList();

      if (cleanedCategories.contains(widget.category)) {
        categoryApps.add(app);
      }
    }

    // Sort apps
    _sortApps(categoryApps);

    setState(() {
      _categoryApps = categoryApps;
      _isLoading = false;
    });

    debugPrint(
      '[CategoryScreen] Found ${categoryApps.length} apps in ${widget.category}',
    );
  }

  void _sortApps(List<Application> apps) {
    if (_sortBy == 'name') {
      apps.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    } else if (_sortBy == 'developer') {
      apps.sort((a, b) {
        final devA = _getDeveloper(a).toLowerCase();
        final devB = _getDeveloper(b).toLowerCase();
        return devA.compareTo(devB);
      });
    }
  }

  void _changeSortOrder(String sortBy) {
    setState(() {
      _sortBy = sortBy;
      _sortApps(_categoryApps);
    });
  }

  String _cleanCategoryName(String category) {
    final cleaned = category
        .replaceAll(RegExp(r'^(GTK|Qt|GNOME|KDE)\s*'), '')
        .trim();

    if (cleaned.isEmpty) return '';
    return cleaned[0].toUpperCase() + cleaned.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading ? _buildLoadingState() : _buildContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      elevation: 0,
      scrolledUnderElevation: 0.0,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF6366F1).withValues(alpha: 0.05),
                  const Color(0xFF8B5CF6).withValues(alpha: 0.05),
                ],
              ),
            ),
          ),
        ),
      ),
      title: Text(
        widget.category,
        style: TextStyle(
          fontSize: Responsive.scale(context, 24).clamp(18, 28),
          fontWeight: FontWeight.bold,
          fontFamily: 'khand',
          color: const Color(0xFF111827),
        ),
      ),
      actions: [if (!_isLoading) _buildSortMenu(), const SizedBox(width: 8)],
    );
  }

  Widget _buildSortMenu() {
    return PopupMenuButton<String>(
      icon: Icon(Icons.sort, color: Colors.grey[700]),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: _changeSortOrder,
      itemBuilder: (context) => [
        PopupMenuItem(
          value: 'name',
          child: Row(
            children: [
              Icon(
                Icons.sort_by_alpha,
                color: _sortBy == 'name'
                    ? const Color(0xFF2563EB)
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sort by Name',
                style: TextStyle(
                  fontFamily: 'general-sans',
                  color: _sortBy == 'name'
                      ? const Color(0xFF2563EB)
                      : Colors.grey[800],
                  fontWeight: _sortBy == 'name'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
        PopupMenuItem(
          value: 'developer',
          child: Row(
            children: [
              Icon(
                Icons.people,
                color: _sortBy == 'developer'
                    ? const Color(0xFF2563EB)
                    : Colors.grey[600],
                size: 20,
              ),
              const SizedBox(width: 12),
              Text(
                'Sort by Developer',
                style: TextStyle(
                  fontFamily: 'general-sans',
                  color: _sortBy == 'developer'
                      ? const Color(0xFF2563EB)
                      : Colors.grey[800],
                  fontWeight: _sortBy == 'developer'
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading apps...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
              fontFamily: 'general-sans',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_categoryApps.isEmpty) {
      return _buildEmptyState();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
          child: Text(
            '${_categoryApps.length} app${_categoryApps.length == 1 ? '' : 's'} in ${widget.category}',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontFamily: 'general-sans',
            ),
          ),
        ),
        Expanded(
          child: GridView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _getCrossAxisCount(context),
              childAspectRatio: _getAspectRatio(context),
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _categoryApps.length,
            itemBuilder: (context, index) {
              return AppCard(
                application: _categoryApps[index],
                onTap: () {
                  context.push('/app/${_categoryApps[index].shortId}');
                },
              );
            },
          ),
        ),
      ],
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1400) return 6;
    if (width > 1100) return 5;
    if (width > 800) return 4;
    if (width > 600) return 3;
    return 2;
  }

  double _getAspectRatio(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 0.85;
    if (width > 800) return 0.9;
    if (width > 600) return 0.95;
    return 1.0;
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.category_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'No apps found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'khand',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This category doesn\'t have any apps',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'general-sans',
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.pop(),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2563EB),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Go Back',
              style: TextStyle(
                fontFamily: 'general-sans',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getDeveloper(Application app) {
    try {
      if (app.metadata.isEmpty) return 'Unknown Developer';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final dev = metadata['developer'];
      if (dev != null) {
        String devString = dev is List && dev.isNotEmpty
            ? dev.first.toString()
            : dev.toString();
        return devString.trim();
      }
      return 'Unknown Developer';
    } catch (e) {
      return 'Unknown Developer';
    }
  }

  List<String> _getCategories(Application app) {
    try {
      if (app.metadata.isEmpty) return [];
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final categoriesData = metadata['categories'];
      if (categoriesData == null) return [];
      List<dynamic> categories = categoriesData is List
          ? categoriesData
          : [categoriesData];
      return categories
          .where((c) => c != null && c.toString().trim().isNotEmpty)
          .map((c) => c.toString().trim())
          .toList();
    } catch (e) {
      return [];
    }
  }
}
