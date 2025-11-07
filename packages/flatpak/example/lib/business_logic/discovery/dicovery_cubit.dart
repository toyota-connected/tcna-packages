import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final FlatpakRepository flatpakRepository;

  final Map<String, List<Application>> _categoryCache = {};
  final List<String> _availableRemotes = [];
  List<Application> _allApps = [];
  List<Application> _updateApps = [];

  DiscoveryCubit({required this.flatpakRepository}) : super(DiscoveryInitial());

  Future<void> initialize() async {
    emit(DiscoveryLoading());

    final installationResult = await flatpakRepository.getSystemInstallations();
    installationResult.fold(
      (failure) {
        emit(DiscoveryError(failure.message));
      },
      (installations) {
        _availableRemotes.clear();
        for (final installation in installations) {
          for (final remote in installation.remotes) {
            if (!_availableRemotes.contains(remote.name)) {
              _availableRemotes.add(remote.name);
            }
          }
        }
        emit(
          DiscoveryLoaded(
            categoryApps: {},
            availableRemotes: _availableRemotes,
          ),
        );
      },
    );
  }

  Future<void> loadAllApps() async {
    if (_allApps.isNotEmpty) {
      return;
    }

    emit(DiscoveryLoading());

    final allApps = <Application>[];

    for (final remote in _availableRemotes) {
      final result = await flatpakRepository.getApplicationsRemote(remote);
      result.fold(
        (failure) {
          debugPrint(
            '[DiscoveryCubit] Error loading remote $remote: ${failure.message}',
          );
        },
        (apps) {
          if (kDebugMode) {
            print('[DiscoveryCubit] Loaded ${apps.length} apps from $remote');
          }
          allApps.addAll(apps);
        },
      );
    }

    _allApps = allApps;
    if (kDebugMode) {
      print('[DiscoveryCubit] Total apps loaded: ${_allApps.length}');
    }

    emit(
      DiscoveryLoaded(
        categoryApps: Map.from(_categoryCache),
        availableRemotes: _availableRemotes,
      ),
    );
  }

  Future<void> loadUpdateApps() async {
    if (_updateApps.isNotEmpty) {
      return;
    }
    emit(DiscoveryLoading());
    final result = await flatpakRepository.getApplicationsUpdate();
    result.fold(
      (failure) {
        emit(DiscoveryError(failure.message));
      },
      (apps) {
        _updateApps = apps;
        debugPrint(
          '[DiscoveryCubit] Apps with updates available: ${_updateApps.length}',
        );
        emit(
          DiscoveryLoaded(
            categoryApps: Map.from(_categoryCache),
            availableRemotes: _availableRemotes,
          ),
        );
      },
    );
  }

  Future<void> loadCategoryApps(
    String categoryName,
    List<String> appIds,
  ) async {
    if (_categoryCache.containsKey(categoryName)) {
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    if (_allApps.isEmpty) {
      await loadAllApps();
    }

    final categoryApps = <Application>[];
    for (final appId in appIds) {
      try {
        final app = _allApps.firstWhere(
          (a) =>
              a.id == appId ||
              a.shortId == appId ||
              a.id.contains(appId) ||
              a.shortId.contains(appId),
        );
        categoryApps.add(app);
      } catch (e) {
        debugPrint('[DiscoveryCubit] App not found: $appId');
      }
    }

    debugPrint(
      '[DiscoveryCubit] Category "$categoryName" has ${categoryApps.length} apps',
    );

    _categoryCache[categoryName] = categoryApps;

    emit(
      DiscoveryLoaded(
        categoryApps: Map.from(_categoryCache),
        availableRemotes: _availableRemotes,
      ),
    );
  }

  Future<void> loadRemoteApps(String category, String remoteId) async {
    if (_categoryCache.containsKey(category)) {
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    emit(DiscoveryLoading(category: category));

    final result = await flatpakRepository.getApplicationsRemote(remoteId);
    result.fold(
      (failure) {
        emit(DiscoveryError(failure.message));
      },
      (apps) {
        _categoryCache[category] = apps;
        emit(
          DiscoveryLoaded(
            categoryApps: Map.from(_categoryCache),
            availableRemotes: _availableRemotes,
          ),
        );
      },
    );
  }

  Future<void> searchApplications(String query, {int limit = 50}) async {
    if (query.isEmpty) {
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    emit(DiscoverySearchResults(results: [], query: query, isSearching: true));

    // Ensure all apps are loaded
    if (_allApps.isEmpty) {
      await loadAllApps();
    }

    final searchLower = query.toLowerCase();
    final results = <Application>[];
    final scores = <Application, int>{};

    for (final app in _allApps) {
      int score = 0;
      final nameLower = app.name.toLowerCase();
      final shortIdLower = app.shortId.toLowerCase();

      if (nameLower == searchLower) {
        score += 100;
      }
      // Starts with query
      else if (nameLower.startsWith(searchLower)) {
        score += 50;
      }
      // Contains query
      else if (nameLower.contains(searchLower)) {
        score += 25;
      }

      // ID matches
      if (shortIdLower.contains(searchLower)) {
        score += 15;
      }

      // Check description
      final description = _getDescription(app).toLowerCase();
      if (description.contains(searchLower)) {
        score += 10;
      }

      // Check developer
      final developer = _getDeveloper(app).toLowerCase();
      if (developer.contains(searchLower)) {
        score += 20;
      }

      // Check categories
      final categories = _getCategories(app);
      for (final category in categories) {
        if (category.toLowerCase().contains(searchLower)) {
          score += 15;
          break;
        }
      }

      if (score > 0) {
        scores[app] = score;
      }
    }

    // Sort by score and take top results
    final sortedApps = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    results.addAll(sortedApps.take(limit));

    debugPrint(
      '[DiscoveryCubit] Search "$query" found ${results.length} results',
    );

    emit(
      DiscoverySearchResults(
        isSearching: false,
        results: results,
        query: query,
      ),
    );
  }

  void clearSearch() {
    emit(
      DiscoveryLoaded(
        categoryApps: Map.from(_categoryCache),
        availableRemotes: _availableRemotes,
      ),
    );
  }

  List<Application> getCategoryApps(String category) {
    return _categoryCache[category] ?? [];
  }

  bool isCategoryLoading(String category) {
    final currentState = state;
    return currentState is DiscoveryLoading &&
        currentState.category == category;
  }

  List<Application> get allApps => List.unmodifiable(_allApps);

  // Helper methods for search
  String _getDescription(Application app) {
    try {
      if (app.appdata.isEmpty) return '';
      final appdata = jsonDecode(app.appdata) as Map<String, dynamic>;
      final description = appdata['description'] as String?;
      return description?.trim() ?? '';
    } catch (e) {
      return '';
    }
  }

  String _getDeveloper(Application app) {
    try {
      if (app.metadata.isEmpty) return '';
      final metadata = jsonDecode(app.metadata) as Map<String, dynamic>;
      final dev = metadata['developer'];
      if (dev != null) {
        String devString = dev is List && dev.isNotEmpty
            ? dev.first.toString()
            : dev.toString();
        return devString.trim();
      }
      return '';
    } catch (e) {
      return '';
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
          .where((c) => c != null)
          .map((c) => c.toString().trim())
          .toList();
    } catch (e) {
      return [];
    }
  }
}
