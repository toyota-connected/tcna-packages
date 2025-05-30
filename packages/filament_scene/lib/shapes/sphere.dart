part of 'shapes.dart';

/// An object that represents a cube shape to be rendered.
class Sphere extends Shape {
  ///The number of stacks for the sphere.
  int? stacks;

  ///The number of slices for the sphere.
  int? slices;

  // this ends up becoming the scaled size
  Vector3 size;

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
    super.collidable,
    required this.size,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'size': size.toJson(),
    'stacks': stacks,
    'slices': slices,
    'shapeType': 3,
  };

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return
      other is Sphere &&
      other.stacks == stacks &&
      other.slices == slices &&
      super == other;
  }

  @override
  int get hashCode => stacks.hashCode ^ slices.hashCode ^ super.hashCode;
}
