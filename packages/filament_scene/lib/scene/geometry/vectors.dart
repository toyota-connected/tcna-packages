part of 'geometry.dart';

/// Convenience alias for Vector3
typedef Position = Vector3; typedef Size = Vector3; typedef Direction = Vector3;

/// Convenience alias for Vector4
typedef Rotation = Vector4;



/// An object that represents the a vector in 3D world space
/// TODO(kerberjg): test whether it makes sense to even have a Vector3 - a cache line fits 2x Vector4 perfectly. Maybe there's pointers involved? Run benchmarks
class Vector3 {
  double x, y, z;

  Vector3(this.x, this.y, this.z);
  Vector3.only({this.x = 0, this.y = 0, this.z = 0});

  Vector3.x(final double x) : this.only(x: x);
  Vector3.y(final double y) : this.only(y: y);
  Vector3.z(final double z) : this.only(z: z);
  Vector3.all(final double value) : this.only(
    x: value, y: value, z: value,
  );

  /// Square magnitude of the vector
  double get sqrMagnitude => x * x + y * y + z * z;
  /// Magnitude of the vector
  /// NOTE: This is a slow operation, use [sqrMagnitude] if you only need to compare magnitudes or check if it's equal to 0 or 1
  double get magnitude => Math.sqrt(sqrMagnitude);

  /// Whether the vector is a zero vector
  bool get isZero => sqrMagnitude == 0;
  /// Whether the vector is a one vector
  bool get isOne => sqrMagnitude == 1;


  /// Returns a normalized copy of the vector
  /// 
  /// See: [Vector3.normalized]
  Vector3 normalized() {
    final double mag = magnitude;
    if (mag == 0) return this;
    return Vector3(x / mag, y / mag, z / mag);
  }

  /// Normalizes this vector and returns it (no copy)
  ///
  /// See: [Vector3.normalized]
  Vector3 normalize() {
    final double mag = magnitude;

    // Skip if it's already normalized or zero
    if (mag == 0 || mag == 1) return this;

    x /= mag;
    y /= mag;
    z /= mag;
    
    return this;
  }

  Vector3 operator +(final Vector3 other) => Vector3(x + other.x, y + other.y, z + other.z);
  Vector3 operator -(final Vector3 other) => Vector3(x - other.x, y - other.y, z - other.z);
  Vector3 operator *(final Vector3 other) => Vector3(x * other.x, y * other.y, z * other.z);
  Vector3 operator /(final Vector3 other) => Vector3(x / other.x, y / other.y, z / other.z);

  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'z': z,
  };

  @override
  String toString() => 'Vector3(x: $x, y: $y, z: $z)';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Vector3 &&
        other.x == x &&
        other.y == y &&
        other.z == z;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode;
}

/// An object that represents the a vector in 4D world space
class Vector4 {
  /// Default value is 0
  double x, y, z;
  /// Default value is 1
  double w;

  Vector4({this.x = 0, this.y = 0, this.z = 0, this.w = 1});

  Vector4.x(final double x) : this(x: x);
  Vector4.y(final double y) : this(y: y);
  Vector4.z(final double z) : this(z: z);
  Vector4.w(final double w) : this(w: w);
  Vector4.all(final double value) : this(
    x: value, y: value, z: value, w: value,
  );

  /// constructor; Quaternion from euler angles
  static Vector4 fromEulerAngles(double xx, double yy, double zz, { bool useDegrees = false }) {
    if (useDegrees) {
      xx = xx * Math.pi / 180;
      yy = yy * Math.pi / 180;
      zz = zz * Math.pi / 180;
    }

    final double halfX = xx / 2;
    final double halfY = yy / 2;
    final double halfZ = zz / 2;

    final double cosX = Math.cos(halfX);
    final double cosY = Math.cos(halfY);
    final double cosZ = Math.cos(halfZ);

    final double sinX = Math.sin(halfX);
    final double sinY = Math.sin(halfY);
    final double sinZ = Math.sin(halfZ);

    double x, y, z, w;
    x = sinX * cosY * cosZ + cosX * sinY * sinZ;
    y = cosX * sinY * cosZ - sinX * cosY * sinZ;
    z = cosX * cosY * sinZ - sinX * sinY * cosZ;
    w = cosX * cosY * cosZ + sinX * sinY * sinZ;

    return Vector4(x: x, y: y, z: z, w: w);
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'x': x,
    'y': y,
    'z': z,
    'w': w,
  };

  @override
  String toString() => 'Vector4(x: $x, y: $y, z: $z. w" $w)';

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Vector4 &&
        other.x == x &&
        other.y == y &&
        other.z == z &&
        other.w == w;
  }

  @override
  int get hashCode => x.hashCode ^ y.hashCode ^ z.hashCode ^ w.hashCode;
}
