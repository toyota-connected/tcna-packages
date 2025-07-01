import 'package:filament_scene/filament_scene.dart';
import 'package:filament_scene/scene/camera/exposure.dart';
import 'package:filament_scene/scene/camera/lens_projection.dart';
import 'package:filament_scene/scene/camera/projection.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

/// Default camera exposure settings.
const Exposure kDefaultExposure = Exposure.fromAperture(
  aperture: 24,
  shutterSpeed: 1 / 60,
  sensitivity: 150,
);

/// Default camera projection settings (don't use together with [kDefaultLens]).
const Projection kDefaultProjection = Projection();

/// Default camera lens projection settings (don't use together with [kDefaultProjection]).
const LensProjection kDefaultLens = LensProjection();

typedef CameraHead = Camera;

/// A class that represents the camera settings for a scene.
/// TODO(kerberjg): turns this into a component
mixin class Camera {
  Exposure? exposure;
  Projection? projection;
  LensProjection? lens;

  void setProjection({
    final Projection? projection,
    final LensProjection? lens,
  }) {
    assert(
      (projection == null && lens == null) ||
      (projection != null && lens == null) ||
      (projection == null && lens != null),
      "Either projection or lens must be set, but not both.",
    );

    this.projection = projection;
    this.lens = lens;
  }

  JsonObject cameraToJson() {
    return toJson();
  }

  JsonObject toJson() {
    return <String, dynamic>{
      'exposure': exposure?.toJson(),
      'projection': projection?.toJson(),
      'lens': lens?.toJson(),
    };
  }
}

enum CameraTargetType {
  /// No target, camera rotation is controlled by its transform directly.
  none,
  /// Camera is looking at a point in space.
  point,
  /// Camera is looking at an entity.
  entity,
}

// ignore_for_file: unnecessary_getters_setters
abstract mixin class CameraRig {
  /// Camera's offset relative to its rig
  Vector3 _dollyOffset = Vector3.zero();

  Vector3 get dollyOffset => _dollyOffset;
  set dollyOffset(final Vector3 offset) {
    _dollyOffset = offset;
  }
  /*
   *  Targeting
   */
  Vector3? _targetPoint;
  EntityGUID? _targetEntity;
  double _targetDistance = 1;

  CameraTargetType get targetType =>
    _targetPoint != null
      ? CameraTargetType.point
      : _targetEntity != null
        ? CameraTargetType.entity
        : CameraTargetType.none;

  Vector3? get targetPoint => _targetPoint;
  EntityGUID? get targetEntity => _targetEntity;
  double get targetDistance => _targetDistance;

  set targetPoint(final Vector3? point) {
    _targetPoint = point;
    _targetEntity = null;
  }

  set targetEntity(final EntityGUID? entity) {
    _targetPoint = null;
    _targetEntity = entity;
  }

  set targetDistance(final double distance) {
    _targetDistance = distance;
  }

  void disableTarget() {
    _targetPoint = null;
    _targetEntity = null;
  }

  Vector3 getTargetPosition() {
    switch (targetType) {
      case CameraTargetType.point:
        return _targetPoint!;
      case CameraTargetType.entity:
        // TODO(kerberjg): get position of entity
        throw UnimplementedError("Getting transform of entity is not implemented yet.");
      case CameraTargetType.none:
        return Vector3.zero();
    }
  }

  JsonObject rigToJson() {
    return toJson();
  }

  JsonObject toJson() {
    return <String, dynamic>{
      'dollyOffset': dollyOffset.toJson(),
      'targetPoint': _targetPoint?.toJson() ?? Vector3.zero().toJson(),
      'targetEntity': _targetEntity ?? kNullGuid,
      'targetDistance': _targetDistance,
    };
  }

}
