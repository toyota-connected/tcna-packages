import 'package:dartz/dartz.dart';
import '../../helpers/errors_exception.dart';
import '../../helpers/errors_handler.dart';
import '../data_sources/flatpak_event_data.dart';
import '../data_sources/flatpak_local_data.dart';
import '../models/application_model.dart';
import '../models/flatpak_event_model.dart';
import '../models/installation_model.dart';
import '../models/remote_model.dart';
import 'flatpak_repository.dart';

class FlatpakRepositoryImpl implements FlatpakRepository {
  final FlatpakLocalDataSource localDataSource;
  final FlatpakEventDataSource eventDataSource;

  FlatpakRepositoryImpl({
    required this.localDataSource,
    required this.eventDataSource,
  });

  @override
  Stream<FlatpakEventModel> get eventStream => eventDataSource.eventStream;

  @override
  void startEventListening() {
    eventDataSource.startListening();
  }

  @override
  void stopEventListening() {
    eventDataSource.stopListening();
  }

  @override
  Future<Either<Failure, String>> getVersion() async {
    try {
      final version = await localDataSource.getVersion();
      return Right(version);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultArch() async {
    try {
      final arch = await localDataSource.getDefaultArch();
      return Right(arch);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSupportedArches() async {
    try {
      final arches = await localDataSource.getSupportedArches();
      return Right(arches);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, List<Installation>>> getSystemInstallations() async {
    try {
      final installations = await localDataSource.getSystemInstallations();
      return Right(installations);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, Installation>> getUserInstallation() async {
    try {
      final installation = await localDataSource.getUserInstallation();
      return Right(installation);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsInstalled() async {
    try {
      final apps = await localDataSource.getApplicationsInstalled();
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsRemote(
      String remoteId) async {
    try {
      final apps = await localDataSource.getApplicationsRemote(remoteId);
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsUpdate() async {
    try {
      final apps = await localDataSource.getApplicationsUpdate();
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Platform error'));
    }
  }

  @override
  Future<Either<Failure, bool>> installApplication(String appId) async {
    try {
      final result = await localDataSource.applicationInstall(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Installation failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> uninstallApplication(String appId) async {
    try {
      final result = await localDataSource.applicationUninstall(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Uninstallation failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> updateApplication(String appId) async {
    try {
      final result = await localDataSource.applicationUpdate(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Update failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> launchApplication(String appId) async {
    try {
      final result = await localDataSource.applicationStart(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Launch failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> stopApplication(String appId) async {
    try {
      final result = await localDataSource.applicationStop(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Stop failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> addRemote(Remote remote) async {
    try {
      final remoteModel = remote as RemoteModel;
      final result = await localDataSource.remoteAdd(remoteModel);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Add remote failed'));
    }
  }

  @override
  Future<Either<Failure, bool>> removeRemote(String remoteId) async {
    try {
      final result = await localDataSource.remoteRemove(remoteId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message ?? 'Remove remote failed'));
    }
  }
}