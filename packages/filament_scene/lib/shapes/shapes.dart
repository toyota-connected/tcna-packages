library shapes;

import 'package:filament_scene/scene/geometry/geometry.dart';
import 'package:filament_scene/material/material.dart';

part 'cube.dart';
part 'plane.dart';
part 'sphere.dart';

/// An object that represents shapes to be rendered on the scene.
///
/// See also:
/// [Cube]
/// [Plane]
/// [Sphere]
class Shape {
  /// center position of the shape in the world space.
  Vector3? centerPosition;

  /// Scale of the shape
  Vector3? scale;

  /// direction of the shape rotation in the world space
  Vector3? normal;

  /// material to be used for the shape.
  Material? material;

  /// Quaternion rotation for the shape
  Vector4? rotation;

  /// Do we have a collidable for this object (expecting to collide)
  Collidable? collidable;

  /// used for communication back and forth from dart/native
  String? name;

  /// used for communication back and forth from dart/native
  String? global_guid;

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
    this.centerPosition,
    this.normal,
    this.material,
    this.scale,
    this.rotation,
    this.collidable, 
    this.global_guid,
    this.name,
    this.doubleSided = false,
    this.cullingEnabled = true,
    this.castShadows = false,
    this.receiveShadows = false,
  });

  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'global_guid' : global_guid,
    'centerPosition': centerPosition?.toJson(),
    'normal': normal?.toJson(),
    'material': material?.toJson(),
    'scale': scale?.toJson(),
    'rotation': rotation?.toJson(),
    'collidable': collidable?.toJson(),
    'type': 0,
    'doubleSided': doubleSided,
    'cullingEnabled': cullingEnabled,
    'receiveShadows': receiveShadows,
    'castShadows': castShadows,
  };

  @override
  String toString() {
    return 'centerPosition: $centerPosition normal: $normal, material: $material)';
  }

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
