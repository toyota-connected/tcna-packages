library shapes;

import 'package:filament_scene/components/collidable.dart';
import 'package:filament_scene/entity/entity.dart';
import 'package:filament_scene/material/material.dart';
import 'package:filament_scene/utils/guid.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

part 'cube.dart';
part 'plane.dart';
part 'sphere.dart';

/// An object that represents shapes to be rendered on the scene.
///
/// See also:
/// [Cube]
/// [Plane]
/// [Sphere]
class Shape extends TransformEntity {
  /// direction of the shape rotation in the world space
  Vector3? normal;

  /// material to be used for the shape.
  Material? material;

  /// Do we have a collidable for this object (expecting to collide)
  Collidable? collidable;

  /// When creating geometry if its inside and out, or only
  /// outward facing
  bool doubleSided;

  /// Variables for filament renderer upon shape creation
  bool cullingEnabled;

  /// Variables for filament renderer upon shape creation
  bool receiveShadows;

  /// Variables for filament renderer upon shape creation
  bool castShadows;

  Shape({
    required super.id,
    super.name,
    required super.centerPosition,
    this.normal,
    this.material,
    required super.scale,
    required super.rotation,
    this.collidable,
    this.doubleSided = false,
    this.cullingEnabled = true,
    this.castShadows = false,
    this.receiveShadows = false,
  });

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'normal': normal?.toJson(),
    'collidable': collidable?.toJson(),
    'material': material?.toJson(),
    'type': 0,
    'doubleSided': doubleSided,
    'cullingEnabled': cullingEnabled,
    'receiveShadows': receiveShadows,
    'castShadows': castShadows,
  };

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return
      other is Shape &&
      other.centerPosition == centerPosition &&
      other.normal == normal &&
      other.material == material;
  }

  @override
  int get hashCode =>
      centerPosition.hashCode ^
      normal.hashCode ^
      material.hashCode;
}
