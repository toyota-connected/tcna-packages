import 'dart:ui';

import 'package:vector_math/vector_math.dart';

typedef JsonObject = Map<String, dynamic>;
typedef JsonArray = List<dynamic>;
typedef JsonKey = String;
typedef JsonValue = dynamic;

/// A mixin that provides JSON serialization capabilities to classes.
/// Classes that implement this mixin must provide a `toJson` method that returns a map
/// representing the object's state in a JSON-compatible format.
/// The mixin also overrides [toString], [==], and [hashCode] methods
mixin Jsonable {
  /// Converts the object to a JSON-compatible map.
  JsonObject toJson();

  @override
  String toString() =>
      '$runtimeType(${toJson().entries.map((final e) => '${e.key}: ${e.value}').join(', ')})';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;
    if (other.runtimeType != runtimeType) return false;
    if (other is! Jsonable) return false;

    final Jsonable otherJsonable = other;
    return toJson().entries.every((final entry) {
      final dynamic value = otherJsonable.toJson()[entry.key];
      return value == entry.value;
    });
  }

  @override
  int get hashCode {
    int hash = 0;
    // ignore: specify_nonobvious_local_variable_types
    for (final entry in toJson().entries) {
      hash ^= entry.value.hashCode;
    }
    return hash;
  }
}

/// Serialization extension for Vector2
extension Vector2Serializable on Vector2 {
  JsonObject toJson() => <String, dynamic>{'x': x, 'y': y};
}

/// Serialization extension for Vector3
extension Vector3Serializable on Vector3 {
  JsonObject toJson() => <String, dynamic>{'x': x, 'y': y, 'z': z};
}

/// Serialization extension for Vector4
extension Vector4Serializable on Vector4 {
  JsonObject toJson() => <String, dynamic>{'x': x, 'y': y, 'z': z, 'w': w};
}

/// Serialization extension for Quaternion
extension QuaternionSerializable on Quaternion {
  JsonObject toJson() => <String, dynamic>{'x': x, 'y': y, 'z': z, 'w': w};
}

/// Serialization extension for Color
extension ColorsExt on Color {
  /// Returns the RGBA representation of the color in hexadecimal format.
  String toHex() {
    return "#${toARGB32().toRadixString(16)}";
  }
}
