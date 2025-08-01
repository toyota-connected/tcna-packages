part of 'shapes.dart';

/// A [Plane] shape entity that represents a quad mesh facing Z+
class Plane extends Shape {
  Plane({
    required super.id,
    required super.position,
    super.name,
    required super.scale,
    super.normal,
    required super.rotation,
    super.material,
    super.collider,
    super.doubleSided,
    super.castShadows,
    super.receiveShadows,
    super.cullingEnabled,
  }) : super();

  @override
  ShapeType get type => ShapeType.plane;
}
