part of 'camera.dart';

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

///An object that controls camera projection matrix.
class Projection {
  ///Denotes the projection type used by this camera.
  ProjectionType? projection;

  ///distance in world units from the camera to the left plane, at the near plane. Precondition: left != right
  double? left;

  ///distance in world units from the camera to the right plane, at the near plane. Precondition: left != right
  double? right;

  ///distance in world units from the camera to the bottom plane, at the near plane. Precondition: bottom != top
  double? bottom;

  ///distance in world units from the camera to the top plane, at the near plane. Precondition: bottom != top
  double? top;

  ///distance in world units from the camera to the near plane.
  /// The near plane's position in view space is z = -near.
  /// Precondition: near > 0 for ProjectionType.PERSPECTIVE or near != far for ProjectionType.ORTHO.
  double? near;

  ///distance in world units from the camera to the far plane.
  /// The far plane's position in view space is z = -far.
  /// Precondition: far > near for ProjectionType.PERSPECTIVE or far != near for ProjectionType.ORTHO.
  double? far;

  /// full field-of-view in degrees. 0 < fovInDegrees < 180
  double? fovInDegrees;

  /// aspect ratio width/height. aspect > 0
  double? aspect;

  ///direction of the field-of-view parameter.
  Fov? fovDirection;

  ///Sets the projection matrix from a frustum defined by six planes.
  Projection.fromPlanes(
      {required this.projection,
      required this.left,
      required this.right,
      required this.bottom,
      required this.top,
      this.near,
      this.far});

  ///Sets the projection matrix from the field-of-view.
  Projection.fromFov(
      {required this.fovInDegrees,
      required this.fovDirection,
      this.aspect,
      this.near,
      this.far});

  Map<String, dynamic> toJson() {
    return {
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
  bool operator ==(Object other) {
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
