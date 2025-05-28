part of 'shapes.dart';

/// An object that represents a cube shape to be rendered.
class Cube extends Shape {
  /// Length of the cube.
  Vector3 size;

  final Vector3 _size;

  Cube({
    required super.id,
    required this.size,
    required super.position,
    super.name,
    super.parentId,
    required super.scale,
    required super.rotation,
    super.children,
    super.material,
    super.collidable,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : 
    _size = size,
    super();

  @override
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'size': _size.toJson(),
    'shapeType': 2,
  };

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Cube && other.size == size && super == other;
  }

  @override
  int get hashCode => size.hashCode ^ super.hashCode;
}
