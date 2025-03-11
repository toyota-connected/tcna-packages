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
    required super.centerPosition,
    this.stacks,
    this.slices,
    super.global_guid,
    super.name,
    super.normal,
    super.material,
    super.scale,
    super.rotation,
    super.collidable,
    required this.size,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    'name': name,
    'global_guid' : global_guid,
    'centerPosition': centerPosition?.toJson(),
    'normal': normal?.toJson(),
    'scale': scale?.toJson(),
    'size': size.toJson(),
    'stacks': stacks,
    'slices': slices,
    'collidable': collidable?.toJson(),
    'material': material?.toJson(),
    'shapeType': 3,
    'rotation': rotation?.toJson(),
    'doubleSided': doubleSided,
    'cullingEnabled': cullingEnabled,
    'receiveShadows': receiveShadows,
    'castShadows': castShadows,
  };

  @override
  String toString() {
    return 'Sphere(centerPosition: $centerPosition)';
  }

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
