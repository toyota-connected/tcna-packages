import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../business_logic/discovery/discovery_cubit.dart';
import '../../business_logic/discovery/discovery_state.dart';
import '../../business_logic/installation/installation_cubit.dart';
import '../../data/models/application_model.dart';
import '../../responsive.dart';
import '../widgets/category_section.dart';

class DiscoverScreen extends StatefulWidget {
  const DiscoverScreen({super.key});

  @override
  State<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends State<DiscoverScreen> {
  final ScrollController _scrollController = ScrollController();
  Timer? _rotationTimer;

  Map<String, List<Application>> _dynamicCategories = {};
  final List<String> _displayedCategories = [];
  List<Application> _featuredApps = [];

  static const int _maxDisplayedCategories = 6;
  static const Duration _rotationInterval = Duration(minutes: 5);

  @override
  void initState() {
    super.initState();
    _initializeDiscovery();
    _startCategoryRotation();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _rotationTimer?.cancel();
    super.dispose();
  }

  Future<void> _initializeDiscovery() async {
    final cubit = context.read<DiscoveryCubit>();
    if (cubit.allApps.isEmpty) {
      await cubit.loadAllApps();
    }
    _organizeCategoriesDynamically();
    _selectRandomFeaturedApps();
  }

  void _organizeCategoriesDynamically() {
    final cubit = context.read<DiscoveryCubit>();
    final allApps = cubit.allApps;

    if (allApps.isEmpty) return;

    final Map<String, List<Application>> categoryMap = {};

    // Extract categories from each app's metadata
    for (final app in allApps) {
      final categories = _getCategories(app);

      for (final category in categories) {
        final cleanCategory = _cleanCategoryName(category);
        if (cleanCategory.isNotEmpty) {
          categoryMap.putIfAbsent(cleanCategory, () => []);
          if (!categoryMap[cleanCategory]!.any((a) => a.id == app.id)) {
            categoryMap[cleanCategory]!.add(app);
          }
        }
      }
    }

    _dynamicCategories = Map.fromEntries(
      categoryMap.entries.where((entry) => entry.value.length >= 3),
    );

    // Sort categories by number of apps
    final sortedEntries = _dynamicCategories.entries.toList()
      ..sort((a, b) => b.value.length.compareTo(a.value.length));

    _dynamicCategories = Map.fromEntries(sortedEntries);

    debugPrint(
      '[DiscoverScreen] Found ${_dynamicCategories.length} categories',
    );

    _selectRandomCategories();
  }

  void _selectRandomCategories() {
    if (_dynamicCategories.isEmpty) return;

    final allCategoryNames = _dynamicCategories.keys.toList();
    final random = Random();

    final priorityCategories = [
      'Graphics & Photography',
      'Development',
      'Audio & Video',
      'Game',
      'Network',
      'Office',
      'Utility',
      'Education',
      'Science',
    ];

    _displayedCategories.clear();

    for (final category in priorityCategories) {
      if (_dynamicCategories.containsKey(category) &&
          _displayedCategories.length < _maxDisplayedCategories) {
        _displayedCategories.add(category);
      }
    }

    while (_displayedCategories.length < _maxDisplayedCategories &&
        _displayedCategories.length < allCategoryNames.length) {
      final randomCategory =
          allCategoryNames[random.nextInt(allCategoryNames.length)];
      if (!_displayedCategories.contains(randomCategory)) {
        _displayedCategories.add(randomCategory);
      }
    }

    debugPrint('[DiscoverScreen] Displaying categories: $_displayedCategories');

    if (mounted) {
      setState(() {});
    }
  }

  void _selectRandomFeaturedApps() {
    final cubit = context.read<DiscoveryCubit>();
    final allApps = cubit.allApps;

    if (allApps.isEmpty) return;

    final random = Random();
    final shuffled = List<Application>.from(allApps)..shuffle(random);

    _featuredApps = shuffled.take(10).toList();

    if (mounted) {
      setState(() {});
    }
  }

  void _startCategoryRotation() {
    _rotationTimer = Timer.periodic(_rotationInterval, (timer) {
      debugPrint('[DiscoverScreen] Rotating categories...');
      _selectRandomCategories();
      _selectRandomFeaturedApps();
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
      body: RefreshIndicator(
        onRefresh: () async {
          await _initializeDiscovery();
        },
        child: CustomScrollView(
          controller: _scrollController,
          slivers: [
            _buildHeader(),
            BlocBuilder<DiscoveryCubit, DiscoveryState>(
              builder: (context, state) {
                if (state is DiscoveryLoading) {
                  return const SliverFillRemaining(
                    child: Center(child: CircularProgressIndicator()),
                  );
                }

                if (state is DiscoveryError) {
                  return SliverFillRemaining(
                    child: _buildErrorState(state.message),
                  );
                }

                return SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 20),
                    if (_featuredApps.isNotEmpty) ...[
                      _buildFeaturedSection(),
                      const SizedBox(height: 32),
                    ],
                    ..._buildCategorySections(),
                    const SizedBox(height: 80),
                  ]),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Colors.white.withValues(alpha: 0.25),
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: FlexibleSpaceBar(
            titlePadding: const EdgeInsets.only(left: 32, bottom: 16),
            title: Text(
              'Discover',
              style: TextStyle(
                fontSize: Responsive.scale(context, 28).clamp(20, 32),
                fontWeight: FontWeight.bold,
                fontFamily: 'khand',
                color: const Color(0xFF111827),
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomRight,
                  end: Alignment.topLeft,
                  transform: const GradientRotation(45 * 3.1416 / 180),
                  colors: [
                    const Color(0xFF6366F1).withValues(alpha: 0.1),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                    const Color(0xFF22D3EE).withValues(alpha: 0.1),
                    const Color(0xFF33D17A).withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturedSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Featured Apps',
            style: TextStyle(
              color: const Color(0xFF111827),
              fontSize: Responsive.scale(context, 24).clamp(16, 28),
              fontWeight: FontWeight.bold,
              fontFamily: 'khand',
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: Responsive.scaleWithConstraints(context, 200, minSize: 180, maxSize: 260),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _featuredApps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: _buildFeaturedCard(_featuredApps[index]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCard(Application app) {
    return SizedBox(
      width: Responsive.scaleWithConstraints(context, 300, minSize: 260, maxSize: 380),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.4),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/app/${app.shortId}'),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildAppIcon(app, size: 64),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  app.name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'khand',
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  _getDeveloper(app),
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontFamily: 'general-sans',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _getDescription(app),
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          fontFamily: 'general-sans',
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildCategorySections() {
    final sections = <Widget>[];

    for (final categoryName in _displayedCategories) {
      final apps = _dynamicCategories[categoryName] ?? [];

      if (apps.isEmpty) continue;

      sections.add(
        CategorySection(
          category_heading: categoryName,
          apps: apps.take(20).toList(),
          onTap: (app) {
            context.push('/app/${app.shortId}');
          },
          onInstall: (app) {
            context.read<InstallationCubit>().installApp(app.id);
          },
          isLoading: false,
        ),
      );
      sections.add(const SizedBox(height: 32));
    }

    return sections;
  }

  Widget _buildAppIcon(Application app, {double size = 64}) {
    final iconPath = _getIconPath(app);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(size * 0.25),
        child: iconPath != null
            ? _buildIconImage(iconPath, size)
            : _buildDefaultIcon(size),
      ),
    );
  }

  Widget _buildIconImage(String iconPath, double size) {
    if (iconPath.startsWith('http')) {
      return Image.network(
        iconPath,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(size),
      );
    } else {
      final file = File(iconPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) => _buildDefaultIcon(size),
        );
      }
      return _buildDefaultIcon(size);
    }
  }

  Widget _buildDefaultIcon(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF6366F1),
        borderRadius: BorderRadius.circular(size * 0.25),
      ),
      child: Icon(Icons.apps, color: Colors.white, size: size * 0.5),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Error loading apps',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
              fontFamily: 'khand',
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
                fontFamily: 'general-sans',
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _initializeDiscovery,
            child: const Text('Retry'),
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

  String _getDescription(Application app) {
    try {
      if (app.appdata.isEmpty) return 'No description available';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final description = appdata['description'] as String?;
      if (description != null && description.isNotEmpty) {
        final cleanDesc = description.replaceAll(RegExp(r'<[^>]*>'), '');
        return cleanDesc.trim();
      }
      return 'No description available';
    } catch (e) {
      return 'No description available';
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

  String? _getIconPath(Application app) {
    try {
      if (app.appdata.isEmpty) return null;
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final icons = appdata['icons'] as List<dynamic>?;
      if (icons != null) {
        for (final iconType in ['remote', 'cached', 'local']) {
          for (final icon in icons) {
            if (icon is Map<String, dynamic> && icon['type'] == iconType) {
              final path = icon['path'] as String?;
              if (icon['type'] == 'cached') {
                return '/var/lib/flatpak/appstream/flathub/x86_64/active/icons/128x128/$path';
              }
              if (path != null) return path;
            }
          }
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
