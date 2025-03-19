
import 'package:filament_scene/math/vectors.dart';
import 'package:filament_scene/scene/scene.dart';
import 'package:filament_scene/utils/serialization.dart';
import 'package:flutter/foundation.dart';

typedef EntityGUID = int;

class Entity {
  final EntityGUID id;
  final String? name;

  Entity({
    required this.id,
    this.name,
  });


  @mustCallSuper
  Map<String, dynamic> toJson() => <String, dynamic>{
    'guid': id,
    'name': name,
  };

  @override @nonVirtual
  /// Returns a string representation of this object, including all of its fields (based on the [toJson] method).
  /// Overriding is not necessary, as it will call the subclass' [toJson] method to get the fields.
  String toString() {
    // ignore: no_runtimetype_tostring
    return '$runtimeType(${toJson().entries.map((e) => '${e.key}: ${e.value}').join(', ')})';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Entity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TransformEntity extends Entity {
  /// Coordinate of center point position of the rendered model.
  final Position centerPosition;

  /// Scale Factor of the model.
  /// Should be greater than 0.
  /// Defaults to 1.
  final Scale scale;

  /// Quaternion rotation for the shape
  /// Defaults to `Quaternion.identity()` or [0, 0, 0, 1]
  final Quaternion rotation;

  TransformEntity({
    required super.id,
    super.name,
    required this.centerPosition,
    required this.scale,
    required this.rotation,
  }) : super();

  @override @mustCallSuper
  Map<String, dynamic> toJson() => <String, dynamic>{
    ...super.toJson(),
    'centerPosition': centerPosition.toJson(),
    'scale': scale.toJson(),
    'rotation': rotation.toJson(),
  };
}
