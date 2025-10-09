import 'package:flatpak_flutter/src/messages.g.dart';

class FlatpakService {
  final FlatpakApi _api = FlatpakApi();

  Future<List<Application>> getApplicationsInstalled() async {
    return await _api.getApplicationsInstalled();
  }

  Future<List<Application>> getApplicationsRemote(String remoteName) async {
    return await _api.getApplicationsRemote(remoteName);
  }

  Future<Installation> getUserInstallations() async {
    return await _api.getUserInstallation();
  }

  Future<List<Installation>> getSystemInstallations() async {
    return await _api.getSystemInstallations();
  }

  Future<bool> ApplicationInstall(String appId) async {
    return await _api.applicationInstall(appId);
  }

  Future<bool> ApplicationUninstall(String appId) async {
    return await _api.applicationUninstall(appId);
  }

  
  Future<bool> remoteAdd(Remote remote) async {
    return await _api.remoteAdd(remote);
  }

  Future<bool> remoteRemove(String remoteName) async {
    return await _api.remoteRemove(remoteName);
  }

  Future<List<String?>> getSupportedArches()  {
    return  _api.getSupportedArches();
  }

  Future<bool> ApplicationStart(String id) async{
    return _api.applicationStart(id);
  }

  Future<bool> ApplicationStop(String id) async{
    return _api.applicationStop(id);
  }
}
