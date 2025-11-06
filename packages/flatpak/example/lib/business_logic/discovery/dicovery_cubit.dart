import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/flatpak_repository.dart';
import 'discovery_state.dart';

class DiscoveryCubit extends Cubit<DiscoveryState> {
  final FlatpakRepository flatpakRepository;

  final Map<String, List<Application>> _categoryCache = {};
  final List<String> _availableRemotes = [];
  List<Application> _allApps = [];

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

  /// Load all apps from all remotes and cache them
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
          print('[DiscoveryCubit] Error loading remote $remote: ${failure.message}');
        },
            (apps) {
          print('[DiscoveryCubit] Loaded ${apps.length} apps from $remote');
          allApps.addAll(apps);
        },
      );
    }

    _allApps = allApps;
    print('[DiscoveryCubit] Total apps loaded: ${_allApps.length}');

    emit(
      DiscoveryLoaded(
        categoryApps: Map.from(_categoryCache),
        availableRemotes: _availableRemotes,
      ),
    );
  }

  /// Load apps for a specific category by filtering from app IDs
  Future<void> loadCategoryApps(String categoryName, List<String> appIds) async {
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
              (a) => a.id == appId ||
              a.shortId == appId ||
              a.id.contains(appId) ||
              a.shortId.contains(appId),
        );
        categoryApps.add(app);
      } catch (e) {
        print('[DiscoveryCubit] App not found: $appId');
      }
    }

    print('[DiscoveryCubit] Category "$categoryName" has ${categoryApps.length} apps');

    _categoryCache[categoryName] = categoryApps;

    emit(
      DiscoveryLoaded(
        categoryApps: Map.from(_categoryCache),
        availableRemotes: _availableRemotes,
      ),
    );
  }

  /// Load apps from a specific remote
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

  Future<void> searchApplications(String query, {int limit = 20}) async {
    if (query.isEmpty) {
      emit(
        DiscoveryLoaded(
          categoryApps: Map.from(_categoryCache),
          availableRemotes: _availableRemotes,
        ),
      );
      return;
    }

    emit(
      DiscoverySearchResults(results: [], query: query, isSearching: true),
    );

    final searchLower = query.toLowerCase();
    final results = <Application>[];

    for (final app in _allApps) {
      if (app.name.toLowerCase().contains(searchLower) && results.length < limit) {
        results.add(app);
      }
    }

    if (results.length < limit) {
      for (final category in _categoryCache.values) {
        for (final app in category) {
          if (app.name.toLowerCase().contains(searchLower) &&
              results.length < limit &&
              !results.contains(app)) {
            results.add(app);
          }
        }
      }
    }

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
}