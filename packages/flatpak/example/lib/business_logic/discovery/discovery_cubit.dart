import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import '../../helpers/id_utils.dart';
import 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final FlatpakRepository flatpakRepository;

  final Map<String, List<Application>> _categoryCache = {};
  final List<String> _availableRemotes = [];
  List<Application> _allApps = [];
  List<Application> _updateApps = [];

  DiscoveryCubit({required this.flatpakRepository}) : super(DiscoveryInitial());

  Future<void> initialize() async {
    debugPrint('[DiscoveryCubit] Initializing...');
    emit(DiscoveryLoading());

    final installationResult = await flatpakRepository.getSystemInstallations();
    installationResult.fold(
          (failure) {
        debugPrint('[DiscoveryCubit] Initialization failed: ${failure.message}');
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
        debugPrint('[DiscoveryCubit] Available remotes: $_availableRemotes');
        emit(
          DiscoveryLoaded(
            categoryApps: {},
            availableRemotes: _availableRemotes,
          ),
        );
      },
    );
  }

  Future<void> loadAllApps({bool forceReload = false}) async {
    // Allow reloading even if apps are already loaded
    if (_allApps.isNotEmpty && !forceReload) {
      debugPrint('[DiscoveryCubit] Apps already loaded: ${_allApps.length}');
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    debugPrint('[DiscoveryCubit] Loading all apps from remotes (force: $forceReload)...');

    // Don't emit loading if we already have apps
    if (_allApps.isEmpty) {
      emit(DiscoveryLoading());
    }

    final allApps = <Application>[];

    for (final remote in _availableRemotes) {
      debugPrint('[DiscoveryCubit] Fetching apps from remote: $remote');
      final result = await flatpakRepository.getApplicationsRemote(remote);
      result.fold(
            (failure) {
          debugPrint('[DiscoveryCubit] Error loading remote $remote: ${failure.message}');
        },
            (apps) {
          debugPrint('[DiscoveryCubit] Loaded ${apps.length} apps from $remote');
          allApps.addAll(apps);
        },
      );
    }

    _allApps = allApps;
    debugPrint('[DiscoveryCubit] Total apps loaded: ${_allApps.length}');

    if (_allApps.isNotEmpty && _allApps.length >= 5) {
      debugPrint('[DiscoveryCubit] Sample app IDs:');
      for (var i = 0; i < 5; i++) {
        final app = _allApps[i];
        debugPrint('  $i. Full ID: ${app.id}');
        debugPrint('     Short ID: ${app.shortId}');
        debugPrint('     Name: ${app.name}');
      }
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
        debugPrint('[DiscoveryCubit] Apps with updates available: ${_updateApps.length}');
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
      debugPrint('[DiscoveryCubit] Category "$categoryName" already cached with ${_categoryCache[categoryName]!.length} apps');
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    // Ensure all apps are loaded first
    if (_allApps.isEmpty) {
      debugPrint('[DiscoveryCubit] All apps not loaded yet, loading...');
      await loadAllApps();

      if (_allApps.isEmpty) {
        debugPrint('[DiscoveryCubit] No apps available after loading!');
        _categoryCache[categoryName] = [];
        emit(
          DiscoveryLoaded(
            categoryApps: Map.from(_categoryCache),
            availableRemotes: _availableRemotes,
          ),
        );
        return;
      }
    }

    debugPrint('[DiscoveryCubit] Loading category "$categoryName" with ${appIds.length} app IDs');
    debugPrint('[DiscoveryCubit] Searching in ${_allApps.length} available apps');

    final categoryApps = <Application>[];
    int matchedCount = 0;

    for (final requestedId in appIds) {
      try {
        Application? foundApp;

        foundApp = _allApps.cast<Application?>().firstWhere(
              (a) => a!.shortId.toLowerCase() == requestedId.toLowerCase(),
          orElse: () => null,
        );

        foundApp ??= _allApps.cast<Application?>().firstWhere(
                (a) => a!.id.toLowerCase() == requestedId.toLowerCase(),
            orElse: () => null,
          );

        if (foundApp == null) {
          final requestedShortId = AppIdUtils.extractShortId(requestedId);
          foundApp = _allApps.cast<Application?>().firstWhere(
                (a) => AppIdUtils.extractShortId(a!.id).toLowerCase() == requestedShortId.toLowerCase(),
            orElse: () => null,
          );
        }

        foundApp ??= _allApps.cast<Application?>().firstWhere(
                (a) => a!.shortId.toLowerCase().contains(requestedId.toLowerCase()),
            orElse: () => null,
          );

        foundApp ??= _allApps.cast<Application?>().firstWhere(
                (a) => a!.id.toLowerCase().contains(requestedId.toLowerCase()),
            orElse: () => null,
          );

        if (foundApp == null) {
          final requestedLower = requestedId.toLowerCase();
          foundApp = _allApps.cast<Application?>().firstWhere(
                (a) => a!.name.toLowerCase().contains(requestedLower),
            orElse: () => null,
          );
        }

        if (foundApp != null) {
          categoryApps.add(foundApp);
          matchedCount++;
          debugPrint('[DiscoveryCubit] Matched "$requestedId" -> ${foundApp.name} (${foundApp.shortId})');
        } else {
          debugPrint('[DiscoveryCubit] Not found: "$requestedId"');
        }
      } catch (e) {
        debugPrint('[DiscoveryCubit] Error matching "$requestedId": $e');
      }
    }

    debugPrint('[DiscoveryCubit] Category "$categoryName": matched $matchedCount/${appIds.length} apps');

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
      } else if (nameLower.startsWith(searchLower)) {
        score += 50;
      } else if (nameLower.contains(searchLower)) {
        score += 25;
      }

      if (shortIdLower.contains(searchLower)) {
        score += 15;
      }

      final description = _getDescription(app).toLowerCase();
      if (description.contains(searchLower)) {
        score += 10;
      }

      final developer = _getDeveloper(app).toLowerCase();
      if (developer.contains(searchLower)) {
        score += 20;
      }

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

    final sortedApps = scores.keys.toList()
      ..sort((a, b) => scores[b]!.compareTo(scores[a]!));

    results.addAll(sortedApps.take(limit));

    debugPrint('[DiscoveryCubit] Search "$query" found ${results.length} results');

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

  /// Force reload all data from system
  Future<void> refreshAll() async {
    debugPrint('[DiscoveryCubit] Force refreshing all data...');
    _allApps.clear();
    _categoryCache.clear();
    await loadAllApps(forceReload: true);
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