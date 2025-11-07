import 'package:dartz/dartz.dart';

import '../../helpers/errors_handler.dart';
import '../models/application_model.dart';
import '../models/flatpak_event_model.dart';
import '../models/installation_model.dart';
import '../models/remote_model.dart';

abstract class FlatpakRepository {
  // Event Stream
  Stream<FlatpakEventModel> get eventStream;
  void startEventListening();
  void stopEventListening();

  // System Info
  Future<Either<Failure, String>> getVersion();
  Future<Either<Failure, String>> getDefaultArch();
  Future<Either<Failure, List<String>>> getSupportedArches();
  Future<Either<Failure, List<Installation>>> getSystemInstallations();
  Future<Either<Failure, Installation>> getUserInstallation();

  // Application Discovery
  Future<Either<Failure, List<Application>>> getApplicationsInstalled();
  Future<Either<Failure, List<Application>>> getApplicationsRemote(
    String remoteId,
  );
  Future<Either<Failure, List<Application>>> getApplicationsUpdate();

  // Application Management
  Future<Either<Failure, bool>> installApplication(String appId);
  Future<Either<Failure, bool>> uninstallApplication(String appId);
  Future<Either<Failure, bool>> updateApplication(String appId);
  Future<Either<Failure, bool>> launchApplication(String appId);
  Future<Either<Failure, bool>> stopApplication(String appId);

  // Remote Management
  Future<Either<Failure, bool>> addRemote(Remote remote);
  Future<Either<Failure, bool>> removeRemote(String remoteId);
}
