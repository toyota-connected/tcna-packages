import 'package:flutter/foundation.dart';
import 'package:vector_math/vector_math.dart';
export 'package:vector_math/vector_math.dart' show Vector2, Vector3, Quaternion, Matrix4;

extension Vector3WithExtras on Vector3 {
  /// Construct a [Vector3] from a [Vector3Data].
  static Vector3 fromData(final Vector3Data data) => Vector3(data.x, data.y, data.z);

  /// Multiply each component of the vector by the corresponding component of the other vector.
  Vector3 mul(final Vector3 other) => Vector3(x * other.x, y * other.y, z * other.z);

  Vector3 operator *(final Vector3 other) => mul(other);
}

extension QuaterionWithDegrees on Quaternion {
  /// Construct a [Quaternion] from [QuaternionData].
  static Quaternion fromData(final QuaternionData data) {
    final Quaternion q = Quaternion.identity();

    if (data.isEuler) {
      if (data.isDegrees) {
        q.setEulerDegrees(data.x, data.y, data.z);
      } else {
        q.setEulerRadians(data.x, data.y, data.z);
      }
    } else {
      q.setValues(data.x, data.y, data.z, data.w);
    }

    return q;
  }

  void setEulerDegrees(final double x, final double y, final double z) {
    setEuler(y * degrees2Radians, x * degrees2Radians, z * degrees2Radians);
  }

  void setEulerRadians(final double x, final double y, final double z) {
    setEuler(y, x, z);
  }
}

extension Vector3WithStorage64 on Vector3 {
  static const int storageSize = 3;
  Float64List get storage64 {
    final Float64List list = Float64List(storageSize);
    for (int i = 0; i < storageSize; i++) {
      list[i] = storage[i];
    }
    return list;
  }
}

extension QuaternionWithStorage64 on Quaternion {
  static const int storageSize = 4;
  Float64List get storage64 {
    final Float64List list = Float64List(storageSize);
    for (int i = 0; i < storageSize; i++) {
      list[i] = storage[i];
    }
    return list;
  }
}

/// A data class for Vector3
@immutable class Vector3Data {
  final double x, y ,z;

  const Vector3Data({
    required this.x,
    required this.y,
    required this.z,
  });

  @override
  String toString() => 'Vector3Data(x: $x, y: $y, z: $z)';

  /// Convert to a [Vector3] object.
  Vector3 toVector3() => Vector3(x, y, z);
}

/// A data class for Quaternion
@immutable class QuaternionData {
  final double x, y, z, w;
  final bool isEuler, isDegrees;

  const QuaternionData({
    required this.x,
    required this.y,
    required this.z,
    required this.w,
  }) :
    isEuler = false,
    isDegrees = false;

  /// Euler angles in radians
  const QuaternionData.euler({
    required this.x,
    required this.y,
    required this.z,
  }) : 
    w = double.nan,
    isEuler = true,
    isDegrees = false;

  /// Euler angles in degrees
  const QuaternionData.eulerDegrees({
    required this.x,
    required this.y,
    required this.z,
  }) : 
    w = double.nan,
    isEuler = true,
    isDegrees = true;  
  

  @override
  String toString() => 'QuaternionData(x: $x, y: $y, z: $z, w: $w)';
}

typedef Position = Vector3;
typedef Size = Vector3;
typedef Scale = Vector3;
typedef Direction = Vector3;

typedef Rotation = Quaternion;
typedef RotationEuler = Vector3;

typedef TransformMatrix = Matrix4;
