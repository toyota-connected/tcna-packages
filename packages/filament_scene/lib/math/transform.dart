import 'dart:ffi';

import 'package:filament_scene/math/native_vectors.dart';
import 'package:filament_scene/math/vectors.dart';

class TransformData {
  final Vector3 position;
  final Vector3 scale;
  final Quaternion rotation;

  TransformData({required this.position, required this.scale, required this.rotation});

  TransformData.identity()
    : position = Vector3.zero(),
      scale = Vector3.all(1),
      rotation = Quaternion.identity();

  TransformData.fromPointers(final int positionPtr, final int scalePtr, final int rotationPtr)
    : position = createVector3FromPointer(Pointer<Float>.fromAddress(positionPtr)),
      scale = createVector3FromPointer(Pointer<Float>.fromAddress(scalePtr)),
      rotation = createQuaternionFromPointer(Pointer<Float>.fromAddress(rotationPtr));

  /// Constructs a [TransformData] from a [Matrix4].
  /// NOTE: scale extraction is not implemented yet, will be always 1.
  TransformData.fromMatrix(final Matrix4 matrix)
    : position = matrix.getTranslation(),
      scale = Vector3.all(1),
      rotation = Quaternion.fromRotation(matrix.getRotation());
}

/// Represents a 3D entity transform.
/// Contains local (relative to parent) and global (absolute) position/rotation/scale.
class Transform {
  final TransformData local;
  final TransformData global;
  // final Matrix4 _globalMatrix;

  Transform({required this.local, required final Matrix4 globalMatrix})
    : // _globalMatrix = globalMatrix,
      global = TransformData.fromMatrix(globalMatrix);
}
