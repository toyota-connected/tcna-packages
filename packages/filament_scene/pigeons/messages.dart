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

// TODO(kerberjg): Use Float32List instead of separate doubles for vectors and quaternions

@ConfigurePigeon(PigeonOptions(
  dartOut: 'generated/src/dart/messages.g.dart',
  dartTestOut: 'generated/src/dart/test/test_api.g.dart',
  cppHeaderOut: 'generated/src/cpp/messages.g.h',
  cppSourceOut: 'generated/src/cpp/messages.g.cc',
  cppOptions: CppOptions(
    namespace: 'plugin_filament_view',
  ),
  copyrightHeader: 'pigeons/copyright.txt',
  dartPackageName: 'filament_scene',
),)

@HostApi()
abstract class FilamentViewApi {
  /*
   *  Materials
   */
  /// Change material parameters for the given entity.
  void changeMaterialParameter(Map<String?, Object?> params, int id);
  /// Change material definition for the given entity.
  void changeMaterialDefinition(Map<String?, Object?> params, int id);

  /*
   *  Shapes
   */
  /// Toggle shapes visibility in the scene.
  void toggleShapesInScene(bool value);

  /*
   * Rendering
   */
  /// Cycle between view quality settings presets.
  void changeViewQualitySettings();
  /// Set fog options
  void setFogOptions(bool enable);

  /*
   *  Camera
   */
  /// Change the camera mode by name.
  // TODO(kerberjg): refactor to use an enum instead of string
  void changeCameraMode(String mode);
  void changeCameraOrbitHomePosition(double x, double y, double z);
  void changeCameraTargetPosition(double x, double y, double z);
  void changeCameraFlightStartPosition(double x, double y, double z);
  /// (For `INERTIA_AND_GESTURES` mode) Reset inertia camera to default values.
  void resetInertiaCameraToDefaultValues();
  /// Set camera rotation by a float value.
  void setCameraRotation(double value);

  /*
   *  Lights
  */
  /// Set a light's color and intensity by GUID.
  void changeLightColorByGUID(int id, String color, int intensity);
  /// Set a light's transform by GUID. Deprecated.
  @Deprecated('Use changeTranslationByGUID and changeRotationByGUID instead')
  void changeLightTransformByGUID(int id, double posx, double posy,
      double posz, double dirx, double diry, double dirz);

  /*
   *  Animations
   */
  void enqueueAnimation(int id, int animationIndex);
  void clearAnimationQueue(int id);
  void playAnimation(int id, int animationIndex);
  void changeAnimationSpeed(int id, double speed);
  void pauseAnimation(int id);
  void resumeAnimation(int id);
  void setAnimationLooping(int id, bool looping);

  /*
   * Collision
   */
  /// Perform a raycast query.
  /// The result will be sent back to the client via the collision_info event channel.
  void requestCollisionCheckFromRay(
      String queryID,
      double originX,
      double originY,
      double originZ,
      double directionX,
      double directionY,
      double directionZ,
      double length);
  /// Disable raycast checks for the given entity.
  /// NOTE: this will not hide the collider debug visual.
  void turnOffCollisionChecksForEntity(int id);
  /// Enable raycast checks for the given entity.
  /// NOTE: this will not show the collider debug visual.
  void turnOnCollisionChecksForEntity(int id);
  /// Enable/disable debug collidable visuals in the scene.
  void toggleDebugCollidableViewsInScene(bool value);

  /*
   *  Transform
   */
  void setEntityTransformScale(int id, Float64List scl);
  void setEntityTransformPosition(int id, Float64List pos);
  void setEntityTransformRotation(int id, Float64List rot);


  // runtime visual
  void turnOffVisualForEntity(int id);
  void turnOnVisualForEntity(int id);
}
