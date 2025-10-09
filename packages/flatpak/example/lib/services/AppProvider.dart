import 'dart:async';
import 'dart:core';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'flatpak_service.dart';
import 'package:flatpak_flutter/src/messages.g.dart';

class AppStateProvider extends ChangeNotifier {
  String _errorMessage = '';
  bool _isInitializing = false;

  bool get isInitialized => !_isInitializing;
  String get errorMessage => _errorMessage;

  void setInitialize(bool value){
    if (_isInitializing != value) {
      _isInitializing = value;
      notifyListeners();
    }
  }

  void setError(String error){
    if (_errorMessage != error) {
      _errorMessage = error;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage.isNotEmpty) {
      _errorMessage = '';
      notifyListeners();
    }
  }
}

class AppsProvider extends ChangeNotifier {
  final FlatpakService _flatpakService = FlatpakService();
  Timer? _refreshTimer;

  Map<String, List<Application>> _categoryApps = {};
  Set<String> _installedAppIds = {};
  Set<String> _installingApps = {};
  List<String> _availableRemotes = [];

  List<Application> _searchResults = [];
  String _lastSearchQuery = '';
  bool _isSearching = false;

  bool _loadingCategories = false;
  bool _loadingInstalled = false;
  Map<String, bool> _categoryLoadingStates = {};

  Map<String, List<Application>> get cateogryApps => Map.unmodifiable(_categoryApps);
  Set<String> get installedAppsIds => Set.unmodifiable(_installedAppIds);
  Set<String> get installingApps => Set.unmodifiable(_installingApps);
  List<String> get availableRemotes => List.unmodifiable(_availableRemotes);
  List<Application> get searchResults => List.unmodifiable(_searchResults);
  String get lastSearchQuery => _lastSearchQuery;
  bool get isSearching => _isSearching;
  bool get loadingCategories => _loadingCategories;
  bool get loadingInstalled => _loadingInstalled;

  bool isAppInstalled(String appId) {
    final shortId = _extractAppId(appId);
    return _installedAppIds.contains(shortId);
  }

  bool isAppInstalling(String appId) {
    final shortId = _extractAppId(appId);
    return _installingApps.contains(shortId);
  }

  bool isCategoryLoading(String category) => _categoryLoadingStates[category] ?? false;

  List<Application> getCategoryApps(String category){
    return _categoryApps[category] ?? [];
  }

  Future<void> initialize() async {
    await loadRemotes();
    await loadInstalled();
    startAutoRefresh();
  }

