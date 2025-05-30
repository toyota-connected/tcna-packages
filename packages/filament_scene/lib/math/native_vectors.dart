import 'dart:ffi';

import 'package:flutter/foundation.dart';

import './vectors.dart';

/// Constructs a [Vector3] from a native pointer to a raw contiguous array of 3x floats (32-bit).
Vector3 createVector3FromPointer(final Pointer<Float> pointer) {
  final Float32List v3storage = pointer.asTypedList(3);
  return Vector3.fromFloat32List(v3storage);
}

/// Constructs a [Quaternion] from a native pointer to a raw contiguous array of 4x floats (32-bit).
Quaternion createQuaternionFromPointer(final Pointer<Float> pointer) {
  final Float32List qstorage = pointer.asTypedList(4);
  return Quaternion.fromFloat32List(qstorage);
}

/// Constructs a [Matrix4] from a native pointer to a raw contiguous array of 16x floats (32-bit).
Matrix4 createMatrix4FromPointer(final Pointer<Float> pointer) {
  final Float32List mstorage = pointer.asTypedList(16);
  return Matrix4.fromFloat32List(mstorage);
}
