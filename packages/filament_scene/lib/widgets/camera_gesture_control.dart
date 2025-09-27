import 'package:filament_scene/camera/camera.dart';
import 'package:filament_scene/math/utils.dart';
import 'package:filament_scene/math/vectors.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

class CameraGestureControl extends StatelessWidget {
  final ValueNotifier<Vector2> cameraAngle;
  final Camera camera;
  final Vector2 minAngle = Vector2(0, -90);
  final Vector2 maxAngle = Vector2(360, -15);

  CameraGestureControl({
    super.key,
    required this.cameraAngle,
    required this.camera,
    final Vector2? minAngle,
    final Vector2? maxAngle,
  }) {
    if (minAngle != null) {
      this.minAngle.setFrom(minAngle);
    }
    if (maxAngle != null) {
      this.maxAngle.setFrom(maxAngle);
    }
  }

  @override
  Widget build(final BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent, // allow taps to pass through
      // NOTE: exercise: try implementing a camera gesture that allows zooming in and out
      onPanUpdate: (final details) {
        // Updated camera angles based on initial touch position
        cameraAngle.value = Vector2(
          (cameraAngle.value.x - details.delta.dx * 0.25).clamp(minAngle.x, maxAngle.x) % 360,
          (cameraAngle.value.y - details.delta.dy * 0.25).clamp(minAngle.y, maxAngle.y), // % 360,
        );

        camera.setOrbit(
          horizontal: radians(cameraAngle.value.x),
          vertical: radians(cameraAngle.value.y),
        );
      },
    );
  }

  @override
  void debugFillProperties(final DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<ValueNotifier<Vector2>>('cameraAngle', cameraAngle));
    properties.add(DiagnosticsProperty<Camera>('camera', camera));
    properties.add(DiagnosticsProperty<Vector2>('minAngle', minAngle));
    properties.add(DiagnosticsProperty<Vector2>('maxAngle', maxAngle));
  }
}
