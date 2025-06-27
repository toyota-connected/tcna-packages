
///Denotes the projection type used by this camera.
enum ProjectionType {
  /// Perspective projection, objects get smaller as they are farther.
  perspective("PERSPECTIVE"),

  /// Orthonormal projection, preserves distances.
  ortho("ORTHO");

  final String value;
  const ProjectionType(this.value);

  static ProjectionType from(final String? type) => ProjectionType.values.asNameMap()[type] ?? ProjectionType.perspective;
}

///Denotes a field-of-view direction.
enum Fov {
  /// The field-of-view angle is defined on the vertical axis.
  vertical("VERTICAL"),

  /// The field-of-view angle is defined on the horizontal axis.
  horizontal("HORIZONTAL");

  final String value;
  const Fov(this.value);

  static Fov from(final String? fov) => Fov.values.asNameMap()[fov] ?? Fov.vertical;
}

///An object that controls camera projection matrix.
class Projection {
  ///Denotes the projection type used by this camera.
  final ProjectionType? projection;

  ///distance in world units from the camera to the left plane, at the near plane. Precondition: left != right
  final double? left;

  ///distance in world units from the camera to the right plane, at the near plane. Precondition: left != right
  final double? right;

  ///distance in world units from the camera to the bottom plane, at the near plane. Precondition: bottom != top
  final double? bottom;

  ///distance in world units from the camera to the top plane, at the near plane. Precondition: bottom != top
  final double? top;

  ///distance in world units from the camera to the near plane.
  /// The near plane's position in view space is z = -near.
  /// Precondition: near > 0 for ProjectionType.PERSPECTIVE or near != far for ProjectionType.ORTHO.
  final double? near;

  ///distance in world units from the camera to the far plane.
  /// The far plane's position in view space is z = -far.
  /// Precondition: far > near for ProjectionType.PERSPECTIVE or far != near for ProjectionType.ORTHO.
  final double? far;

  /// full field-of-view in degrees. 0 < fovInDegrees < 180
  final double? fovInDegrees;

  /// aspect ratio width/height. aspect > 0
  final double? aspect;

  ///direction of the field-of-view parameter.
  final Fov? fovDirection;

  ///Sets the projection matrix from the field-of-view.
  const Projection({
    this.projection = ProjectionType.perspective,
    this.fovInDegrees = 60.0,
    this.fovDirection = Fov.vertical,
    this.aspect,
    this.near,
    this.far,
  }) :
    left = null,
    right = null,
    bottom = null,
    top = null,
    assert(fovInDegrees != null && fovInDegrees > 0 && fovInDegrees < 180, "Field of view must be between 0 and 180 degrees"),
    assert(aspect == null || aspect > 0, "Aspect ratio must be greater than 0"),
    assert(near == null || near > 0, "Near must be greater than 0 for perspective projection");
    // assert(far == null || far > near!, "Far must be greater than near for perspective projection");

  ///Sets the projection matrix from a frustum defined by six planes.
  const Projection.fromPlanes({
    required this.projection,
    required this.left,
    required this.right,
    required this.bottom,
    required this.top,
    this.near,
    this.far,
  }) :
    aspect = null,
    fovInDegrees = null,
    fovDirection = null,
    assert(left != null && right != null && left < right, "Left must be less than right"),
    assert(bottom != null && top != null && bottom < top, "Bottom must be less than top"),
    assert(near == null || near > 0, "Near must be greater than 0 for perspective projection");
    // assert(far == null || far > near!, "Far must be greater than near for perspective projection");

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      "projection": projection?.value,
      "left": left,
      "right": right,
      "bottom": bottom,
      "top": top,
      "near": near,
      "far": far,
      "fovInDegrees": fovInDegrees,
      "aspect": aspect,
      "direction": fovDirection?.value,
    };
  }

  @override
  String toString() {
    return 'Projection(projection: $projection, left: $left, right: $right, bottom: $bottom, top: $top, near: $near, far: $far, fovInDegrees: $fovInDegrees, aspect: $aspect, fovDirection: $fovDirection)';
  }

  @override
  bool operator ==(final Object other) {
    if (identical(this, other)) return true;

    return other is Projection &&
        other.projection == projection &&
        other.left == left &&
        other.right == right &&
        other.bottom == bottom &&
        other.top == top &&
        other.near == near &&
        other.far == far &&
        other.fovInDegrees == fovInDegrees &&
        other.aspect == aspect &&
        other.fovDirection == fovDirection;
  }

  @override
  int get hashCode {
    return projection.hashCode ^
        left.hashCode ^
        right.hashCode ^
        bottom.hashCode ^
        top.hashCode ^
        near.hashCode ^
        far.hashCode ^
        fovInDegrees.hashCode ^
        aspect.hashCode ^
        fovDirection.hashCode;
  }
}
