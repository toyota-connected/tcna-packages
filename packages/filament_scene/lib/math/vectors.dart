import 'package:vector_math/vector_math.dart';
export 'package:vector_math/vector_math.dart' show Vector2, Vector3, Quaternion;

extension Vector3WithExtras on Vector3 {
  /// Multiply each component of the vector by the corresponding component of the other vector.
  Vector3 mul(final Vector3 other) => Vector3(x * other.x, y * other.y, z * other.z);

  Vector3 operator *(final Vector3 other) => mul(other);
}

extension QuaterionWithDegrees on Quaternion {
  void setEulerDegrees(final double x, final double y, final double z) {
    setEuler(y * degrees2Radians, x * degrees2Radians, z * degrees2Radians);
  }

  void setEulerRadians(final double x, final double y, final double z) {
    setEuler(y, x, z);
  }
}

typedef Position = Vector3;
typedef Size = Vector3;
typedef Scale = Vector3;
typedef Direction = Vector3;

typedef Rotation = Quaternion;
typedef RotationEuler = Vector3;
