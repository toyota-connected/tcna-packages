import 'dart:async';

import 'package:filament_scene/ecs/component.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/utils/serialization.dart';

class Transform extends Component {
  @override
  String get type => 'Transform';

  /// (Local) Position of the entity in the scene.
  /// Default: [Vector3.zero]
  final Vector3 position = Vector3.zero();

  /// (Local) Rotation of the entity in the scene.
  /// Default: [Quaternion.identity]
  final Quaternion rotation = Quaternion.identity();

  /// (Local) Scale of the entity in the scene.
  /// Default: [Vector3.all(1.0)]
  final Vector3 scale = Vector3.all(1.0);

  /// Creates a new Transform component with the given position, rotation, and scale.
  Transform({
    final Position? position, //
    final Quaternion? rotation, //
    final Scale? scale, //
  }) : super() {
    if (position != null) this.position.setFrom(position);
    if (rotation != null) this.rotation.setFrom(rotation);
    if (scale != null) this.scale.setFrom(scale);
  }

  @override
  JsonObject toJson() => <String, dynamic>{
    ...super.toJson(),
    'position': position.toJson(),
    'rotation': rotation.toJson(),
    'scale': scale.toJson(),
  };

  // TODO(kerberjg): instead of explicit setters, get vector array address on init

  /// Sets the local position of this entity.
  void setLocalPosition([final Position? newPosition]) {
    if (newPosition != null) position.setFrom(newPosition);
    unawaited(engine.setEntityTransformPosition(id, position.storage64));
  }

  /// Sets the local scale of this entity.
  void setLocalScale([final Scale? newScale]) {
    if (newScale != null) scale.setFrom(newScale);
    unawaited(engine.setEntityTransformScale(id, scale.storage64));
  }

  /// Sets the local rotation of this entity.
  void setLocalRotation([final Quaternion? newRotation]) {
    if (newRotation != null) rotation.setFrom(newRotation);
    unawaited(engine.setEntityTransformRotation(id, rotation.storage64));
  }

  /// Sets the local rotation of this entity from Euler angles.
  /// The angles are in radians.
  void setLocalRotationFromEuler(final Vector3 rad) {
    rotation.setEulerRadians(rad.x, rad.y, rad.z);
    setLocalRotation();
  }

  /// Flushes the current transform state to the engine
  void updateTransform() {
    unawaited(engine.setEntityTransformPosition(id, position.storage64));
    unawaited(engine.setEntityTransformScale(id, scale.storage64));
    unawaited(engine.setEntityTransformRotation(id, rotation.storage64));
  }
}
