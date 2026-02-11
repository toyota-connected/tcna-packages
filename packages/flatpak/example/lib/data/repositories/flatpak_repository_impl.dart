import 'package:dartz/dartz.dart';
import 'package:flatpak_flutter_example/core/permissions/permission_status.dart';
import 'package:flatpak_flutter_example/core/permissions/permission_types.dart';
import 'package:flatpak_flutter_example/data/models/flatpak_permission_model.dart';
import '../../helpers/errors_exception.dart';
import '../../helpers/errors_handler.dart';
import '../data_sources/flatpak_event_data.dart';
import '../data_sources/flatpak_local_data.dart';
import '../data_sources/flatpak_permission_data.dart';
import '../models/application_model.dart';
import '../models/flatpak_event_model.dart';
import '../models/installation_model.dart';
import '../models/remote_model.dart';
import 'flatpak_repository.dart';

class FlatpakRepositoryImpl implements FlatpakRepository {
  final FlatpakLocalDataSource localDataSource;
  final FlatpakEventDataSource eventDataSource;
  final FlatpakPermissionDataSource permissionDataSource;

  FlatpakRepositoryImpl({
    required this.localDataSource,
    required this.eventDataSource,
    required this.permissionDataSource,
  });

  @override
  Stream<FlatpakEventModel> getTransactionStream(String transactionId) {
    return eventDataSource.getTransactionStream(transactionId);
  }

  @override
  Stream<PermissionEventModel> get permissionStream =>
      permissionDataSource.permissionStream;

  @override
  void startEventListening(String transactionId) {
    eventDataSource.startListening(transactionId);
  }

  @override
  void stopEventListening(String transactionId) {
    eventDataSource.stopListening(transactionId);
  }

  @override
  void startPermissionListening() {
    permissionDataSource.startListening();
  }

  @override
  void stopPermissionListening() {
    permissionDataSource.stopListening();
  }

  @override
  Future<Either<Failure, String>> getVersion() async {
    try {
      final version = await localDataSource.getVersion();
      return Right(version);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> getDefaultArch() async {
    try {
      final arch = await localDataSource.getDefaultArch();
      return Right(arch);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<String>>> getSupportedArches() async {
    try {
      final arches = await localDataSource.getSupportedArches();
      return Right(arches);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Installation>>> getSystemInstallations() async {
    try {
      final installations = await localDataSource.getSystemInstallations();
      return Right(installations);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, Installation>> getUserInstallation() async {
    try {
      final installation = await localDataSource.getUserInstallation();
      return Right(installation);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsInstalled() async {
    try {
      final apps = await localDataSource.getApplicationsInstalled();
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsRemote(
    String remoteId,
  ) async {
    try {
      final apps = await localDataSource.getApplicationsRemote(remoteId);
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, List<Application>>> getApplicationsUpdate() async {
    try {
      final apps = await localDataSource.getApplicationsUpdate();
      return Right(apps);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> installApplication(String appId) async {
    try {
      final transactionId = _generateTransactionId(appId, 'install');
      await localDataSource.applicationInstall(appId, transactionId);
      return Right(transactionId);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }


  @override
  Future<Either<Failure, String>> uninstallApplication(String appId) async {
    try {
      final transactionId = _generateTransactionId(appId, 'uninstall');
      await localDataSource.applicationUninstall(appId, transactionId);
      return Right(transactionId);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, String>> updateApplication(String appId) async {
    try {
      final transactionId = _generateTransactionId(appId, 'update');
      await localDataSource.applicationUpdate(appId, transactionId);
      return Right(transactionId);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> launchApplication(String appId) async {
    try {
      final result = await localDataSource.applicationStart(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> stopApplication(String appId) async {
    try {
      final result = await localDataSource.applicationStop(appId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> addRemote(Remote remote) async {
    try {
      final remoteModel = remote as RemoteModel;
      final result = await localDataSource.remoteAdd(remoteModel);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, bool>> removeRemote(String remoteId) async {
    try {
      final result = await localDataSource.remoteRemove(remoteId);
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    }
  }

  @override
  Future<Either<Failure, void>> respondToPermissionRequest({
    required String requestId,
    required FlatpakPermission permission,
    required bool granted,
  }) async {
    try {
      await permissionDataSource.respondToPermissionRequest(
        requestId: requestId,
        permission: permission,
        granted: granted,
      );
      return const Right(null);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Map<FlatpakPermission, PermissionStatus>>>
  checkPermissions({
    required String appId,
    required List<FlatpakPermission> permissions,
  }) async {
    try {
      final result = await permissionDataSource.checkPermissions(
        appId: appId,
        permissions: permissions,
      );

      // Convert bool to PermissionStatus
      final Map<FlatpakPermission, PermissionStatus> statusMap = {};
      result.forEach((permission, granted) {
        statusMap[permission] = granted
            ? PermissionStatus.granted
            : PermissionStatus.denied;
      });

      return Right(statusMap);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, bool>> revokePermission({
    required String appId,
    required FlatpakPermission permission,
  }) async {
    try {
      final result = await permissionDataSource.revokePermission(
        appId: appId,
        permission: permission,
      );
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }

  String _generateTransactionId(String appId, String operation) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final shortId = appId.split('.').last;
    return '${operation}_${shortId}_$timestamp';
  }

  @override
  Future<Either<Failure, bool>> grantPermission({
    required String appId,
    required FlatpakPermission permission,
  }) async {
    try {
      final result = await permissionDataSource.grantPermission(
        appId: appId,
        permission: permission,
      );
      return Right(result);
    } on PlatformException catch (e) {
      return Left(PlatformFailure(e.message));
    } catch (e) {
      return Left(PlatformFailure(e.toString()));
    }
  }
}