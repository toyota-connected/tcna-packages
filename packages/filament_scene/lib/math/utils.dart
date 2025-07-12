import 'dart:math' as Math;
import 'package:filament_scene/math/vectors.dart';

export 'package:vector_math/vector_math.dart' show radians, degrees;

/// Converts spherical coordinates (Euler angles X and Y in radians) to Cartesian coordinates
/// given a distance radius.
/// Assumes the following:
/// - Z is front
/// - X is right
/// - Y is up
Vector3 sphericalToCartesian(final double radius, final double x, final double y) {
  final double cosX = Math.cos(x);
  return Vector3(radius * cosX * Math.sin(y), radius * Math.sin(x), radius * cosX * Math.cos(y));
}

Quaternion tmpYaw = Quaternion.identity();
Quaternion tmpPitch = Quaternion.identity();
Quaternion tmpRoll = Quaternion.identity();
