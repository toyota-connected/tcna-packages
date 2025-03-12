
import 'package:filament_scene/utils/guid.dart';
import 'package:flutter/foundation.dart';

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
