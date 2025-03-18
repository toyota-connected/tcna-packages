
import 'dart:ui';

import 'package:vector_math/vector_math.dart';

/// Serialization extension for Vector2
extension Vector2Serializable on Vector2 {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
  };
}

/// Serialization extension for Vector3
extension Vector3Serializable on Vector3 {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'z': z,
  };
}

/// Serialization extension for Vector4
extension Vector4Serializable on Vector4 {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'z': z,
    'w': w,
  };
}

/// Serialization extension for Quaternion
extension QuaternionSerializable on Quaternion {
  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'z': z,
    'w': w,
  };
}

/// Serialization extension for Color
extension ColorsExt on Color {
  /// Returns the RGBA representation of the color in hexadecimal format.
  String toHex() {
    return "#${toARGB32().toRadixString(16)}";
  }
}
