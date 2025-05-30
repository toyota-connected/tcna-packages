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
    required super.id,
    required this.size,
    required super.position,
    super.name,
    required super.scale,
    super.normal,
    required super.rotation,
    super.material,
    super.collidable,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'size': size.toJson(),
    'shapeType': 1,
  };

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Plane && other.size == size && super == other;
  }

  @override
  int get hashCode => size.hashCode ^ super.hashCode;
}
