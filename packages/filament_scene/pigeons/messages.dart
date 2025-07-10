/*
 * Copyright 2024 Toyota Connected North America
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

import 'package:pigeon/pigeon.dart';

// TODO(kerberjg): Use Float32List instead of Float64List or double/float

@ConfigurePigeon(
  PigeonOptions(
    dartOut: 'generated/src/dart/messages.g.dart',
    dartTestOut: 'generated/src/dart/test/test_api.g.dart',
    cppHeaderOut: 'generated/src/cpp/messages.g.h',
    cppSourceOut: 'generated/src/cpp/messages.g.cc',
    cppOptions: CppOptions(namespace: 'plugin_filament_view'),
    copyrightHeader: 'pigeons/copyright.txt',
    dartPackageName: 'filament_scene',
  ),
)
@HostApi()
abstract class FilamentViewApi {
  /*
   *  Materials
   */
  /// Change material parameters for the given entity.
  void changeMaterialParameter(final Map<String?, Object?> params, final int id);

  /// Change material definition for the given entity.
  void changeMaterialDefinition(final Map<String?, Object?> params, final int id);

  /*
   *  Shapes
   */
  /// Toggle shapes visibility in the scene.
  void toggleShapesInScene(final bool value);

  /*
   * Rendering
   */
  /// Cycle between view quality settings presets.
  void changeViewQualitySettings();

  /// Set fog options
  void setFogOptions(final bool enable);

  /*
   *  Camera
   */
  /// Set the camera's targeting
  void setCameraTarget(final int id, final int targetEntityId);

  /// Set a given camera as the active camera for a view
  void setActiveCamera(
    /// View ID to set the camera for.
    /// If null, the default view will be used.
    final int? viewId,

    /// EntityGUID of the camera to set as active.
    final int cameraId,
  );

  /// Set the camera's dolly offset.
  /// The dolly offset is the camera's position relative to its target.
  void setCameraDolly(final int id, final Float64List dollyOffset);

  // TODO(kerberjg): add setCameraIpd to support stereoscopic/VR cameras

  /*
   *  Lights
   */
  /// Set a light's color and intensity by GUID.
  void changeLightColorByGUID(final int id, final String color, final int intensity);

  /// Set a light's transform by GUID. Deprecated.
  @Deprecated('Use changeTranslationByGUID and changeRotationByGUID instead')
  void changeLightTransformByGUID(
    final int id,
    final double posx,
    final double posy,
    final double posz,
    final double dirx,
    final double diry,
    final double dirz,
  );

  /*
   *  Animations
   */
  void enqueueAnimation(final int id, final int animationIndex);
  void clearAnimationQueue(final int id);
  void playAnimation(final int id, final int animationIndex);
  void changeAnimationSpeed(final int id, final double speed);
  void pauseAnimation(final int id);
  void resumeAnimation(final int id);
  void setAnimationLooping(final int id, final bool looping);

  /*
   * Collision
   */
  /// Perform a raycast query.
  /// The result will be sent back to the client via the collision_info event channel.
  void requestCollisionCheckFromRay(
    final String queryID,
    final double originX,
    final double originY,
    final double originZ,
    final double directionX,
    final double directionY,
    final double directionZ,
    final double length,
  );

  /// Disable raycast checks for the given entity.
  /// NOTE: this will not hide the collider debug visual.
  void turnOffCollisionChecksForEntity(final int id);

  /// Enable raycast checks for the given entity.
  /// NOTE: this will not show the collider debug visual.
  void turnOnCollisionChecksForEntity(final int id);

  /// Enable/disable debug collidable visuals in the scene.
  void toggleDebugCollidableViewsInScene(final bool value);

  /*
   *  Transform
   */
  void setEntityTransformScale(final int id, final Float64List scl);
  void setEntityTransformPosition(final int id, final Float64List pos);
  void setEntityTransformRotation(final int id, final Float64List rot);

  // runtime visual
  void turnOffVisualForEntity(final int id);
  void turnOnVisualForEntity(final int id);
}
