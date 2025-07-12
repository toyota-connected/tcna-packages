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
// TODO(kerberjg): turns this into a component
mixin class Camera {
  Exposure? exposure;
  Projection? projection;
  LensProjection? lens;

  // NOTE: expose this to properly support multiview
  // ignore: prefer_final_fields
  int _viewId = 0;

  void setProjection({final Projection? projection, final LensProjection? lens}) {
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
    return <String, dynamic>{
      'exposure': exposure?.toJson(),
      'projection': projection?.toJson(),
      'lens': lens?.toJson(),
      'viewId': _viewId,
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
  Vector3? _orbitOriginPoint;
  EntityGUID? _orbitOriginEntity;
  double _orbitDistance = 1;

  CameraTargetType get targetType => _orbitOriginPoint != null
      ? CameraTargetType.point
      : _orbitOriginEntity != null
      ? CameraTargetType.entity
      : CameraTargetType.none;

  Vector3? get orbitOriginPoint => _orbitOriginPoint;
  EntityGUID? get orbitOriginEntity => _orbitOriginEntity;
  double get orbitDistance => _orbitDistance;

  set orbitOriginPoint(final Vector3? point) {
    if (point != null) _orbitOriginEntity = null;
    _orbitOriginPoint = point;
  }

  set orbitOriginEntity(final EntityGUID? entity) {
    if (entity != null) _orbitOriginPoint = null;
    _orbitOriginEntity = entity;
  }

  set orbitDistance(final double distance) {
    _orbitDistance = distance;
  }

  void disableTarget() {
    _orbitOriginPoint = null;
    _orbitOriginEntity = null;
  }

  Vector3 getTargetPosition() {
    switch (targetType) {
      case CameraTargetType.point:
        return _orbitOriginPoint!;
      case CameraTargetType.entity:
        // TODO(kerberjg): get position of entity
        throw UnimplementedError("Getting transform of entity is not implemented yet.");
      case CameraTargetType.none:
        return Vector3.zero();
    }
  }

  JsonObject rigToJson() {
    return <String, dynamic>{
      'dollyOffset': dollyOffset.toJson(),
      'orbitOriginEntity': _orbitOriginEntity ?? kNullGuid,
      'orbitDistance': _orbitDistance,
    };
  }
}
