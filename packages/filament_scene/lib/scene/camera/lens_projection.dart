///An object that control camera and set it's projection matrix from the focal length.
class LensProjection {
  /// lens's focal length in millimeters.
  final double focalLength;

  ///aspect ratio width/height.
  final double? aspect;

  ///distance in world units from the camera to the near plane.
  /// The near plane's position in view space is z = -near.
  /// Precondition: near > 0 for ProjectionType.PERSPECTIVE or near != far for ProjectionType.ORTHO.
  final double? near;

  ///distance in world units from the camera to the far plane.
  /// The far plane's position in view space is z = -far.
  /// Precondition: far > near for ProjectionType.PERSPECTIVE or far != near for ProjectionType.ORTHO.
  final double? far;

  const LensProjection({
    this.focalLength = 50.0, // default focal length in mm
    this.aspect,
    this.near,
    this.far,
  }) : assert(focalLength > 0, "Focal length must be greater than 0"),
       assert(aspect == null || aspect > 0, "Aspect ratio must be greater than 0"),
       assert(near == null || near > 0, "Near must be greater than 0 for perspective projection");
  // assert(far == null || far > near!, "Far must be greater than near for perspective projection");

  LensProjection copyWith({
    final double? focalLength,
    final double? aspect,
    final double? near,
    final double? far,
  }) {
    return LensProjection(
      focalLength: focalLength ?? this.focalLength,
      aspect: aspect ?? this.aspect,
      near: near ?? this.near,
      far: far ?? this.far,
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
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
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is LensProjection &&
        other.focalLength == focalLength &&
        other.aspect == aspect &&
        other.near == near &&
        other.far == far;
  }

  @override
  int get hashCode {
    return focalLength.hashCode ^ aspect.hashCode ^ near.hashCode ^ far.hashCode;
  }
}
