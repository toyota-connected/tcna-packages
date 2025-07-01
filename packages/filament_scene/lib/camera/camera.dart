
import 'dart:async';
import 'dart:math' as Math;

import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/components/camera.dart' as CameraComponent;
import 'package:filament_scene/generated/messages.g.dart';
import 'package:filament_scene/math/utils.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/guid.dart';
import 'package:filament_scene/utils/serialization.dart';

/// This [Entity] represents a camera in the scene.
/// It's composed by two entities:
/// - rig (parent): centered at the target's position;
///                 its rotation is used to control the camera's orbit (Y, X)
/// - head (child): always at (x:0, y:0, z: [targetDistance]) + [dollyOffset] relative to the rig;
///                 its rotation is used to control the camera's pitch (X) yaw (Y), and roll (Z)
class Camera extends TransformEntity with CameraComponent.Camera, CameraComponent.CameraRig {
  /// This entity uses separate GUIDs for the rig and the camera itself (head).
  /// The rig is used to control the camera's motion and transform.
  final EntityGUID _headId = generateGuid();

  Camera({
    required super.id,
    super.name,
    // Target
    final Vector3? targetPoint,
    final EntityGUID? targetEntity,
    final double targetDistance = 1,
    // Orbit
    /// The orbit rotation euler angles in radians.
    Vector2? orbitAngles,
    final double roll = 0,
  }) : super(
    position: Vector3.zero(),
    scale: Vector3.all(1),
    rotation: Quaternion.identity(),
  ) {
    // Set default projection
    setProjection(
      projection: CameraComponent.kDefaultProjection,
    );
    exposure = CameraComponent.kDefaultExposure;

    // Set target
    assert(
      targetPoint != null || targetEntity != null,
      "Either targetPosition or targetEntity must be provided, but not both.",
    );

    super.targetPoint = targetPoint;
    super.targetEntity = targetEntity;
    super.targetDistance = targetDistance;

    // Set orbit angles
    orbitAngles ??= Vector2.zero();
    this._orbitAngles.setValues(
      orbitAngles.x,  // horizontal (azimuth)
      orbitAngles.y,  // vertical (elevation)
      roll,           // roll
    );
  }


  @override
  void initialize(final FilamentViewApi engine) {
    super.initialize(engine);

    // Set the initial position of the head
    _updateHeadPosition();

    // Set the initial target position
    _updateRigPosition();
  }

  /// Sets the camera as active for the given view
  void setActive([final int? viewId]) {
    unawaited(engine.setActiveCamera(viewId, _headId));
  }




  /*
   *  Targeting
   */  

  @override
  set targetPoint(final Vector3? point) {
    super.targetPoint = point;
    _updateRigPosition();
  }

  @override
  set targetEntity(final EntityGUID? entity) {
    super.targetEntity = entity;
    _updateRigPosition();
  }

  void setTarget({
    final Vector3? point,
    final EntityGUID? entity,
  }) {
    assert(
      point != null || entity != null,
      "Either targetPoint or targetEntity must be provided, but not both.",
    );

    super.targetPoint = point;
    super.targetEntity = entity;
    _updateRigPosition();
  }

  void _updateRigPosition() {
    unawaited(engine.setCameraTarget(
      _headId,
      (targetPoint ?? Vector3.zero()).storage64,
      targetEntity ?? kNullGuid,
    ));
  }

  @override
  /// Disables target following, making the camera stay at its current position.
  /// Also resets the target distance.
  void disableTarget() {
    // If the rig is following an entity, set it to the current position and stop following.
    if (targetType == CameraComponent.CameraTargetType.entity) {
      // skip our setter, we're updating the position below
      super.targetPoint = getTargetPosition();
      // super.targetEntity = null; // unnecessary! the above line already does this
    }
    
    // Move the rig to head's current position and reset the target distance.
    if (targetType == CameraComponent.CameraTargetType.point) {
      // Use _orbitAngles and targetDistance to calculate the head's position
      // TODO(kerberjg): once [_head] is just an entity and not an ID, get its position directly
      final Vector3 headOffset = sphericalToCartesian(
        targetDistance, _orbitAngles.x, _orbitAngles.y,
      );

      final Vector3 currentPosition = (targetPoint ?? Vector3.zero()) + headOffset;

      // Reset the head position
      targetDistance = 0; // calls _updateHeadPosition()

      // Set the rig's position
      unawaited(engine.setEntityTransformPosition(
        _headId,
        currentPosition.storage64,
      ));
    }
  }



  /*
   *  Orbit
   */
  final Vector3 _orbitAngles = Vector3.zero();
  /// Sets the orbit angle in radians.
  /// See also:
  /// - [setRoll]
  // TODO(kerberjg): allow to be set as [Vector2] via direct setter
  //                 once direct memory access for vectors is supported
  void setOrbit({
    /// the azimuth angle in radians
    final double? horizontal,
    /// the elevation angle in radians
    final double? vertical,
  }) {
    _orbitAngles.y = horizontal ?? _orbitAngles.y;
    _orbitAngles.x = vertical ?? _orbitAngles.x;

    super.setLocalRotationFromEuler(_orbitAngles);
  }

  /// Sets the camera roll angle in radians.
  // TODO(kerberjg): allow to be set as [double] via direct setter
  //                 once direct memory access for vectors is supported
  void setRoll(final double roll) {
    _orbitAngles.z = roll;
    super.setLocalRotationFromEuler(_orbitAngles);
  }



  /*
   *  Dolly
   */
  final Vector3 _headPosition = Vector3.zero();

  @override
  set targetDistance(final double distance) {
    super.targetDistance = distance;
    
    _updateHeadPosition();
  }

  @override
  set dollyOffset(final Vector3 offset) {
    super.dollyOffset = offset;
    
    _updateHeadPosition();
  }

  void _updateHeadPosition() {
    // TODO(kerberjg): optimize for SIMD when vector_math supports it
    _headPosition.setValues(
      0 + dollyOffset.x,
      0 + dollyOffset.y,
      targetDistance + dollyOffset.z,
    );

    unawaited(engine.setEntityTransformPosition(_headId, _headPosition.storage64));
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
    return <String, dynamic>{
      ...super.toJson(),
      ...cameraToJson(),
      ...rigToJson(),
    };
  }

}
