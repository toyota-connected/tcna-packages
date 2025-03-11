part of 'shapes.dart';

/// An object that represents a plane shape to be rendered.
class Plane extends Shape {
  /// size of the plane in the world space.
  /// provides the width and height of the plane in the world space.
  /// should provide only 2 coordinates of the plane.
  /// To draw horizontally y must be 0.
  /// To draw vertically z must be 0.
  Vector3 size;

  Plane({
    required this.size,
    required super.centerPosition,
    super.global_guid,
    super.name,
    super.scale,
    super.normal,
    super.rotation,
    super.material,
    super.collidable,
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
    'scale': scale?.toJson(),
    'normal': normal?.toJson(),
    'size': size.toJson(),
    'rotation': rotation?.toJson(),
    'collidable': collidable?.toJson(),
    'material': material?.toJson(),
    'shapeType': 1,
    'doubleSided': doubleSided,
    'cullingEnabled': cullingEnabled,
    'receiveShadows': receiveShadows,
    'castShadows': castShadows,
  };

  @override
  String toString() {
    return 'Plane(size: $size, centerPosition: $centerPosition)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Plane && other.size == size && super == other;
  }

  @override
  int get hashCode => size.hashCode ^ super.hashCode;
}
