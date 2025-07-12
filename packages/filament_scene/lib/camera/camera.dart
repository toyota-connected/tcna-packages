import 'dart:async';

import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/components/camera.dart' as CameraComponent;
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/math/utils.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/guid.dart';
import 'package:filament_scene/utils/serialization.dart';

/// This [Entity] represents a camera in the scene.
/// It's composed by two entities:
/// - rig (entity): centered at the [orbitOriginPoint], [orbitOriginEntity] or [position];
///                 its rotation is used to control the camera's orbit (Y, X)
/// - head (camera eye): always at (x:0, y:0, z: [orbitDistance]) + [dollyOffset] relative to the rig;
///
class Camera extends TransformEntity with CameraComponent.Camera, CameraComponent.CameraRig {
  Camera({
    required super.id,
    super.name,
    // Target
    final Vector3? dollyOffset,
    // Orbit
    final Vector3? orbitOriginPoint,
    final EntityGUID? orbitOriginEntity,
    final double orbitDistance = 0,

    /// The orbit rotation euler angles in radians.
    final Vector2? orbitAngles,
    final double? roll = 0,
  }) : super(position: Vector3.zero(), scale: Vector3.all(1), rotation: Quaternion.identity()) {
    // Set default projection
    setProjection(projection: CameraComponent.kDefaultProjection);
    exposure = CameraComponent.kDefaultExposure;

    // Set target
    assert(
      orbitOriginPoint != null || orbitOriginEntity != null,
      "Either targetPosition or orbitOriginEntity must be provided, but not both.",
    );

    super.orbitOriginPoint = orbitOriginPoint;
    super.orbitOriginEntity = orbitOriginEntity;
    super.orbitDistance = orbitDistance;

    super.dollyOffset = dollyOffset ?? Vector3.zero();

    // Set orbit angles
    setOrbit(
      horizontal: orbitAngles?.x ?? 0.0, // azimuth
      vertical: orbitAngles?.y ?? 0.0, // elevation
      roll: roll ?? 0.0, // roll
    );

    // Now engine is null - all this does is set the transform for serialization
    _updateHeadPosition();
    _updateRigPosition();
  }

  @override
  void initialize(final FilamentViewApi engine) {
    super.initialize(engine);

    onEnable();
  }

  void onEnable() {
    print('Camera $id enabled');
    // Set the initial position of the head
    _updateHeadPosition();

    // Set the initial target position
    _updateRigPosition();
  }

  /// Sets the camera as active for the given view
  void setActive([final int? viewId]) {
    unawaited(engine?.setActiveCamera(viewId, id));
    onEnable();
  }

  /*
   *  Targeting
   */

  bool _dirtyTarget = true;

  @override
  set orbitOriginPoint(final Vector3? point) {
    super.orbitOriginPoint = point;
    _dirtyTarget = true;
    _updateRigPosition();
  }

  @override
  set orbitOriginEntity(final EntityGUID? entity) {
    super.orbitOriginEntity = entity;
    _dirtyTarget = true;
    _updateRigPosition();
  }

  void setTarget({final Vector3? point, final EntityGUID? entity}) {
    assert(
      point != null || entity != null,
      "Either orbitOriginPoint or orbitOriginEntity must be provided, but not both.",
    );

    super.orbitOriginPoint = point;
    super.orbitOriginEntity = entity;
    _dirtyTarget = true;
    _updateRigPosition();
  }

  void _updateRigPosition() {
    if (_dirtyTarget) {
      print(
        'Updating camera($id) target: type=${targetType.name}, point=$orbitOriginPoint, entity=$orbitOriginEntity',
      );

      unawaited(engine?.setCameraOrigin(id, orbitOriginEntity ?? kNullGuid));

      if (orbitOriginPoint != null) {
        setLocalPosition(orbitOriginPoint);
      }

      _dirtyTarget = false;
    }

    setLocalRotation();
  }

  @override
  /// Disables target following, making the camera stay at its current position.
  /// Also resets the target distance.
  void disableTarget() {
    // If the rig is following an entity, set it to the current position and stop following.
    if (targetType == CameraComponent.CameraTargetType.entity) {
      // skip our setter, we're updating the position below
      super.orbitOriginPoint = getTargetPosition();
      // super.orbitOriginEntity = null; // unnecessary! the above line already does this
    }

    // Move the rig to head's current position and reset the target distance.
    if (targetType == CameraComponent.CameraTargetType.point) {
      final Vector3 currentPosition = (orbitOriginPoint ?? position);

      // Set the rig's position
      unawaited(engine?.setEntityTransformPosition(id, currentPosition.storage64));
    }
  }

  /*
   *  Orbit
   */
  final Vector3 _orbitAngles = Vector3.zero();

  /// Sets the orbit angle in radians.
  void setOrbit({
    /// the azimuth angle in radians
    final double? horizontal,

    /// the elevation angle in radians
    final double? vertical,

    // camera roll angle in radians
    final double? roll,
  }) {
    _orbitAngles.setValues(
      horizontal ?? _orbitAngles.x, // azimuth
      vertical ?? _orbitAngles.y, // elevation
      roll ?? _orbitAngles.z, // roll
    );

    this.rotation.setEulerRadians(_orbitAngles.y, _orbitAngles.x, _orbitAngles.z);
    _updateRigPosition();
  }

  /// Getter returns a copy of the orbit angles in radians.
  Vector2 get orbitAngles => Vector2.array(_orbitAngles.storage);

  /// Sets the angles by copying the values from the given vector.
  set orbitAngles(final Vector2 angles) => setOrbit(horizontal: angles.x, vertical: angles.y);

  double get roll => _orbitAngles.z;

  set roll(final double angle) => setOrbit(roll: angle);

  /*
   *  Dolly
   */
  @override
  set orbitDistance(final double distance) {
    super.orbitDistance = distance;
    _updateHeadPosition();
  }

  @override
  set dollyOffset(final Vector3 offset) {
    super.dollyOffset.setFrom(offset);

    _updateHeadPosition();
  }

  static final Vector3 kOrbitDistanceAxis = Vector3(0, 0, 1);
  final Vector3 _tmpHeadPosition = Vector3.zero();

  void _updateHeadPosition() {
    _tmpHeadPosition.setFrom(dollyOffset);
    _tmpHeadPosition.addScaled(kOrbitDistanceAxis, orbitDistance);

    unawaited(engine?.setCameraDolly(id, _tmpHeadPosition.storage64));
  }

  /*
   *  Transform
   */
  // Overrides the default setPosition/Rotation to control the head's position instead of the rig
  // but in world-space.

  @override
  /// Setting scale is not supported for Camera entities.
  /// Calling this method will throw an [UnsupportedError].
  void setLocalScale([final Vector3? scale]) {
    // NOTE: consider implementing via Filament's `Camera#setScaling()`
    throw UnsupportedError("Setting scale is not supported for Camera entities.");
  }

  /*
   *  Serialization
   */
  // TODO(kerberjg): use `Jsonable` when done
  @override
  JsonObject toJson() {
    return <String, dynamic>{...super.toJson(), ...cameraToJson(), ...rigToJson()};
  }
}
