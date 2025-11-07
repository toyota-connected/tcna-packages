import 'package:flatpak_flutter/src/messages.g.dart';
import '../models/application_model.dart';
import '../models/installation_model.dart';
import '../models/remote_model.dart';

abstract class FlatpakLocalDataSource {
  Future<String> getVersion();
  Future<String> getDefaultArch();
  Future<List<String>> getSupportedArches();
  Future<List<InstallationModel>> getSystemInstallations();
  Future<InstallationModel> getUserInstallation();
  Future<bool> remoteAdd(RemoteModel remote);
  Future<bool> remoteRemove(String id);
  Future<List<ApplicationModel>> getApplicationsInstalled();
  Future<List<ApplicationModel>> getApplicationsUpdate();
  Future<List<ApplicationModel>> getApplicationsRemote(String remoteId);
  Future<bool> applicationInstall(String id);
  Future<bool> applicationUninstall(String id);
  Future<bool> applicationUpdate(String id);
  Future<bool> applicationStart(String id);
  Future<bool> applicationStop(String id);
}

class FlatpakLocalDataSourceImpl implements FlatpakLocalDataSource {
  final FlatpakApi _api;

  FlatpakLocalDataSourceImpl(this._api);

  @override
  Future<String> getVersion() async {
    return _api.getVersion();
  }

  @override
  Future<String> getDefaultArch() async {
    return _api.getDefaultArch();
  }

  @override
  Future<List<String>> getSupportedArches() async {
    final arches = await _api.getSupportedArches();
    return arches.whereType<String>().toList();
  }

  @override
  Future<List<InstallationModel>> getSystemInstallations() async {
    final installations = await _api.getSystemInstallations();
    return installations.map((i) => InstallationModel.fromPigeon(i)).toList();
  }

  @override
  Future<InstallationModel> getUserInstallation() async {
    final installation = await _api.getUserInstallation();
    return InstallationModel.fromPigeon(installation);
  }

  @override
  Future<bool> remoteAdd(RemoteModel remote) async {
    return await _api.remoteAdd(remote.toPigeon());
  }

  @override
  Future<bool> remoteRemove(String id) async {
    return await _api.remoteRemove(id);
  }

  @override
  Future<List<ApplicationModel>> getApplicationsInstalled() async {
    final apps = await _api.getApplicationsInstalled();
    return apps.map((a) => ApplicationModel.fromPigeon(a)).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsUpdate() async {
    final apps = await _api.getApplicationsUpdate();
    return apps.map((a) => ApplicationModel.fromPigeon(a)).toList();
  }

  @override
  Future<List<ApplicationModel>> getApplicationsRemote(String remoteId) async {
    final apps = await _api.getApplicationsRemote(remoteId);
    return apps.map((a) => ApplicationModel.fromPigeon(a)).toList();
  }

  @override
  Future<bool> applicationInstall(String id) async {
    return await _api.applicationInstall(id);
  }

  @override
  Future<bool> applicationUninstall(String id) async {
    return await _api.applicationUninstall(id);
  }

  @override
  Future<bool> applicationUpdate(String id) async {
    return await _api.applicationUpdate(id);
  }

  @override
  Future<bool> applicationStart(String id) async {
    return await _api.applicationStart(id);
  }

  @override
  Future<bool> applicationStop(String id) async {
    return await _api.applicationStop(id);
  }
}