  void startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      refreshInstallationStatus();
    });
  }

  Future<void> loadRemotes() async {
    try{
      final installations = await _flatpakService.getSystemInstallations();
      _availableRemotes.clear();

      for(final installation in installations){
        for(final remote in installation.remotes){
          if(!_availableRemotes.contains(remote.name)) {
            _availableRemotes.add(remote.name);
          }
        }
      }

      notifyListeners();
    } catch(e){
      throw Exception('Failed loading remotes: $e');
    }
  }

  Future<void> loadInstalled() async {
    _loadingInstalled = true;
    notifyListeners();

    try {
      final installedApps = await _flatpakService.getApplicationsInstalled();
      final newInstalledIds = installedApps
          .map((app) => _extractAppId(app.id))
          .toSet();

      if (kDebugMode) {
        print('Loaded ${newInstalledIds.length} installed apps (short IDs):');
        print('Short IDs: $newInstalledIds');
      }

      if (!_installedAppIds.containsAll(newInstalledIds) ||
          !newInstalledIds.containsAll(_installedAppIds)) {
        _installedAppIds.clear();
        _installedAppIds.addAll(newInstalledIds);
        notifyListeners();
      }
    } catch(e) {
      print('Error loading apps: $e');
    } finally {
      _loadingInstalled = false;
      notifyListeners();
    }
  }

  Future<void> loadCategoryApps(String category, List<String> appIds) async {
    if(_categoryApps.containsKey(category)){
      return;
    }

    _categoryLoadingStates[category] = true;
    notifyListeners();

    try{
      final apps = <Application>[];
      const batchSize = 5;
      for(int i = 0; i < appIds.length; i += batchSize) {
        final batch = appIds.skip(i).take(batchSize);
        final batchApps = await Future.wait(
          batch.map((id) => _findAppById(id)),
        );
        for(final app in batchApps) {
          if(app != null){
            apps.add(app);
          }
        }

        _categoryApps[category] = List.from(apps);
        notifyListeners();
        if(i + batchSize < appIds.length){
          await Future.delayed(const Duration(milliseconds: 100));
        }
      }

    } catch(e) {
      print('Error loading category $category: $e');
    }finally {
      _categoryLoadingStates[category] = false;
      notifyListeners();
    }
  }

  Future<void> searchApps(String query, {int limit = 20}) async {
    if(query.isEmpty) {
      _searchResults.clear();
      _lastSearchQuery = '';
      notifyListeners();
      return;
    }

    _isSearching = true;
    _lastSearchQuery = query;
    notifyListeners();

    try{
      final results = <Application>[];
      final searchLower = query.toLowerCase();

      for (final categoryApps in _categoryApps.values) {
        for (final app in categoryApps) {
          if (app.name.toLowerCase().contains(searchLower) && results.length < limit) {
            results.add(app);
          }
        }
      }

      if (results.length < limit) {
        for (final remote in _availableRemotes) {
          if (results.length >= limit) break;

          try {
            final remoteApps = await _flatpakService.getApplicationsRemote(remote);
            final matches = remoteApps
                .where((app) => app.name.toLowerCase().contains(searchLower))
                .take(limit - results.length);
            results.addAll(matches);
          } catch (e) {
            if (kDebugMode) {
              print('Error searching remote $remote: $e');
            }
          }
        }
      }

      _searchResults = results;
    } catch(e) {
      print('Error searching apps: $e');
      _searchResults = [];
    } finally {
      _isSearching = false;
      notifyListeners();
    }
  }

  String _extractAppId(String fullId) {
    if (fullId.startsWith('app/')) {
      final parts = fullId.split('/');
      if (parts.length >= 2) {
        return parts[1];
      }
    }
    return fullId;
  }

  Future<Application?> _findAppById(String id) async {
    for(final categoryApps in _categoryApps.values) {
      try{
        return categoryApps.firstWhere((app) => app.id == id);
      } catch(e) {
        continue;
      }
    }

    for(final remote in _availableRemotes) {
      try{
        final apps = await _flatpakService.getApplicationsRemote(remote);
        return apps.firstWhere((app) => app.id == id);
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  @override
  Future<bool> installApp(String id) async {
    final shortId = _extractAppId(id);

    if (_installingApps.contains(shortId) || _installedAppIds.contains(shortId)) {
      return _installedAppIds.contains(shortId);
    }

    _installingApps.add(shortId);
    notifyListeners();

    try {
      final success = await _flatpakService.ApplicationInstall(id);

      if (success) {
        Timer(Duration(seconds: 2), () async {
          await refreshInstallationStatus();
          _installingApps.remove(shortId);
          notifyListeners();
        });
      } else {
        _installingApps.remove(shortId);
        notifyListeners();
      }

      return success;
    } catch (e) {
      _installingApps.remove(shortId);
      notifyListeners();
      return false;
    }
  }

  Future<bool> uninstallApp(String id) async {
    final shortId = _extractAppId(id);

    try{
      final uninstall = await _flatpakService.ApplicationUninstall(id);

      if(uninstall){
        _installedAppIds.remove(shortId);
        notifyListeners();
        await refreshInstallationStatus();
      }
      return uninstall;
    } catch(e){
      if (kDebugMode) {
        print('Error uninstalling app $id: $e');
      }
      return false;
    }
  }

  Future<bool> openApp(String id) async {
    final shortId = _extractAppId(id);

    try{
      final start = await _flatpakService.ApplicationStart(id);


      return start;
    } catch(e){
      if (kDebugMode) {
        print('Error starting app $id: $e');
      }
      return false;
    }
  }

  Future<void> refreshInstallationStatus() async {
    _loadingInstalled = true;
    notifyListeners();
    try{
      final installedApps = await _flatpakService.getApplicationsInstalled();
      final newInstalledIds = installedApps
          .map((app) => _extractAppId(app.id))
          .toSet();

      if (!_installedAppIds.containsAll(newInstalledIds) ||
          !newInstalledIds.containsAll(_installedAppIds)) {
        _installedAppIds.clear();
        _installedAppIds.addAll(newInstalledIds);
        notifyListeners();
      }
    }catch(e){
      if (kDebugMode) {
        print('Error Loading installed Apps: $e');
      }
    } finally{
      _loadingInstalled = false;
      notifyListeners();
    }
  }

  void clearSearch() {
    _searchResults.clear();
    _lastSearchQuery = '';
    _isSearching = false;
    notifyListeners();
  }

  void clear() {
    _categoryApps.clear();
    _installedAppIds.clear();
    _installingApps.clear();
    _searchResults.clear();
    _availableRemotes.clear();
    _categoryLoadingStates.clear();
    _lastSearchQuery = '';
    _isSearching = false;
    _loadingInstalled = false;
    _loadingCategories = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
