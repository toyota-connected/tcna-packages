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

Quaternion sphericalToQuaternion(
  final double azimuth, // azimuth angle (X) in radians
  final double elevation, // elevation angle (Y) in radians
  final double roll, [ // roll angle (Z) in radians
  Quaternion? out,
]) {
  // First convert spherical to Euler angles
  final double yaw = azimuth; // Yaw (around Y axis)
  final double pitch = elevation; // Pitch (around X axis)
  // final double roll = roll; // Roll (around Z axis)

  // Create the yaw quaternion
  tmpYaw.setAxisAngle(Vector3(0, 1, 0), yaw);
  // Create the pitch quaternion
  tmpPitch.setAxisAngle(Vector3(1, 0, 0), pitch);
  // Create the roll quaternion
  tmpRoll.setAxisAngle(Vector3(0, 0, 1), roll);

  // Combine yaw and pitch to get the final quaternion
  out ??= Quaternion.identity();
  out.setFrom(tmpYaw * tmpPitch * tmpRoll); // TODO(kerberjg): muls create new quats, optimize this

  return out;
}

Quaternion cameraOrbitToQuaternion(
  /// Azimuth angle (X) in radians
  final double azimuth,

  /// Elevation angle (Y) in radians
  final double elevation,
  final double roll, [
  final Quaternion? out,
]) => sphericalToQuaternion(azimuth, elevation, roll, out);
