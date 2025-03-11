part of 'camera.dart';

///An object that control camera and set it's projection matrix from the focal length.
class LensProjection {
  /// lens's focal length in millimeters.
  double focalLength;

  ///aspect ratio width/height.
  double? aspect;

  ///distance in world units from the camera to the near plane.
  /// The near plane's position in view space is z = -near.
  /// Precondition: near > 0 for ProjectionType.PERSPECTIVE or near != far for ProjectionType.ORTHO.
  double? near;

  ///distance in world units from the camera to the far plane.
  /// The far plane's position in view space is z = -far.
  /// Precondition: far > near for ProjectionType.PERSPECTIVE or far != near for ProjectionType.ORTHO.
  double? far;

  LensProjection({required this.focalLength, this.aspect, this.near, this.far});

  Map<String, dynamic> toJson() {
    return {
      "focalLength": focalLength,
      "aspect": aspect,
      "near": near,
      "far": far,
    };
  }

  @override
  String toString() {
    return 'LensProjection(focalLength: $focalLength, aspect: $aspect, near: $near, far: $far)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is LensProjection &&
        other.focalLength == focalLength &&
        other.aspect == aspect &&
        other.near == near &&
        other.far == far;
  }

  @override
  int get hashCode {
    return focalLength.hashCode ^
        aspect.hashCode ^
        near.hashCode ^
        far.hashCode;
  }
}
