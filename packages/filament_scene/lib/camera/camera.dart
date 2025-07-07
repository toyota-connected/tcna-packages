
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
/// - rig (entity): centered at the target's position;
///                 its rotation is used to control the camera's orbit (Y, X)
/// - head (camera eye): always at (x:0, y:0, z: [targetDistance]) + [dollyOffset] relative to the rig;
/// 
class Camera extends TransformEntity with CameraComponent.Camera, CameraComponent.CameraRig {
  Camera({
    required super.id,
    super.name,
    // Target
    final Vector3? targetPoint,
    final EntityGUID? targetEntity,
    final double targetDistance = 1,
    final Vector3? dollyOffset,
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
    // super.targetEntity = targetEntity;
    super.targetDistance = targetDistance;

    super.dollyOffset = dollyOffset ?? Vector3.zero();

    // Set orbit angles
    orbitAngles ??= Vector2.zero();
    this._orbitAngles.setValues(
      // roll,           // roll
      orbitAngles.x,  // horizontal (azimuth)
      orbitAngles.y,  // vertical (elevation)
      0,
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
    // super.targetEntity = entity;
    _updateRigPosition();
  }

  void _updateRigPosition() {
    print('Camera $id updating rig position to ${targetPoint}');
    if(targetPoint != null) setLocalPosition(targetPoint);
    print('Camera $id updating rig rotation to ${_orbitAngles}');
    setLocalRotation();

    unawaited(engine?.setCameraTarget(
      id,
      targetEntity ?? kNullGuid,
    ),);
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
      final Vector3 currentPosition = (targetPoint ?? position);

      // Set the rig's position
      unawaited(engine?.setEntityTransformPosition(
        id,
        currentPosition.storage64,
      ),);
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
    _orbitAngles.x = horizontal ?? _orbitAngles.x;
    _orbitAngles.y = vertical ?? _orbitAngles.y;
    cameraOrbitToQuaternion(_orbitAngles.x, _orbitAngles.y, this.rotation);

    _updateRigPosition();
  }

  /// Sets the camera roll angle in radians.
  // TODO(kerberjg): allow to be set as [double] via direct setter
  //                 once direct memory access for vectors is supported
  void setRoll(final double roll) {
    // _orbitAngles.x = roll;

    // _updateRigPosition();
  }



  /*
   *  Dolly
   */
  @override
  set targetDistance(final double distance) {
    super.targetDistance = distance;
    _updateHeadPosition();
  }

  static final Vector3 kTargetDistanceAxis = Vector3(0, 0, 1);

  @override
  Vector3 get dollyOffset => super.dollyOffset;

  @override
  set dollyOffset(final Vector3 offset) {
    super.dollyOffset = offset;
    
    _updateHeadPosition();
  }

  Vector3 _tmpHeadPosition = Vector3.zero();

  void _updateHeadPosition() {
    _tmpHeadPosition.setFrom(dollyOffset);
    _tmpHeadPosition.addScaled(kTargetDistanceAxis, targetDistance);

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
    return <String, dynamic>{
      ...super.toJson(),
      ...cameraToJson(),
      ...rigToJson(),
    };
  }
}
