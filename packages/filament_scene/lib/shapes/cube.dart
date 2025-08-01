part of 'shapes.dart';

/// An object that represents a cube shape to be rendered.
class Cube extends Shape {
  Cube({
    required super.id,
    required super.position,
    super.name,
    super.parentId,
    required super.scale,
    required super.rotation,
    super.children,
    super.material,
    super.collider,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  ShapeType get type => ShapeType.cube;
}
