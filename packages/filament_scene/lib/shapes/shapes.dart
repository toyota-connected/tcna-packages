library shapes;

import 'package:filament_scene/components/collider.dart';
import 'package:filament_scene/ecs/entity.dart';
import 'package:filament_scene/material/material.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:vector_math/vector_math.dart';

part 'cube.dart';
part 'plane.dart';
part 'sphere.dart';

/// Enumeration of all shape types.
enum ShapeType {
  /// No shape type.
  none(0),

  /// Plane shape type.
  plane(1),

  /// Cube shape type.
  cube(2),

  /// Sphere shape type.
  sphere(3);

  final int value;
  const ShapeType(this.value);
}

/// An object that represents shapes to be rendered on the scene.
///
/// See also:
/// [Cube]
/// [Plane]
/// [Sphere]
abstract class Shape extends TransformEntity {
  /// direction of the shape rotation in the world space
  Vector3? normal;

  /// material to be used for the shape.
  Material? material;

  /// Do we have a collider for this object (expecting to collide)
  Collider? collider;

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
    super.parentId,
    required super.position,
    this.normal,
    this.material,
    required super.scale,
    required super.rotation,
    super.children,
    this.collider,
    this.doubleSided = false,
    this.cullingEnabled = true,
    this.castShadows = true,
    this.receiveShadows = true,
  });

  ShapeType get type;

  @override
  JsonObject toJson() => <String, dynamic>{
    ...super.toJson(),
    'normal': normal?.toJson(),
    'collider': collider?.toJson(),
    'material': material?.toJson(),
    'type': type.value,
    'doubleSided': doubleSided,
    'cullingEnabled': cullingEnabled,
    'receiveShadows': receiveShadows,
    'castShadows': castShadows,
  };
}
