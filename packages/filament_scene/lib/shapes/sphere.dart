part of 'shapes.dart';

/// An object that represents a cube shape to be rendered.
class Sphere extends Shape {
  ///The number of stacks for the sphere.
  int? stacks;

  ///The number of slices for the sphere.
  int? slices;

  Sphere({
    required super.id,
    required super.position,
    this.stacks,
    this.slices,
    super.name,
    super.parentId,
    super.normal,
    super.material,
    required super.scale,
    required super.rotation,
    super.collider,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  ShapeType get type => ShapeType.sphere;

  @override
  JsonObject toJson() => {
    ...super.toJson(), //
    'stacks': stacks, //
    'slices': slices, //
  };
}
