import 'package:dartz/dartz.dart';
import '../../core/permissions/permission_types.dart';
import '../../core/permissions/permission_status.dart';
import '../../helpers/errors_handler.dart';
import '../models/application_model.dart';
import '../models/flatpak_event_model.dart';
import '../models/flatpak_permission_model.dart';
import '../models/installation_model.dart';
import '../models/remote_model.dart';

abstract class FlatpakRepository {
  // Event Streams
  Stream<FlatpakEventModel> getTransactionStream(String transactionId);
  Stream<PermissionEventModel> get permissionStream;

  void startEventListening(String transactionId);
  void stopEventListening(String transactionId);
  void startPermissionListening();
  void stopPermissionListening();

  // System Info
  Future<Either<Failure, String>> getVersion();
  Future<Either<Failure, String>> getDefaultArch();
  Future<Either<Failure, List<String>>> getSupportedArches();
  Future<Either<Failure, List<Installation>>> getSystemInstallations();
  Future<Either<Failure, Installation>> getUserInstallation();
  Future<Either<Failure, Map<String, dynamic>>> getSystemStorage();

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
  Future<Either<Failure, void>> setupEventChannel(String appId);

  // Remote Management
  Future<Either<Failure, bool>> addRemote(Remote remote);
  Future<Either<Failure, bool>> removeRemote(String remoteId);

  // Permission Management
  Future<Either<Failure, void>> respondToPermissionRequest({
    required String requestId,
    required FlatpakPermission permission,
    required bool granted,
  });

  Future<Either<Failure, Map<FlatpakPermission, PermissionStatus>>>
  checkPermissions({
    required String appId,
    required List<FlatpakPermission> permissions,
  });

  Future<Either<Failure, bool>> revokePermission({
    required String appId,
    required FlatpakPermission permission,
  });

  Future<Either<Failure, bool>> grantPermission({
    required String appId,
    required FlatpakPermission permission,
  });
}